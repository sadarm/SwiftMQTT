//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/16.
//

import Foundation

extension MQTT5 {
    struct PublishPacket: MQTT5ControlPacket {
        var typeAndFlags: MQTT5.ControlPacketTypeAndFlags {
            MQTT5.ControlPacketTypeAndFlags(type: .publish, flags: 0)
        }
        
        
        
        func variableHeader() -> Data {
            return Data()
        }
        
        func payload() -> Data {
            return Data()
        }
    }
}

extension MQTT5.PublishPacket {
    struct Properties: MQTTBytesRepresentable {
        var willDelayInterval: MQTT5.Properties.WillDelayInterval?
        var payloadFormatIndicator: MQTT5.Properties.PayloadFormatIndicator?
        var messageExpiryInterval: MQTT5.Properties.MessageExpiryInterval?
        var contentType: MQTT5.Properties.ContentType?
        var responseTopic: MQTT5.Properties.ResponseTopic?
        var correlationData: MQTT5.Properties.CorrelationData?
        var userProperty: [MQTT5.Properties.UserProperty]
    }
}
