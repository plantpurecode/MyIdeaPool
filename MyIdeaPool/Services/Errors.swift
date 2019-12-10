//
//  Errors.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation

protocol ErrorConvertible: Error {
    init(error: Error)
}

enum IdeaPoolError: ErrorConvertible, CustomStringConvertible {
    case refreshTokenInvalid
    case server(reason: String)
    case underlying(Error)

    init(error: Error) {
        if let er = error as? Self {
            self = er
        } else {
            self = .underlying(error)
        }
    }
    
    var description: String {
        switch self {
        case .refreshTokenInvalid:
            return "Refresh Token Invalid"
        case .server(let reason):
            return reason
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}


struct ServerErrorResponse: Decodable {
    let reason: String?
    let status: String?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case error
        case status
        case reason
    }
}

func throwPossibleIdeaPoolError(fromServerResponse response: URLSession.DataTaskPublisher.Output) throws {
    let statusCode = (response.response as? HTTPURLResponse)?.statusCode ?? 0
    if statusCode >= 400 {
        if let type = response.response.mimeType, type == "application/json" {
            do {
                let decoded = try JSONDecoder().decode(ServerErrorResponse.self, from: response.data)
                throw IdeaPoolError.server(reason: decoded.reason ?? (decoded.error ?? "Unknown reason"))
            } catch {
                if error is IdeaPoolError {
                    throw error
                }
                
                print(error)
                throw IdeaPoolError.server(reason: "HTTP Status Code \(statusCode), response: \(String(data: response.data, encoding: .utf8) ?? "")")
            }
        }
    }
}
