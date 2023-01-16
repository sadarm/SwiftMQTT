import XCTest
@testable import SwiftMQTT

final class SwiftMQTTTests: XCTestCase {
    func testExample() async throws {
        let parameters = MQTT3Connection.Parameters(host: "localhost",
                                                    port: 1883,
                                                    clientID: "UnitTest",
                                                    cleanSession: false,
                                                    keepAlive: 5)
        let connection = MQTT3Connection(using: parameters)
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
