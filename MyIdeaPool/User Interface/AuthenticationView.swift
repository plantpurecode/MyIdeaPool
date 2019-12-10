//
//  AuthenticationView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 16/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI


struct AuthenticationView: View {
    @Environment(\.isTall) var isTall
    @ObservedObject var keyboardResponder = KeyboardResponder()
    
    let fields: [AnyView]
    let buttons: [AnyView]
    let title: String
    let bottomLabelQuestion: String
    let bottomLabelActionTitle: String
    let bottomLabelAction: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, isTall ? 32 : 16)
                .padding(.bottom, isTall ? 32 : 8)

            ForEach(0..<fields.count) {
                self.fields[$0]
                    .frame(width: nil, height: self.isTall ? 12 : 10, alignment: .leading)

                Divider()
            }.padding(.bottom, 8)
            
            ForEach(0..<buttons.count) {
                self.buttons[$0]
            }

            Spacer()
            
            HStack(alignment: .center, spacing: 8) {
                Text(bottomLabelQuestion)
                    .fixedSize()

                Button(action: {
                    withAnimation {
                        self.bottomLabelAction()
                    }
                }, label: {
                    Text(bottomLabelActionTitle)
                }).foregroundColor(.green)
            }.padding(.bottom, bottomPadding)
        }
        .padding(.horizontal, 40)
    }
    
    private var bottomPadding: CGFloat {
        if keyboardResponder.isActive {
            let offset:CGFloat = isTall ? 10 : -10
            return keyboardResponder.currentHeight - offset
        }
        
        return isTall ? 48 : 16
    }
}
