//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3Message {
    let qos: MQTTQoS
    let topic: MQTTString
    let payload: MQTTString
    let retain: Bool
}

extension MQTT3Message: MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        var bytes: [UInt8] = []
        bytes.append(self.topic)
        bytes.append(self.payload)
        return bytes
    }
}
