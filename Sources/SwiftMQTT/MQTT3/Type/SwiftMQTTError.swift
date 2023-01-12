//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation

public enum SwiftMQTTError: Error {
    case notEnoughData
    case corruptData
    case unexpectedType
    case typeMissmatch
    case incorrentBytes
}

