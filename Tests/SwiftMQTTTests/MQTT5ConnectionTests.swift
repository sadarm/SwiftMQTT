import XCTest
@testable import SwiftMQTT

final class MQTT5ConnectionTests: XCTestCase {
    func testExample() async throws {
        let parameters = MQTTConnectionParameters(clientID: "UnitTest", mqttProtocol: .v5(.init(connectProperties: MQTT5.ConnectProperties.init(userProperty: []))))
        
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
