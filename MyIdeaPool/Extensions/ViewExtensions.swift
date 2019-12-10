//
//  ViewExtensions.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 20/10/2019.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
