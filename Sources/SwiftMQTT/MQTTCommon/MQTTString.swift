//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/15.
//

import Foundation

struct MQTTString: ExpressibleByStringLiteral, MQTTBytesRepresentable {
    typealias StringLiteralType = String

    var bytesMQTTEncoded: [UInt8] {
        return UInt16(self.rawString.utf8.count).bytesMQTTEncoded + self.rawString.utf8
    }
    
    let rawString: String
    
    init(stringLiteral value: String) {
        self.init(value)
    }
    
    init(_ rawString: String) {
        self.rawString = Self.triming(string: rawString)
    }
    
    init(_ data: Data) throws {
        guard let string = String(bytes: data, encoding: .utf8) else {
            throw SwiftMQTTError.corruptData
        }
        
        self.init(string)
    }
    
    private static func triming(string: String) -> String {
        let maxLength = Int(UInt16.max)
        if string.utf8.count > maxLength {
            let startIndex = string.utf8.startIndex
            let endIndex = string.utf8.index(startIndex, offsetBy: Int(UInt16.max))
            return String(string[startIndex..<endIndex])
        } else {
            return string
        }
    }
}
