//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/16.
//

import Foundation

public enum MQTTQoS: UInt8, Comparable {
    case qos0 = 0
    case qos1
    case qos2
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
