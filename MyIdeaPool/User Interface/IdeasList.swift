//
//  IdeasList.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 16/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI
import Combine

struct ChevronView: View {
    var body: some View {
        VStack {
            ForEach(1...3, id: \.self) { index in
                Circle()
                    .frame(width: 4, height: 4, alignment: .center)
                    .foregroundColor(Color.gray)
            }
        }
    }
}

struct IdeasListRowBottomRow: View {
    @Environment(\.isTall) var isTall
    
    let idea: ConcreteIdea
    
    private var titleToValueAndAddSpacerMapping: [(String, Int, Bool)] {
        [
            ("Impact", idea.impact, false),
            ("Ease", idea.ease, false),
            ("Confidence", idea.confidence, false),
            ("Average", Int(idea.averageScore.rounded()), true)
        ]
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ForEach(titleToValueAndAddSpacerMapping, id: \.0) { attribute in
                HStack {
                    if attribute.2 {
                        Spacer()
                    }
                    
                    VStack {
                        Text(attribute.1.description)
                            .font(.body)
                            .minimumScaleFactor(self.isTall ? 1 : 0.8)
                        Spacer()
                        Text(attribute.0)
                            .font(.body)
                            .minimumScaleFactor(self.isTall ? 1 : 0.8)
                    }
                }
            }
        }
    }
}

struct IdeasListRow: View {
    @Environment(\.isTall) var isTall
    
    let idea: ConcreteIdea
    let onTap: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text(idea.content)
                    .minimumScaleFactor(isTall ? 1 : 0.9)
                Spacer()
                ChevronView()
            }
            
            Divider()
            
            IdeasListRowBottomRow(idea: idea)
        }
        .padding(.all, 10)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(.white)
                .shadow(color: Color(UIColor.lightGray), radius: 6, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .onTapGesture(perform: self.onTap)
    }
}

class IdeasListViewModel: BaseViewModel {
    @Published var ideas: [ConcreteIdea] = []
    @Published var loadingIdeas: Bool = false
    
    override var errorMessage: String? {
        set {
            upstreamViewModel.errorMessage = newValue
        }
        get {
            upstreamViewModel.errorMessage
        }
    }
    
    override var alert: Alert? {
        set {
            upstreamViewModel.alert = newValue
        }
        get {
            upstreamViewModel.alert
        }
    }
    
    override var showingAlert: Bool {
        set {
            upstreamViewModel.showingAlert = newValue
        }
        get {
            upstreamViewModel.showingAlert
        }
    }
        
    var ideaToEdit: ConcreteIdea? = nil
    
    private let upstreamViewModel: BaseViewModel
    private let ideasService: IdeasService
    
    init(ideasService: IdeasService, upstreamViewModel: BaseViewModel) {
        self.upstreamViewModel = upstreamViewModel
        self.ideasService = ideasService
        
        super.init()
        
        requestAllIdeas()
    }

    private func sortIdeas() {
        self.ideas.sort { (one, two) -> Bool in
            if one.averageScore > two.averageScore {
                return true
            }
            
            if one.averageScore == two.averageScore, one.createdAt > two.createdAt {
                return true
            }
            
            return false
        }
    }
    
    func requestAllIdeas() {
        reset()
        
        self.loadingIdeas = true
        
        // TODO: Use paging.
        ideasService.getAllIdeas()
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (completion) in
            self.standardRequestCompletionHandler(completion: completion)
        }) { ideas in
            self.ideas = ideas
            self.sortIdeas()
            self.loadingIdeas = false
            self.objectWillChange.send()
        }.store(in: &objectWillChangeBindingSubscriptions)
    }
    
    func saveOrUpdateIdea(idea: Idea, completion: @escaping (Bool) -> Void) {
        reset()
        
        if let ideaToEdit = self.ideaToEdit {
            edit(idea: idea, editing: ideaToEdit, completion: completion)
        } else {
            create(idea: idea, completion: completion)
        }
    }
    
    func delete(idea: ConcreteIdea, completion: @escaping (Bool) -> Void) {
        reset()
        
        ideasService.delete(idea: idea)
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { (_completion) in
            self.standardRequestCompletionHandler(completion: _completion, resultClosure: completion)
        }) { (response) in
            completion(true)
            self.loadingIdeas = true
            self.requestAllIdeas()
        }.store(in: &objectWillChangeBindingSubscriptions)
    }
    
    private func create(idea: Idea, completion: @escaping (Bool) -> Void) {
        ideasService.create(idea: idea)
        .sink(receiveCompletion: {
            self.standardRequestCompletionHandler(completion: $0, resultClosure: completion)
        }, receiveValue: { (updatedIdea) in
            DispatchQueue.main.async {
                self.requestAllIdeas()
                self.objectWillChange.send()
                completion(true)
            }
        }).store(in: &objectWillChangeBindingSubscriptions)
    }
    
    private func edit(idea: Idea, editing editingIdea: ConcreteIdea, completion: @escaping (Bool) -> Void) {
        let newIdea = ConcreteIdea(id: editingIdea.id,
                                   content: idea.content,
                                   impact: idea.impact,
                                   ease: idea.ease,
                                   confidence: idea.confidence,
                                   createdAt: editingIdea.createdAt)
        ideasService.update(idea: IdeaForUpdating(from: newIdea))
        .sink(receiveCompletion: { _completion in
            self.standardRequestCompletionHandler(completion: _completion, resultClosure: completion)
        }, receiveValue: { (updatedIdea) in
            DispatchQueue.main.async {
                self.ideas.removeAll { $0.id == newIdea.id }
                self.ideas.append(updatedIdea)
                self.sortIdeas()
                
                self.objectWillChange.send()
                completion(true)
            }
        }).store(in: &objectWillChangeBindingSubscriptions)
    }
    
    private func standardRequestCompletionHandler(completion: Subscribers.Completion<IdeasServiceError>, resultClosure: @escaping (Bool) -> Void = {_ in}) {
        switch completion {
        case .failure(let error):
            var message = error.localizedDescription
            switch error {
            case .invalidIdea(let reason):
                message = "Invalid idea: \(reason)"
            default:
                break
            }

            DispatchQueue.main.async {
                self.errorMessage = message
                self.showingAlert = true

                resultClosure(false)
            }
        case .finished:
            DispatchQueue.main.async {
                resultClosure(true)
            }
            break
        }
    }
}

struct IdeasList: View {
    let ideas: [ConcreteIdea]
    let selectedIdeaClosure: (ConcreteIdea) -> Void
    
    var body: some View {
        if ideas.isEmpty {
            return EmptyIdeasView().eraseToAnyView()
        } else {
            return ScrollView(.vertical, showsIndicators: true) {
                Spacer().padding(.bottom, 8)
                
                ForEach(ideas) { idea in
                    if idea.id == self.ideas.first?.id {
                        Spacer()
                    }
                    
                    IdeasListRow(idea: idea, onTap: {
                        self.selectedIdeaClosure(idea)
                    })
                }
                
                Spacer()
                    .padding(.bottom, 32)
            }
            .eraseToAnyView()
        }
    }
}

struct EmptyIdeasView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image("lightbulb_big")
            Text("Got Ideas?")
                .font(.title)
                .foregroundColor(Color(UIColor(red:42/255.0, green:56/255.0, blue:66/255.0, alpha:1)))
        }.offset(x: 0, y: -(UIImage(named: "lightbulb_big")?.size.height ?? 2) / 2)
    }
}
