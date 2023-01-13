//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/07.
//

import Foundation
import Network
import Combine


enum _MQTT3ControlPacket {
    case reserved
    case connect(MQTT3ConnectPacket)
    case connack(MQTT3ConnectAckPacket)
    case publish(MQTT3PublishPacket)
    case pubact(MQTT3PublishAckPacket)
    case pubrec(MQTT3PublishReceivedPacket)
    case pubrel(MQTT3PublishReleasePacket)
    case pubcomp(MQTT3PublishCompletePacket)
    case subscribe(MQTT3SubscribePacket)
    case suback(MQTT3SubscribeAckPacket)
    case unsubscribe(MQTT3UnsubscribePacket)
    case unsuback(MQTT3UnsubscribeAckPacket)
    case pingreq(MQTT3PingRequestPacket)
    case pingresp(MQTT3PingResponsePacket)
    case disconnect(MQTT3DisconnectPacket)
    case reserved2
}

final class MQTT3StreamReader {
    
    var receivedControlPacketPublisher: AnyPublisher<_MQTT3ControlPacket, Never> {
        self.receivedControlPacketSubject.eraseToAnyPublisher()
    }
    private let receivedControlPacketSubject: PassthroughSubject<_MQTT3ControlPacket, Never> = PassthroughSubject()
    
    private let connection: NWConnection
    
    private let streamDecoder: MQTT3StreamDecoder = MQTT3StreamDecoder()
    private var buffer: Data = Data()
    
    init(_ connection: NWConnection) {
        self.connection = connection
    }
    
    func start() {
        self.receive()
    }
    
    func cancel() {
        
    }
    
    private func receive() {
        self.connection.receive(minimumIncompleteLength: 1, maximumLength: 1024 * 1024 * 2,
                                 completion: { [weak self] (content, contentContext, isComplete, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                switch error {
                case NWError.posix(.ENODATA):
                    strongSelf.connection.forceCancel()
                default:
                    break
                }
                
                return
            }
            
            if let content = content {
                strongSelf.buffer.append(content)
                strongSelf.consumeBuffer()
                strongSelf.receive()
            } else if let contentContext = contentContext {
                if !contentContext.isFinal {
                    // error
                }
            }
        })
    }
}

extension MQTT3StreamReader {
    private func consumeBuffer() {
        do {
            let result = try self.streamDecoder.decode(self.buffer)
            self.buffer = result.leftData
            self.receivedControlPacketSubject.send(result.packet)
        } catch {
            print("MQTT3StreamReader failed to decode buffer \(self.buffer)")
        }
    }
}

struct MQTT3ControlPacketTypeDecoder {
    struct DecodingResult {
        let leftData: Data
        let type: MQTT3ControlPacketType
    }

    init() {
        
    }
        
    func decode(_ data: Data) throws -> DecodingResult {
        guard let rawValue = data.first else {
            throw SwiftMQTTError.notEnoughData
        }
        
        guard let type = MQTT3ControlPacketType(rawValue: rawValue) else {
            throw SwiftMQTTError.corruptData
        }

        let leftData = data.subdata(in: (Data.Index(1)..<data.endIndex))
        return DecodingResult(leftData: leftData, type: type)
    }
}

struct MQTT3StreamDecoder {
    struct DecodingResult {
        let leftData: Data
        let packet: _MQTT3ControlPacket
    }

    private let typeDecoder = MQTT3ControlPacketTypeDecoder()
    
    init() {
        
    }

    @discardableResult
    func decode(_ data: Data) throws -> DecodingResult {
        guard let rawValue = data.first else {
            throw SwiftMQTTError.notEnoughData
        }
        
        guard let typeAndFlags = MQTT3ControlPacketTypeAndFlags(rawValue: rawValue) else {
            throw SwiftMQTTError.corruptData
        }

        return try self.decode(with: typeAndFlags, data: data)
    }
    
    private func decode(with typeAndFlags: MQTT3ControlPacketTypeAndFlags, data: Data) throws -> DecodingResult {
        switch typeAndFlags.type {
        case .reserved:
            let leftData = data.subdata(in: (1..<data.endIndex))
            return DecodingResult(leftData: leftData, packet: .reserved)
        case .reserved2:
            let leftData = data.subdata(in: (1..<data.endIndex))
            return DecodingResult(leftData: leftData, packet: .reserved2)
        default:
            return try self._decode(with: typeAndFlags, data: data)
        }
    }
    
    private func _decode(with typeAndFlags: MQTT3ControlPacketTypeAndFlags, data: Data) throws -> DecodingResult {
        guard data.count >= 2 else {
            throw SwiftMQTTError.notEnoughData
        }

        var data: Data = data
        let remainingLength = Int(data[data.startIndex+1])
        data = data[data.startIndex+2..<data.endIndex]

        let content = data[data.startIndex..<data.startIndex+remainingLength]
        let leftData = data[data.startIndex+remainingLength..<data.endIndex]
        
        return try DecodingResult(leftData: leftData, packet: self.__decode(with: typeAndFlags, data: content))
    }
    
    private func __decode(with typeAndFlags: MQTT3ControlPacketTypeAndFlags, data: Data) throws -> _MQTT3ControlPacket {
        print("received ControlPacketType \(typeAndFlags.type)")
        switch typeAndFlags.type {
        case .connect:
            throw SwiftMQTTError.unexpectedType
        case .connack:
            return try .connack(.init(data))
        case .publish:
            return try .publish(.init(typeAndFlags: typeAndFlags, data: data))
        case .puback:
            return try .pubact(.init(data))
        case .pubrec:
            return try .pubrec(.init(data))
        case .pubrel:
            return try .pubrel(.init(data))
        case .pubcomp:
            return try .pubcomp(.init(data))
        case .subscribe:
            return try .subscribe(.init(data))
        case .suback:
            return try .suback(.init(data))
        case .unsubscribe:
            return try .unsubscribe(.init(data))
        case .unsuback:
            return try .unsuback(.init(data))
        case .pingreq:
            return .pingreq(.init())
        case .pingresp:
            return .pingresp(.init())
        case .disconnect:
            return .disconnect(.init())
        case .reserved, .reserved2:
            throw SwiftMQTTError.incorrentBytes
        }
    }
}



