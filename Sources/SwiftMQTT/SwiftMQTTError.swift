//
//  File.swift
//  
//
//  Created by kisu park on 2023/01/12.
//

import Foundation
import Network

public enum SwiftMQTTError: Error {
    case unknown
    case cancelled
    case timeOut
    case stateIsNotSetup
    case notEnoughData
    case corruptData
    case unexpectedType
    case typeMissmatch
    case incorrentBytes
    case unacceptableProtocolVersion
    case identifierRejected
    case serverUnavailable
    case badUserNameOrPassword
    case notAuthorized
    case network(NWError)
    case any(Error)
}

