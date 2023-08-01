//
//  IzumrudTests.swift
//  IzumrudTests
//
//  Created by Sergey Balalaev on 31.07.2023.
//  Copyright © 2023 Byterix. All rights reserved.
//

import XCTest
import iSamaraCounters
import iSamaraCountersModels

final class IzumrudTests: XCTestCase {

    let service = SamaraEnergoSendDataService(data: SamaraEnergoData(domain: "http://127.0.0.1:8080"))

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSamaraEnergo() throws {
        let expectation = expectation(description: "SamaraEnergo")

        service
            .map(SendDataMockInput(email: "sof.bix@mail.ru", electricCounterNumber: "123", dayElectricCount: "12", nightElectricCount: "8"))
            .done{ _ in
                expectation.fulfill()
            }.catch{ error in
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }

        waitForExpectations(timeout: 30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

    func testErrorSamaraEnergo() throws {
        let expectation = expectation(description: "SamaraEnergo")

        service
            .map(SendDataMockInput(email: "!", electricCounterNumber: "123"))
            .done{ _ in
                XCTFail()
                expectation.fulfill()
            }.catch{ error in
                defer {
                    expectation.fulfill()
                }
                let error = error as NSError
                XCTAssertEqual(417, error.code)
            }

        waitForExpectations(timeout: 30) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
    }

}
