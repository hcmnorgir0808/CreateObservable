//
//  CreateObservableTests.swift
//  CreateObservableTests
//
//  Created by 岩本康孝 on 2022/05/13.
//

import XCTest
@testable import CreateObservable

class CreateObservableTests: XCTestCase {
    var expect: XCTestExpectation!

    override func setUpWithError() throws {
        expect = expectation(description: "")
        // 2回実行されるか検証
        expect.expectedFulfillmentCount = 1
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // AnyObserverによるsubscribeとクロージャによるsubscribeの2つでそれぞれonNextとonCompletedの
    // 2ヶ所が実行されrているか検証する(計4回)
//    func testExample() throws {
//        // ランダムな整数を文字列とする
//        let observable = Observable.just(2)
//
//        let observer = AnyObserver { [weak self] (event: Event<Int>) in
//            switch event {
//            case .next(let element):
//                XCTAssertEqual(element, 2)
//                self?.expect.fulfill()
//            case .completed:
//                self?.expect.fulfill()
//            }
//        }
//
//        // AnyObserver型はObservableのストリームを購読するようにし、そのストリームの内容はEvent型とする
//        // subscribeメソッドでAnyObserver型で購読するようにsうる
//        observable.subscribe(observer)
//
//        observable.subscribe(onNext: { [weak self] in
//            XCTAssertEqual($0, 2)
//            self?.expect.fulfill()
//        }, onCompleted: { [weak self] in
//            //
//            self?.expect.fulfill()
//        })
//
//        waitForExpectations(timeout: 0.1)
//    }

    func test() {
        let observable = Observable.of(1, 2, 3)

        var output = [Int]()

        let observer = AnyObserver { (event: Event<Int>) in
            switch event {
            case .next(let element):
                output.append(element)
            case .completed:
                XCTAssertEqual(output, [1, 2, 3])
                self.expect.fulfill()
            }
        }

        observable.subscribe(observer)

        waitForExpectations(timeout: 0.1)
    }
}
