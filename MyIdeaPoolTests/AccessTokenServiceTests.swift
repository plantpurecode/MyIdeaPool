//
//  AccessTokenServiceTests.swift
//  MyIdeaPoolTests
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import XCTest
import Combine

@testable import MyIdeaPool

class AccessTokenServiceTests: XCTestCase {
    func testLoginSuccessWithRealIdeaPoolAPI() {
        var session: IdeaPoolSession? = nil
        var error: IdeaPoolError? = nil

        let loginExpectation = expectation(description: "login")
        let service = AccessTokenService()
        let cancellable = service.login(email: "email-1@test.com", password: "the-Secret-123").sink(receiveCompletion: {
            switch $0 {
            case .failure(let er):
                error = er
                break
            default:
                break
            }

            loginExpectation.fulfill()
        }) { (value) in
            session = value
        }

        waitForExpectations(timeout: 60) { (error) in
            cancellable.cancel()
        }

        XCTAssertNil(error)
        XCTAssertNotNil(session)
        XCTAssertTrue(service.hasValidSession)
        XCTAssertEqual(service.session?.jwt, session?.jwt)
        XCTAssertEqual(service.session?.refreshToken, session?.refreshToken)
    }

    func testLoginFailureWithRealIdeaPoolAPI() {
        var session: IdeaPoolSession? = nil
        var error: IdeaPoolError? = nil

        let loginExpectation = expectation(description: "login")
        let service = AccessTokenService()
        let cancellable = service.login(email: "fake@test.com", password: "the-Secret-123").sink(receiveCompletion: { (completion) in
            switch completion {
            case .failure(let er):
                error = er
                break
            default:
                break
            }

            loginExpectation.fulfill()
        }) { (value) in
            session = value
        }

        waitForExpectations(timeout: 60) { (error) in
            cancellable.cancel()
        }

        XCTAssertNil(session)
        XCTAssertNil(service.session)
        XCTAssertFalse(service.hasValidSession)

        guard case .server(let reason) = error else {
            XCTFail("Expected server error message. Got \(String(describing: error))")
            return
        }

        XCTAssertEqual(reason, "Either email or password is incorrect")
    }


    func testLoginSuccessWithFakeNetworkTransporter() {
        var session: IdeaPoolSession? = nil

        let loginExpectation = expectation(description: "login")
        let service = AccessTokenService(requestFactory: IdeaPoolRequestFactory(transporter: FakeNetworkTransporter()))
        let cancellable = service.login(email: "email-1@test.com", password: "the-Secret-123").sink(receiveCompletion: { _ in
            loginExpectation.fulfill()
        }) { (value) in
            session = value
        }

        waitForExpectations(timeout: 60) { (error) in
            cancellable.cancel()
        }

        XCTAssertNotNil(session)
        XCTAssertTrue(service.hasValidSession)
        XCTAssertEqual(service.session?.jwt, session?.jwt)
        XCTAssertEqual(service.session?.refreshToken, session?.refreshToken)
        XCTAssertEqual(session?.jwt, "jwt")
        XCTAssertEqual(session?.refreshToken, "rft")
    }

    func testLoginFailureWithFakeNetworkTransporter() {
        var session: IdeaPoolSession? = nil
        var receivedError: IdeaPoolError? = nil

        let loginExpectation = expectation(description: "login")
        let service = AccessTokenService(requestFactory:  IdeaPoolRequestFactory(transporter: FakeNetworkTransporter(errorToThrow: URLError(.badServerResponse))))
        let cancellable = service.login(email: "email-1@test.com", password: "the-Secret-123")
            .sink(receiveCompletion: { (completion) in
            switch completion {
            case .failure(let error):
                receivedError = error
                break
            default:
                break
            }

            loginExpectation.fulfill()
        }) { (value) in
            session = value
        }

        waitForExpectations(timeout: 60) { (error) in
            cancellable.cancel()
        }

        XCTAssertNil(session)
        XCTAssertFalse(service.hasValidSession)
        XCTAssertNotNil(receivedError)

        guard case .underlying(let underlying) = receivedError else {
            XCTFail("Expected error of type .underlying but got \(String(describing: receivedError))")
            return
        }

        XCTAssertEqual(underlying.localizedDescription, "The operation couldn’t be completed. (NSURLErrorDomain error -1011.)")
    }

    func testLoginFailureWithUnauthorizedStatusCodeUsingFakeNetworkTransporter() {
        var session: IdeaPoolSession? = nil
        var receivedError: IdeaPoolError? = nil
        let response = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 400, httpVersion: nil, headerFields: ["Content-Type": "application/json"])

        let loginExpectation = expectation(description: "login")
        let service = AccessTokenService(requestFactory: IdeaPoolRequestFactory(transporter: FakeNetworkTransporter(response: response)))
        let cancellable = service.login(email: "email-1@test.com", password: "the-Secret-123").sink(receiveCompletion: { (completion) in
            switch completion {
            case .failure(let error):
                receivedError = error
                break
            default:
                break
            }

            loginExpectation.fulfill()
        }) { (value) in
            session = value
        }

        waitForExpectations(timeout: 60) { (error) in
            cancellable.cancel()
        }

        XCTAssertNil(session)
        XCTAssertFalse(service.hasValidSession)
        XCTAssertNotNil(receivedError)

        guard case .server(let reason) = receivedError else {
            XCTFail("Expected error of type .underlying but got \(String(describing: receivedError))")
            return
        }

        XCTAssertEqual(reason, "Invalid status code")
    }
}
