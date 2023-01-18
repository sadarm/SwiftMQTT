//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/17.
//

import Foundation
import Network
import Combine

extension MQTT3 {
    final class ConnectionCore: MQTTConnectionCore {
        
        private var cancellables: Set<AnyCancellable> = []
        
        var state: MQTTConnectionState { self.stateSubject.value }
        
        private let stateSubject: CurrentValueSubject<MQTTConnectionState, Never> = CurrentValueSubject(.setup)
                
        private let connectionStateSubject: CurrentValueSubject<NWConnection.State, Never> = CurrentValueSubject(.setup)
                
        private let connectionInfo: MQTTConnectionInfo
        private let options: MQTT3.Options
        private let internalConnection: NWConnection
        
        private let streamReader: StreamReader
        
        private var packetIdentifier: UInt16 = 0
        
        private var keepAliveTimer: DispatchSourceTimer?
        
        private let queue: DispatchQueue = DispatchQueue(label: "SwiftMQTT.NWConnection")

        init(connectionInfo: MQTTConnectionInfo, options: MQTT3.Options, internalConnection: NWConnection) {
            self.connectionInfo = connectionInfo
            self.options = options
            self.internalConnection = internalConnection
            self.streamReader = StreamReader(internalConnection)
            
            self.internalConnection.stateUpdateHandler = { [weak self] (state) in
                self?.connectionStateSubject.send(state)
            }
        }
        
        func start() async throws {
            guard case .setup = self.stateSubject.value else {
                throw SwiftMQTTError.stateIsNotSetup
            }
            
            do {
                self.stateSubject.send(.preparing)
                try await self.connect()
                self.startStreamReading()
                try await self.handshake()
                self.startKeepAlive()
                self.stateSubject.send(.ready)
            } catch {
                self.internalConnection.cancel()
                self.stopStreamReading()
                self.stopKeepAlive()
                
                let mqttError: SwiftMQTTError
                switch error {
                case let error as SwiftMQTTError:
                    mqttError = error
                default:
                    mqttError = .any(error)
                }
                self.stateSubject.send(.failed(mqttError))
                throw mqttError
            }
        }
        
        private func handshake() async throws {
            self.sendConnectPacket()
            try await self.waitForConnectionAccepted()
        }
        
        private func waitForConnectionAccepted() async throws {
            var cancellable: AnyCancellable?
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                cancellable = self.streamReader.receivedControlPacketPublisher
                    .prefix(1)
                    .sink(receiveValue: { (_packet) in
                        guard case let .connack(packet) = _packet else {
                            continuation.resume(throwing: SwiftMQTTError.unexpectedType)
                            return
                        }
                        
                        switch packet.returnCode {
                        case .accepted:
                            continuation.resume(returning: ())
                        case .badUserNameOrPassword:
                            continuation.resume(throwing: SwiftMQTTError.badUserNameOrPassword)
                        case .identifierRejected:
                            continuation.resume(throwing: SwiftMQTTError.identifierRejected)
                        case .notAuthorized:
                            continuation.resume(throwing: SwiftMQTTError.notAuthorized)
                        case .reserved:
                            continuation.resume(throwing: SwiftMQTTError.unexpectedType)
                        case .serverUnavailable:
                            continuation.resume(throwing: SwiftMQTTError.serverUnavailable)
                        case .unacceptableProtocolVersion:
                            continuation.resume(throwing: SwiftMQTTError.unacceptableProtocolVersion)
                        }
                    })
            }
            _ = cancellable
        }
        
        public func cancel() {
            self.stopKeepAlive()
            self.stopStreamReading()
            self.internalConnection.cancel()
        }
        
        func publish(message: MQTTString, qos: MQTTQoS) async throws {
            
        }
        
        func subscribe(topics: [(MQTTString, MQTTQoS)]) async throws {
            let packetIdentifier = self.nextPacketIdentifier()
            try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
                self.streamReader.receivedControlPacketPublisher
                    .filter {
                        if case let .suback(packet) = $0,
                           packet.identifier == packetIdentifier {
                            return true
                        } else {
                            return false
                        }
                    }.prefix(1)
                    .sink(receiveValue: { _ in
                        continuation.resume(returning: ())
                    }).store(in: &self.cancellables)
                
                self.send(MQTT3.SubscribePacket(identifier: packetIdentifier,
                                          subscriptions: topics.map { SubscribePacket.Subscription(topic: $0.0, qos: $0.1) }))
            })
        }
        
        func unsubscribe(topics: [MQTTString]) {
            self.send(MQTT3.UnsubscribePacket(identifier: self.nextPacketIdentifier(),
                                        topics: topics))
        }
        
        private func nextPacketIdentifier() -> UInt16 {
            self.packetIdentifier &+= 1
            return self.packetIdentifier
        }
    }
}

// MARK: - Connection Start
extension MQTT3.ConnectionCore {
    private func connect() async throws {
        self.internalConnection.start(queue: self.queue)
        try await self.waitForConnectionStateIsReady()
        self.startToCheckConnectionState()
    }
    
    private func waitForConnectionStateIsReady() async throws {
        var cancellable: AnyCancellable?
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            cancellable = self.connectionStateSubject
                .flatMap { (state) -> AnyPublisher<Void, Error> in
                    print("MQTT3Connection.state updated: \(state)")
                    switch state {
                    case .ready:
                        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                    case .setup, .preparing:
                        return Empty().eraseToAnyPublisher()
                    case .failed(let error):
                        return Fail(error: error).eraseToAnyPublisher()
                    case .waiting(let error):
                        // 에러가 무엇이냐에 따라 기다리거나 취소하거나 동작을 취해야 한다.
                        return Empty().eraseToAnyPublisher()
                    case .cancelled:
                        return Fail(error: SwiftMQTTError.cancelled).eraseToAnyPublisher()
                    @unknown default:
                        return Fail(error: SwiftMQTTError.unknown).eraseToAnyPublisher()
                    }
                }.prefix(1)
                .timeout(10.0, scheduler: self.queue, customError: { SwiftMQTTError.timeOut })
                .sink(receiveCompletion: { (completion) in
                    switch completion {
                    case .finished:
                        continuation.resume(returning: ())
                    case .failure(let error):
                        switch error {
                        case let error as NWError:
                            continuation.resume(throwing: SwiftMQTTError.network(error))
                        case let error as SwiftMQTTError:
                            continuation.resume(throwing: error)
                        default:
                            continuation.resume(throwing: SwiftMQTTError.any(error))
                        }
                    }
                }, receiveValue: { })
        })
        _ = cancellable
    }
    
    private func startToCheckConnectionState() {
        self.connectionStateSubject.sink(receiveValue: { [weak self] (state) in
            guard let strongSelf = self else { return }
            switch state {
            case .cancelled:
                strongSelf.stateSubject.send(.cancelled)
                print("MQTT3Client cancelled")
            case .failed(let error):
                strongSelf.stateSubject.send(.failed(SwiftMQTTError.network(error)))
                print("MQTT3Client failed. \(error)")
            default:
                break
            }
        }).store(in: &self.cancellables)
    }
    
    
}


// MARK: - Send Packet
extension MQTT3.ConnectionCore {
    
    private func sendConnectPacket() {
        let connectPacket = MQTT3.ConnectPacket(username: self.connectionInfo.username.map { MQTTString($0) },
                                                password: self.connectionInfo.password.map { MQTTString($0) },
                                                willMessage: nil,
                                                cleanSession: self.connectionInfo.cleanStart,
                                                clientID: MQTTString(self.connectionInfo.clientID),
                                                keepAlive: self.connectionInfo.keepAlive)
        self.send(connectPacket)
    }
    
    
    private func sendPublishAckPacket(withPacketIdentifier identifier: UInt16) {
        let packet = MQTT3.PublishAckPacket(identifier: identifier)
        self.send(packet)
    }
    
    private func performAcknowledgmentForQos2Publish(withPacketIdentifier identifier: UInt16) async throws {
        self.sendPublishReceivedPacket(withPacketIdentifier: identifier)
        try await self.waitForPublishReleasePacketReceived(withPacketIdentifier: identifier)
        self.sendPublishCompletePacket(withPacketIdentifier: identifier)
    }
    
    private func sendPublishReceivedPacket(withPacketIdentifier identifier: UInt16) {
        let packet = MQTT3.PublishReceivedPacket(identifier: identifier)
        self.send(packet)
    }
    
    private func waitForPublishReleasePacketReceived(withPacketIdentifier identifier: UInt16) async throws {
        var cancellable: AnyCancellable?
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            cancellable = self.streamReader.receivedControlPacketPublisher
                .filter {
                    if case let .pubrel(packet) = $0,
                       packet.identifier == identifier {
                        return true
                    } else {
                        return false
                    }
                }.prefix(1)
                .sink(receiveValue: { _ in
                    
                })
        }
        _ = cancellable
    }
    
    private func sendPublishCompletePacket(withPacketIdentifier identifier: UInt16) {
        let packet = MQTT3.PublishCompletePacket(identifier: identifier)
        self.send(packet)
    }
    
    private func sendPingRequestPacket() {
        self.streamReader.receivedControlPacketPublisher
            .compactMap {
                if case let .pingresp(packet) = $0 {
                    return packet
                } else {
                    return nil
                }
            }.prefix(1)
            .sink(receiveValue: { (packet: MQTT3.PingResponsePacket) in
                print("received ping response")
            }).store(in: &self.cancellables)
        
        self.send(MQTT3.PingRequestPacket())
    }

    private func subscribePublishPacket() {
        self.streamReader.receivedControlPacketPublisher.sink(receiveValue: { [weak self] (packet) in
            guard let strongSelf = self else { return }
            switch packet {
            case .publish(let packet):
                switch packet.qosWithIdentifier {
                case .qos0:
                    break
                case .qos1(let identifier):
                    strongSelf.sendPublishAckPacket(withPacketIdentifier: identifier)
                case .qos2(let identifier):
                    Task {
                        try await strongSelf.performAcknowledgmentForQos2Publish(withPacketIdentifier: identifier)
                    }
                }
            default:
                break
            }
        }).store(in: &self.cancellables)
    }

    
    private func send(_ controlPacket: MQTT3ControlPacket) {
        let content = controlPacket.bytes()
        print("send content \(controlPacket)\n\(content)")
        self.internalConnection.send(content: content,
                                     completion: .contentProcessed({ (error) in
            if let error = error {
                print("failed to send control packet(\(controlPacket)). error: \(error)")
                
            } else {
                
            }
        }))
    }
}


extension MQTT3.ConnectionCore {
    private func startStreamReading() {
        self.streamReader.start()
    }
    
    private func stopStreamReading() {
        self.streamReader.cancel()
    }
    
}

// MARK: - KeepAlive
extension MQTT3.ConnectionCore {
    private func startKeepAlive() {
        let interval: Int = self.connectionInfo.keepAlive > 0 ? Int(self.connectionInfo.keepAlive) : 60
        let timer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        timer.schedule(deadline: .now() + .seconds(interval), repeating: .seconds(interval))
        timer.setEventHandler(handler: { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.connectionStateSubject.value == .ready else {
                return
            }
            
            strongSelf.sendPingRequestPacket()
        })
        timer.resume()
        self.keepAliveTimer = timer
    }
    
    private func stopKeepAlive() {
        guard let timer = self.keepAliveTimer else {
            return
        }
        self.keepAliveTimer = nil
        
        timer.setEventHandler(handler: { })
        timer.cancel()
    }
}
