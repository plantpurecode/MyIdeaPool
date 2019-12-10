//
//  AuthenticatedService.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import Foundation
import Combine

protocol AuthenticatedService: Service {
    var session: IdeaPoolSession { get }

    init(session: IdeaPoolSession)
}
