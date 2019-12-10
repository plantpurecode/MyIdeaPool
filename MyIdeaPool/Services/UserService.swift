//
//  UserService.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

class UserService: AuthenticatedService {
    private let requestFactory = IdeaPoolRequestFactory()
    private var userSubscription: AnyCancellable?

    let session: IdeaPoolSession

    @Published var user: User?
    
    required init(session: IdeaPoolSession) {
        self.session = session

        userSubscription?.cancel()
        userSubscription =
            self.me()
            .map { Optional($0) }
            .catch { _ in Just(nil) }
            .assign(to: \.user, on: self)
    }

    private func me() -> AnyPublisher<User, IdeaPoolError> {
        do {
            return try requestFactory.request(path: "/me", method: "GET") {
                $0.addValue("application/json", forHTTPHeaderField: "Accept")
                $0.addValue(session.jwt, forHTTPHeaderField: "X-Access-Token")
            }
        } catch {
            return Fail<User, Error>(error: error).mapError { IdeaPoolError(error: $0) }.eraseToAnyPublisher()
        }
    }
}

