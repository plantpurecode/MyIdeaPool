//
//  UIApplicationExtensions.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 20/10/2019.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import UIKit

extension UIApplication {
    func endEditing(force: Bool) {
        connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first(where: { $0.isKeyWindow })?
            .endEditing(force)
    }
}
