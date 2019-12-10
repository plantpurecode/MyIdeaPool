//
//  CreateEditIdeaView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 16/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

struct IdeaScoreRow: View, Identifiable {
    var id: String {
        title
    }

    let title: String
    let value: Binding<Int>

    var body: some View {
        Stepper(value: value, in: 1...10) {
            HStack {
                Text(title)
                .font(.body)
                .fontWeight(.semibold)

                Spacer()

                Text("\(value.wrappedValue)")
                    .foregroundColor(.secondary)
            }
        }
    }
}

class CreateEditIdeaViewModel: ObservableObject {
    @Published var content: String = ""
    @Published var impact: Int = 5
    @Published var ease: Int = 5
    @Published var confidence: Int = 5

    private let cancelAction: () -> Void
    private let saveAction: (Idea) -> Void
    private let ideaToEdit: ConcreteIdea?
    
    var isEditing: Bool {
        return ideaToEdit != nil
    }
    
    var average: Float {
        return Float(impact + ease + confidence) / 3
    }
    
    init(idea: ConcreteIdea?, cancelAction: @escaping () -> Void, saveAction: @escaping (Idea) -> Void) {
        self.ideaToEdit = idea
        self.cancelAction = cancelAction
        self.saveAction = saveAction
        
        if let idea = idea {
            self.content = idea.content
            self.impact = idea.impact
            self.ease = idea.ease
            self.confidence = idea.confidence
        }
    }
    
    func save() {
        self.saveAction(buildIdea())
    }
    
    func cancel() {
        self.cancelAction()
    }
    
    private func buildIdea() -> Idea {
        return Idea(content: self.content, impact: self.impact, ease: self.ease, confidence: self.confidence)
    }
}

struct CreateEditIdeaView: View {
    @Environment(\.isTall) var isTall
    @ObservedObject var viewModel: CreateEditIdeaViewModel
    @ObservedObject private var keyboardResponder = KeyboardResponder()
    
    private var titleView: some View {
        Text((viewModel.isEditing ? "Edit" : "Create") + " Idea")
            .font(.title)
            .bold()
            .padding(.vertical, isTall ? 24 : 12)
    }
    
    private var descriptionField: some View {
        TextField("Description", text: $viewModel.content)
            .disableAutocorrection(true)
            .foregroundColor(.black)
            .frame(width: nil, height: isTall ? 40 : 28, alignment: .leading)
    }
    
    private var scoreRows: some View {
        ForEach([
            IdeaScoreRow(title: "Impact", value: $viewModel.impact),
            IdeaScoreRow(title: "Ease", value: $viewModel.ease),
            IdeaScoreRow(title: "Confidence", value: $viewModel.confidence)
        ]) {
            $0
            Divider()
        }
    }
    
    var averageRow: some View {
        HStack {
            Text("Average")
            .font(.body)
            .fontWeight(.semibold)

            Spacer()

            Text("\(viewModel.average)")
                .foregroundColor(.primary)
        }
    }
        
    var body: some View {
        VStack(alignment: .leading, spacing: isTall ? 16 : 8) {
            titleView
            
            VStack {
                descriptionField
                
                Divider()

                scoreRows
                averageRow
                
                Spacer()
                    .padding(.bottom, isTall ? 16 : 4)
                
                IdeaPoolButton(color: .green, title: "SAVE", width: isTall ? 320 : 280, action: viewModel.save)
                    .padding(.bottom, 8)

                IdeaPoolButton(color: .gray, title: "CANCEL", width: isTall ? 320 : 280, action: viewModel.cancel)
            }
            .padding(.bottom, bottomPadding)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, isTall ? 24 : 36)
    }
    
    private var bottomPadding: CGFloat {
        if keyboardResponder.isActive {
            return keyboardResponder.currentHeight - (isTall ? 32 : 98)
        } else {
            return 0
        }
    }
}
