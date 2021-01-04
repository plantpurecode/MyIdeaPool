//
//  AccessTokenService.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

fileprivate struct AccessTokenRefreshResponse: Decodable {
    let jwt: String
}

class AccessTokenService: Service, Codable {
    private var refreshOperationCancellable: AnyCancellable?
    private var expirationTimer: Timer?
    
    @Published private(set) var refreshing = false
    @Published private(set) var authenticating = false
    @Published private(set) var hasValidSession = false
    
    private(set) var session: IdeaPoolSession? = nil {
        didSet {
            refreshOperationCancellable?.cancel()
            self.expirationTimer?.invalidate()
            self.expirationTimer = nil
            self.hasValidSession = self.session?.isValid ?? false

            if self.hasValidSession {
                setupExpirationTimer()
            }
            
            try? AccessTokenStorage().save(service: self)
        }
    }
    
    private func setupExpirationTimer() {
        guard let session = self.session, let expiration = session.expirationDate else {
            self.hasValidSession = false
            return
        }

        func doRefresh() {
            refreshOperationCancellable?.cancel()
            refreshOperationCancellable = self.refresh()
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { (completion) in
                    switch completion {
                    case .failure(let error):
                        print(error)
                        
                        switch error {
                        case .server(let reason):
                            print("Server error: " + reason)
                            break
                        default:
                            break
                        }
                        
                        self.session = nil
                        break
                    default:
                        break
                    }
            }, receiveValue: { (session) in
                self.session = session
            })
        }

        self.expirationTimer?.invalidate()

        if expiration.timeIntervalSinceNow > 0 {
            self.expirationTimer = Timer.scheduledTimer(withTimeInterval: expiration.timeIntervalSinceNow, repeats: false) { _ in
                doRefresh()
            }
        } else {
            self.expirationTimer = nil
            doRefresh()
        }
        
        self.hasValidSession = session.isValid
    }

    private let requestFactory: RequestFactory

    // MARK: -
    
    init(requestFactory: RequestFactory = IdeaPoolRequestFactory()) {
        self.requestFactory = requestFactory
    }

    // MARK: - Codable

    required init(from decoder: Decoder) throws {
        self.requestFactory = IdeaPoolRequestFactory()
        self.session = try? decoder.singleValueContainer().decode(IdeaPoolSession.self)
        
        defer {
            self.hasValidSession = self.session?.isValid ?? false
        }
        
        if (self.session?.isValid ?? true) == false {
            setupExpirationTimer()
        }
    }

    func encode(to encoder: Encoder) throws {
        try self.session.encode(to: encoder)
    }

    // MARK: -

    func refresh() -> AnyPublisher<IdeaPoolSession, IdeaPoolError> {
        guard let refreshToken = session?.refreshToken else {
            return Fail<IdeaPoolSession, IdeaPoolError>(error: IdeaPoolError.refreshTokenInvalid).eraseToAnyPublisher()
        }
        
        self.refreshing = true

        do {
            let request:AnyPublisher<AccessTokenRefreshResponse, IdeaPoolError> = try requestFactory.request(path: "access-tokens/refresh", method: "POST") {
                try $0.encoding(encoder: .json, body: ["refresh_token": refreshToken])
            }

            return request
            .handleEvents(receiveSubscription: nil, receiveOutput: nil, receiveCompletion: { completion in
                self.refreshing = false
            }, receiveCancel: nil, receiveRequest: nil)
            .map { response in
                var session = IdeaPoolSession(jsonWebToken: response.jwt, refreshToken: refreshToken)
                session.trackExpirationDate()
                return session
            }.eraseToAnyPublisher()
        } catch {
            return Fail<IdeaPoolSession, Error>(error: error).mapError { IdeaPoolError(error: $0) }.eraseToAnyPublisher()
        }
    }

    func login(email: String, password: String) -> AnyPublisher<IdeaPoolSession, IdeaPoolError> {
        self.authenticating = true
        
        do {
            return try requestFactory.request(path: "access-tokens", method: "POST") {
                try $0.encoding(encoder: .json, body: ["email": email, "password": password])
            }
            .handleEvents(receiveSubscription: nil, receiveOutput: {
                var sesh = $0
                sesh.trackExpirationDate()
                self.session = sesh
            }, receiveCompletion: { completion in
                self.authenticating = false
            }, receiveCancel: nil, receiveRequest: nil)
            .eraseToAnyPublisher()
        } catch {
            self.authenticating = false
            
            return Fail<IdeaPoolSession, Error>(error: error).mapError { IdeaPoolError(error: $0) }.eraseToAnyPublisher()
        }
    }

    func signUp(user: UserToCreate) -> AnyPublisher<IdeaPoolSession, IdeaPoolError> {
        self.authenticating = true
        
        do {
            return try requestFactory.request(path: "/users", method: "POST") {
                try $0.encoding(encoder: .json, body: user)
            }
            .handleEvents(receiveSubscription: nil, receiveOutput: {
                var sesh = $0
                sesh.trackExpirationDate()
                self.session = sesh
            }, receiveCompletion: { completion in
                self.authenticating = false
            }, receiveCancel: nil, receiveRequest: nil)
            .eraseToAnyPublisher()
        } catch {
            self.authenticating = false
            return Fail<IdeaPoolSession, Error>(error: error).mapError { IdeaPoolError(error: $0) }.eraseToAnyPublisher()
        }
    }

    func logout() -> AnyPublisher<Bool, IdeaPoolError> {
        expirationTimer?.invalidate()
        
        guard let refreshToken = session?.refreshToken, let accessToken = session?.jwt else {
            return Fail<Bool, IdeaPoolError>(error: IdeaPoolError.refreshTokenInvalid).eraseToAnyPublisher()
        }

        do {
            return try requestFactory.request(path: "/access-tokens", method: "DELETE") {
                $0.addValue(accessToken, forHTTPHeaderField: "X-Access-Token")

                try $0.encoding(encoder: .json, body: [
                    "refresh_token": refreshToken
                ])
            }
        } catch {
            return Fail<Bool, Error>(error: error).mapError { IdeaPoolError(error: $0) }.eraseToAnyPublisher()
        }
    }
}

class AccessTokenStorage: ServiceStorage {
    typealias ServiceType = AccessTokenService
    
    private let underlyingStorage = UserDefaults.standard

    func get() throws -> AccessTokenService? {
        guard let data = underlyingStorage.data(forKey: ServiceType.identifier) else {
            return nil
        }

        return try PropertyListDecoder().decode(ServiceType.self, from: data)
    }

    func save(service: ServiceType) throws {
        let data = try PropertyListEncoder().encode(service)
        underlyingStorage.set(data, forKey: type(of: service).identifier)
    }

    func remove() -> ServiceType? {
        guard let previous = underlyingStorage.data(forKey: AccessTokenService.identifier) else {
            return nil
        }

        underlyingStorage.removeObject(forKey: AccessTokenService.identifier)
        underlyingStorage.synchronize()
        
        return try? PropertyListDecoder().decode(AccessTokenService.self, from: previous)
    }
}
