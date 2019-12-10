//
//  IdeasService.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

enum IdeasServiceError: ErrorConvertible {
    init(error: Error) {
        if let selfError = error as? Self {
            self = selfError
        } else {
            self = .underlying(error)
        }
    }

    case invalidParameters(String)
    case invalidIdea(String)
    case requestCreation
    case underlying(Error)
}

class IdeasService: AuthenticatedService {
    private let requestFactory = IdeaPoolRequestFactory()
    
    let session: IdeaPoolSession

    required init(session: IdeaPoolSession) {
        self.session = session
    }

    func create(idea: Idea) -> AnyPublisher<ConcreteIdea, IdeasServiceError> {
        var validationError:String?
        guard idea.validate(reason: &validationError) else {
            return Fail<ConcreteIdea, IdeasServiceError>(error: .invalidIdea(validationError ?? "Unknown reason"))
                .eraseToAnyPublisher()
        }
        
        do {
            let publisher:AnyPublisher<ConcreteIdea, IdeasServiceError> = try requestFactory.request(path: "ideas", method: "POST") {
                $0.addValue(session.jwt, forHTTPHeaderField: "X-Access-Token")

                try $0.encoding(encoder: .json, body: idea)
            }
            
            return publisher
        } catch {
            return Fail<ConcreteIdea, IdeasServiceError>(error: .requestCreation).eraseToAnyPublisher()
        }
    }

    func delete(idea: ConcreteIdea) -> AnyPublisher<Bool, IdeasServiceError> {
        do {
            return try requestFactory.request(path: "ideas/\(idea.id)", method: "DELETE") {
                $0.addValue(session.jwt, forHTTPHeaderField: "X-Access-Token")
                $0.addValue("application/json", forHTTPHeaderField: "Accept")
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail<Bool, IdeasServiceError>(error: .requestCreation).eraseToAnyPublisher()
        }
    }

    func getIdeas(on page: Int) -> AnyPublisher<[ConcreteIdea], IdeasServiceError> {
        guard page > 0 else {
            return Fail<[ConcreteIdea], IdeasServiceError>(error: .invalidParameters("Page index must be > 0"))
                .eraseToAnyPublisher()
        }

        do {
            return try requestFactory.request(path: "ideas", method: "GET") {
                // Encode the page parameter into the request
                var components = URLComponents(url: $0.url!, resolvingAgainstBaseURL: false)!
                components.queryItems = [URLQueryItem(name: "page", value: "\(page)")]
                
                $0.url = components.url
                $0.addValue(session.jwt, forHTTPHeaderField: "X-Access-Token")
                $0.addValue("application/json", forHTTPHeaderField: "Accept")
            }
            .eraseToAnyPublisher()
        } catch {
            return Fail<[ConcreteIdea], IdeasServiceError>(error: .requestCreation).eraseToAnyPublisher()
        }
    }
    
    func getAllIdeas(from page: Int = 1, previousIdeas: [ConcreteIdea] = []) -> AnyPublisher<[ConcreteIdea], IdeasServiceError> {
        let pageSize = 10
        return getIdeas(on: page).flatMap { ideas -> AnyPublisher<[ConcreteIdea], IdeasServiceError> in
            let combinedIdeas = previousIdeas + ideas
            
            if ideas.count == pageSize {
                return self.getAllIdeas(from: page + 1, previousIdeas: combinedIdeas)
            } else {
                return Just(combinedIdeas).mapError { IdeasServiceError(error: $0) }.eraseToAnyPublisher()
            }
        }.eraseToAnyPublisher()
    }

    func update(idea: IdeaForUpdating) -> AnyPublisher<ConcreteIdea, IdeasServiceError> {
        var validationError:String?
        guard idea.validate(reason: &validationError) else {
            return Fail<ConcreteIdea, IdeasServiceError>(error: .invalidIdea(validationError ?? "Unknown reason")).eraseToAnyPublisher()
        }

        do {
            return try requestFactory.request(path: "ideas/\(idea.id)", method: "PUT") {
                $0.addValue(session.jwt, forHTTPHeaderField: "X-Access-Token")
                try $0.encoding(encoder: .json, body: idea)
            }.eraseToAnyPublisher()
        } catch {
            return Fail<ConcreteIdea, IdeasServiceError>(error: .requestCreation).eraseToAnyPublisher()
        }
    }
}
