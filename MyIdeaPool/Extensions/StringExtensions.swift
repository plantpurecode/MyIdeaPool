//
//  StringExtensions.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 08/01/2020.
//  Copyright © 2020 Jacob Relkin. All rights reserved.
//

import Foundation

extension String {
    var isValidEmail: Bool {
        return NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}").evaluate(with: self)
    }
}
