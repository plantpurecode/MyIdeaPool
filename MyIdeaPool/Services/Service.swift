//
//  Service.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation

typealias ServiceIdentifier = String

protocol Service {
    static var identifier: ServiceIdentifier { get }
}

extension Service {
    static var identifier: ServiceIdentifier { ServiceIdentifier(describing: self) }
}

protocol ServiceStorage {
    associatedtype ServiceType: Service

    func get() throws -> ServiceType?
    func save(service: ServiceType) throws
    func remove() -> ServiceType?
}
