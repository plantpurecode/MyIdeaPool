//
//  HeaderView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI


struct HeaderWrapperView: View {
    @Environment(\.isTall) var isTall
    
    let wrapped: AnyView
    let text: String
    let rightItem: AnyView?

    init<Content: View>(text: String = "The Idea Pool", rightItem: AnyView?, animations: (AnyView) -> AnyView = { $0 }, @ViewBuilder content: () -> Content) {
        self.text = text
        self.rightItem = rightItem

        wrapped = animations(content().eraseToAnyView())
    }

    var height: CGFloat {
        50
    }
    
    var body: some View {
        GeometryReader { g in
            self.wrapped
                .frame(width: g.frame(in: .global).width,
                       height: g.frame(in: .global).height - self.height,
                       alignment: .bottom)
                .padding(.top, self.height)

            HeaderView(text: self.text, rightItem: self.rightItem)
                .frame(width: g.frame(in: .global).width, height: self.height, alignment: .top)
        }
    }
}

struct HeaderView: View {
    @Environment(\.isTall) var isTall

    let text: String?
    let rightItem: AnyView?

    init(text: String? = "The Idea Pool", rightItem: AnyView? = nil) {
        self.rightItem = rightItem
        self.text = text
    }

    var body: some View {
        HStack(alignment: .center, spacing: isTall ? 16 : 8) {
            Image("lightbulb")
                .padding(.leading, isTall ? 20 : 12)
                .padding(.trailing, 5)

            self.text.flatMap {
                Text($0)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .fixedSize()
            }
            
            Spacer()

            self.rightItem.flatMap {
                $0
                    .fixedSize()
                    .padding(.trailing, isTall ? 16 : 8)
            }
        }
        .padding(.bottom, 16)
        .padding(.top, isTall ? 54 : 24)
        .background(
            Rectangle()
                .foregroundColor(Color(UIColor(red: 0, green:168/255.0, blue:67/255.0, alpha: 1)))
        )
        .edgesIgnoringSafeArea(.top)
    }
}

struct HeaderView_Preview: PreviewProvider {
    static var previews: some View {
        HeaderView(rightItem: AnyView(Text("Food")))
    }
}
