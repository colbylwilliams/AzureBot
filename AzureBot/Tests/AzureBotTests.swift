//
//  AzureBotTests.swift
//  AzureBotTests
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import XCTest
@testable import AzureBot

class AzureBotTests: XCTestCase {
    
    let timeout: TimeInterval = 30.0
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let expectation = self.expectation(description: "work")
        
        BotClient.shared.start { r in
            if let conversation = r.resource {
                print("conversationId : " + (conversation.conversationId ?? "nil"))
                print("eTag : " + (conversation.eTag ?? "nil"))
                print("expires_in : \(conversation.expires_in ?? 0)")
                print("referenceGrammarId : " + (conversation.referenceGrammarId ?? "nil"))
                print("streamUrl : " + (conversation.streamUrl ?? "nil"))
                print("token : " + (conversation.token ?? "nil"))
            } else if let error = r.error {
                print("Error: " + error.localizedDescription)
            }
            //expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
