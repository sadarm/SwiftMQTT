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
