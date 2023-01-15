//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

protocol MQTT3BytesRepresentable {
    var bytesMQTT3Encoded: [UInt8] { get }
}
