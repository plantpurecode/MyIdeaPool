//
//  Models.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation

struct IdeaPoolSession: Codable, Equatable {    
    let jwt: String
    let refreshToken: String

    init(jsonWebToken: String, refreshToken: String, expirationDate: Date? = nil) {
        self.jwt = jsonWebToken
        self.refreshToken = refreshToken
        self.expirationDate = expirationDate
    }

    private(set) var expirationDate: Date? = nil

    mutating func trackExpirationDate() {
        let dateInTenMinutes = Calendar.current.date(byAdding: .minute, value: 10, to: Date())
        expirationDate = dateInTenMinutes
    }

    var isValid: Bool {
        return [jwt, refreshToken].allSatisfy { $0.isEmpty == false } && expirationDate?.timeIntervalSinceNow ?? 0 > 0
    }
}

struct User: Codable {
    let email: String
    let name: String
    let avatarURL: String
}

struct UserToCreate: Encodable {
    let email: String
    let name: String
    let password: String
}

protocol IdeaPoolIdea {
    var content: String { get }
    var impact: Int { get }
    var ease: Int { get }
    var confidence: Int { get }
}

extension IdeaPoolIdea {
    func validate(reason: inout String?) -> Bool {
        if content.isEmpty {
            reason = "Content too short"
            return false
        }
        
        if content.count > 255 {
            reason = "Content too long"
            return false
        }

        for (name, score) in ["impact": impact, "ease": ease, "confidence": confidence] {
            if score < 1 || score > 10 {
                reason = "\(name) out of bounds! (\(score))"
                return false
            }
        }

        return true
    }
}

struct Idea: IdeaPoolIdea, Codable {
    let content: String
    let impact: Int
    let ease: Int
    let confidence: Int
}

struct ConcreteIdea: IdeaPoolIdea, Codable, Identifiable {
    let id: String
    let content: String
    let impact: Int
    let ease: Int
    let confidence: Int
    let averageScore: Float
    let createdAt: Date

    init(id: String, content: String, impact: Int, ease: Int, confidence: Int, createdAt: Date) {
        self.id = id
        self.content = content
        self.impact = impact
        self.ease = ease
        self.confidence = confidence
        self.averageScore = Float(impact + ease + confidence) / 3
        self.createdAt = createdAt
    }
}

struct IdeaForUpdating: IdeaPoolIdea, Codable {
    let id: String
    let content: String
    let impact: Int
    let ease: Int
    let confidence: Int

    init(from idea: ConcreteIdea) {
        id = idea.id
        content = idea.content
        impact = idea.impact
        ease = idea.ease
        confidence = idea.confidence
    }
}
