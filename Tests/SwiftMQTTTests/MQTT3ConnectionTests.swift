//
//  File.swift
//  
//
//  Created by M1ProMacbook-kisupark on 2023/01/13.
//

import Foundation
import XCTest

@testable import SwiftMQTT

final class MQTT3ConnectionTests: XCTestCase {
        
    func test_a() async throws {
        let parameters = MQTTConnectionParameters(clientID: "UnitTest", mqttProtocol: .v3(.init()))
        
        let connection = MQTTConnection(host: "localhost", port: 1883, using: parameters)
        try await connection.start()
        try await connection.subscribeTopics([("/stat", .qos2)])
        
        let expection = expectation(description: "waiting")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60.0, execute: {
            expection.fulfill()
        })
        
        await waitForExpectations(timeout: 100.0)
        
        _ = connection
    }
}
