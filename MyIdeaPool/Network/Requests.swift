//
//  Requests.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

protocol DecoderType {
    func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable
}

protocol EncoderType {
    func encode<T>(_ value: T) throws -> Data where T : Encodable
    func configure(urlRequest: inout URLRequest)
}

extension JSONDecoder: DecoderType {}
extension PropertyListDecoder: DecoderType {}

extension JSONEncoder: EncoderType {
    func configure(urlRequest: inout URLRequest) {
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
    }
}

extension PropertyListEncoder: EncoderType {
    func configure(urlRequest: inout URLRequest) {
        urlRequest.addValue("application/x-plist", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/x-plist", forHTTPHeaderField: "Accept")
    }
}

enum URLRequestEncoder {
    case json
    case plist

    var underlyingEncoderType: EncoderType {
        switch self {
        case .json:
            return {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                return encoder
            }()
        case .plist:
            return PropertyListEncoder()
        }
    }
}

extension URLRequest {
    mutating func encoding<T: Encodable>(encoder: URLRequestEncoder, body: T) throws {
        encoder.underlyingEncoderType.configure(urlRequest: &self)
        self.httpBody = try encoder.underlyingEncoderType.encode(body)
    }
}

protocol RequestFactory {
    static func decoder() -> DecoderType

    func request<ResponseType: Decodable, ErrorType: ErrorConvertible>(path: String, method: String, configuredBy: (inout URLRequest) throws -> Void) throws -> AnyPublisher<ResponseType, ErrorType>
}

extension RequestFactory {
    // Use the JSONDecoder by default.
    static func decoder() -> DecoderType {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

typealias BasicNetworkTransporterPublisher = AnyPublisher<URLSession.DataTaskPublisher.Output, URLSession.DataTaskPublisher.Failure>

protocol NetworkTransporter {
    func beginTransport(for request: URLRequest) -> BasicNetworkTransporterPublisher
}

fileprivate var formatter: DateFormatter {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .medium
    f.timeZone = .current
    return f
}

extension URLSession: NetworkTransporter {
    func beginTransport(for request: URLRequest) -> BasicNetworkTransporterPublisher {
        let identifyingPrefix = { "[\(formatter.string(from: Date()))] - [\(request.httpMethod!) \(request.url!)]" }
        print(identifyingPrefix())
        
        return dataTaskPublisher(for: request)
            .handleEvents(receiveSubscription: nil, receiveOutput: {
                let responseString = String(data: $0.data, encoding: .utf8) ?? "[NO DATA]"
                print(identifyingPrefix() + " response: \n" + (responseString.isEmpty ? "[EMPTY]" : responseString))
            }, receiveCompletion: {
                switch $0 {
                case .failure(let error):
                    print(identifyingPrefix() + " [ERROR]\n" + error.localizedDescription)
                    break
                case .finished:
                    break
                }
            }, receiveCancel: nil, receiveRequest: nil)
            .eraseToAnyPublisher()
    }
}
