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
        let expectation = XCTestExpectation(description: "1")
        let expectation3 = XCTestExpectation(description: "2")

        let subject = ConfigService(
            remote: ICloudPersistenceService(),
            remoteLegacy: KeychainPersistenceService()
        )

        let publisher = subject.account
        .sink(
            receiveCompletion: { completion in
                
            },
            receiveValue: { received in
                XCTAssertEqual("rmiqpzizmfuu", received.id)
                expectation.fulfill()
            }
        )
        XCTAssertNotNil(publisher)

        let pub2 = subject.hasAccount.sink { completion in
            
        } receiveValue: { it in
            XCTAssertEqual(true, it)
            expectation3.fulfill()
        }
        XCTAssertNotNil(pub2)


        wait(for: [expectation, expectation3], timeout: 5.0)
    }

}
