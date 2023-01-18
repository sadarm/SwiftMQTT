//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

protocol MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] { get }
}

extension MQTTBytesRepresentable {
    var bytesMQTTEncoded: [UInt8] {
        let mirror = Mirror(reflecting: self)
        return mirror.children.compactMap {
            $0.value as? MQTTBytesRepresentable
        }.reduce([UInt8](), { (result, value) in
            var result = result
            result.append(value)
            return result
        })
    }
}
