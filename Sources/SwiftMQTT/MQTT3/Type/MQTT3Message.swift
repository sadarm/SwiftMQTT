//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

struct MQTT3Message {
    let qos: MQTT3QoS
    let topic: MQTT3String
    let payload: MQTT3String
    let retain: Bool
}

extension MQTT3Message: MQTT3BytesRepresentable {
    var bytesMQTT3Encoded: [UInt8] {
        var bytes: [UInt8] = []
        bytes.append(self.topic)
        bytes.append(self.payload)
        return bytes
    }
}
