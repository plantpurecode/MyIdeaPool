//
//  IdeaPoolButton.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 20/10/2019.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

struct IdeaPoolButton: View {
    enum ButtonColor {
        case green
        case gray
        
        fileprivate var underlyingColor: Color {
            switch self {
            case .green:
                return Color(red: 0, green:168/255.0, blue:67/255.0)
            case .gray:
                return Color(red: 206/255.0, green:206/255.0, blue:206/255.0)
            }
        }
    }
    
    let color: ButtonColor
    let title: String
    let action: () -> Void
    let width: Int
    let height: Int
    let fontSize: Int
    
    init(color: ButtonColor, title: String, width: Int = 300, height: Int = 50, fontSize: Int = 14, action: @escaping () -> Void) {
        self.color = color
        self.title = title
        self.width = width
        self.height = height
        self.fontSize = fontSize
        self.action = action
    }
    
    var body: some View {
        return Button(action: self.action, label: {
            Text(title)
                .font(.system(size: CGFloat(fontSize)))
                .foregroundColor(.white)
                .frame(minWidth: CGFloat(width))
                .contentShape(Rectangle())
        })
        .frame(width: CGFloat(width),
               height: CGFloat(height),
               alignment: .center)
        .background(self.color.underlyingColor)
    }
}
