//
//  This file is part of Blokada.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Copyright © 2021 Blocka AB. All rights reserved.
//
//  @author Kar
//

import XCTest
@testable import Mocked

class AppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let expectation = XCTestExpectation(description: "Will dload")

        let client = HttpClientService()
        let publisher = client.get(url: "https://api.blocka.net/v2/gateway")
        .sink(
            receiveCompletion: { completion in
                
            },
            receiveValue: { received in
                XCTAssertEqual("llol", "\(received)")
                expectation.fulfill()
            }
        )
        XCTAssertNotNil(publisher)
        wait(for: [expectation], timeout: 5.0)
    }

}
