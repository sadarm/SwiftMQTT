//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/18.
//

import Foundation

public protocol MQTT5Property {
    associatedtype Value
    
    var identifier: MQTT5.PropertyIdentifier { get }
    var value: Value { get set }
}

extension MQTT5Property where Self.Value == UInt32 {
    var mqttFourByteInteger: MQTTFourByteInteger {
        MQTTFourByteInteger(integerLiteral: self.value)
    }
    
    var mqttBytesRepresentable: MQTTBytesRepresentable {
        self.mqttFourByteInteger
    }
}

extension MQTT5Property where Self.Value == UInt16 {
    var mqttTwoByteInteger: MQTTTwoByteInteger {
        MQTTTwoByteInteger(integerLiteral: self.value)
    }
    
    var mqttBytesRepresentable: MQTTBytesRepresentable {
        self.mqttTwoByteInteger
    }
}

extension MQTT5Property where Self.Value == Bool, Self: ExpressibleByBooleanLiteral, Self.BooleanLiteralType == Bool {
    var mqttBool: MQTTBool {
        MQTTBool(booleanLiteral: self.value)
    }
    
    var mqttBytesRepresentable: MQTTBytesRepresentable {
        self.mqttBool
    }
}

extension MQTT5Property where Self.Value == String {
    var mqttString: MQTTString {
        MQTTString(stringLiteral: self.value)
    }
    
    var mqttBytesRepresentable: MQTTBytesRepresentable {
        self.mqttString
    }
}

extension MQTT5 {
    public enum Properties {
        
    }
}

extension MQTT5.Properties {
    public struct SessionExpiryInterval: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .sessionExpiryInterval }
        public var value: UInt32
        
        public init(integerLiteral value: UInt32) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTFourByteInteger(data: data).uint32Value
        }
    }
    
    public struct ReceiveMaximum: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .receiveMaximum }
        public var value: UInt16
        
        public init(integerLiteral value: UInt16) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTTwoByteInteger(data: data).uint16Value
        }
    }
    
    public struct MaximumPacketSize: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .maximumPacketSize }
        public var value: UInt32
        
        public init(integerLiteral value: UInt32) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTFourByteInteger(data: data).uint32Value
        }
    }
    
    public struct TopicAliasMaximum: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .topicAliasMaximum }
        public var value: UInt16
        
        public init(integerLiteral value: UInt16) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTTwoByteInteger(data: data).uint16Value
        }
    }
    
    public struct RequestResponseInformation: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .requestResponseInformation }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct RequestProblemInformation: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .requestProblemInformation }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct UserProperty: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .userProperty }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct AuthenticationMethod: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .authenticationMethod }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct AuthenticationData: MQTT5Property, ExpressibleByArrayLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .authenticationData }
        public var value: Data
        
        public init(arrayLiteral elements: UInt8...) {
            self.value = Data(elements)
        }
        
        init(_ data: Data) {
            self.value = data
        }
    }
    
    public struct WillDelayInterval: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .willDelayInterval }
        public var value: UInt32
        
        public init(integerLiteral value: UInt32) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTFourByteInteger(data: data).uint32Value
        }
    }
    
    public struct PayloadFormatIndicator: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .payloadFormatIndicator }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct MessageExpiryInterval: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .messageExpiryInterval }
        public var value: UInt32
        
        public init(integerLiteral value: UInt32) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTFourByteInteger(data: data).uint32Value
        }
    }
    
    public struct ContentType: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .contentType }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct ResponseTopic: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .responseTopic }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct CorrelationData: MQTT5Property, ExpressibleByArrayLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .correlationData }
        public var value: Data
        
        public init(arrayLiteral elements: UInt8...) {
            self.value = Data(elements)
        }
        
        init(_ data: Data) {
            self.value = data
        }
    }
    
    public struct MaximumQoS: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .maximumQoS }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct RetainAvailable: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .retainAvailable }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct AssignedClientIdentifier: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .assignedClientIdentifier }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct WildecardSubscriptionAvailable: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .wildcardSubscriptionAvailable }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct SubscriptionIdentifiersAvailable: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .subscriptionIdentifiersAvailable }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct SharedSubscriptionAvailable: MQTT5Property, ExpressibleByBooleanLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .sharedSubscriptionAvailable }
        public var value: Bool
        
        public init(booleanLiteral value: Bool) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTBool(data: data).boolValue
        }
    }
    
    public struct ServerKeepAlive: MQTT5Property, ExpressibleByIntegerLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .serverKeepAlive }
        public var value: UInt16
        
        public init(integerLiteral value: UInt16) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTTwoByteInteger(data: data).uint16Value
        }
    }
    
    public struct ResponseInformation: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .responseInformation }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct ServerReference: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .serverReference }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
    
    public struct ReasonString: MQTT5Property, ExpressibleByStringLiteral {
        public var identifier: MQTT5.PropertyIdentifier { .reasonString }
        public var value: String
        
        public init(stringLiteral value: String) {
            self.value = value
        }
        
        init(_ data: Data) throws {
            self.value = try MQTTString(data).rawString
        }
    }
}
