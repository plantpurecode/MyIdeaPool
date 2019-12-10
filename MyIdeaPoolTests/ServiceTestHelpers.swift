//
//  ServiceTestHelpers.swift
//  MyIdeaPoolTests
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

struct FakeNetworkTransporter: NetworkTransporter {
    let errorToThrow: URLError?
    let response: URLResponse?

    init(errorToThrow:URLError? = nil, response: URLResponse? = nil) {
        self.errorToThrow = errorToThrow
        self.response = response
    }

    func beginTransport(for request: URLRequest) -> BasicNetworkTransporterPublisher {
        if let error = errorToThrow {
            return Fail<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>(error: error).eraseToAnyPublisher()
        }

        let fakeData = { () -> Data in
            if let response = response as? HTTPURLResponse, response.statusCode >= 400 {
                return try! JSONEncoder().encode(["reason": "Invalid status code"])
            }

            return try! JSONEncoder().encode(IdeaPoolSession(jsonWebToken: "jwt", refreshToken: "rft"))
        }()

        let publishValue = (data: fakeData, response: response ?? URLResponse())
        return Result<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>.Publisher(publishValue).eraseToAnyPublisher()
    }
}
