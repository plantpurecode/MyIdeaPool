//
//  IdeaPoolRequestFactory.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

fileprivate let baseURL = URL(string: "https://small-project-api.herokuapp.com")!

struct IdeaPoolRequestFactory: RequestFactory {
    let transporter: NetworkTransporter

    init(transporter: NetworkTransporter = URLSession.shared) {
        self.transporter = transporter
    }

    func request<ResponseType: Decodable, ErrorType: ErrorConvertible>(path: String, method: String, configuredBy configuration: (inout URLRequest) throws -> Void = {_ in }) throws -> AnyPublisher<ResponseType, ErrorType> {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.timeoutInterval = 15
        request.httpMethod = method
        try configuration(&request)

        return transporter.beginTransport(for: request)
        .tryMap {
            var response = $0
            try throwPossibleIdeaPoolError(fromServerResponse: response)
            
            // Special casing for DELETE requests
            if ResponseType.self == Bool.self && $0.data.isEmpty && method == "DELETE" && ($0.response as? HTTPURLResponse)?.statusCode == 204 {
                response.data = try JSONEncoder().encode(true)
            }
            
            return try Self.decoder().decode(ResponseType.self, from: response.data)
        }
        .mapError {
            ErrorType(error: $0)
        }.eraseToAnyPublisher()
    }
}

