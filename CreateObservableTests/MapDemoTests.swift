//
//  MapDemoTests.swift
//  CreateObservableTests
//
//  Created by 岩本康孝 on 2022/05/18.
//

import XCTest
@testable import CreateObservable

class MapDemoTests: XCTestCase {

    var expect: XCTestExpectation!

    override func setUpWithError() throws {
        expect = expectation(description: "")
        expect.expectedFulfillmentCount = 1
    }

    func test() throws {
        let observable = Observable.of(1, 2, 3)
            .map { $0 * 10 }

        var array = [Int]()

        let observer = AnyObserver<Int> {
            switch $0 {
            case .next(let element):
                array.append(element)
            case .completed:
                // 10倍されてるか検証する
                XCTAssertEqual(array, [10, 20, 30])
                self.expect.fulfill()
            }
        }

        observable.subscribe(observer)

        waitForExpectations(timeout: 0.1)
    }
}
