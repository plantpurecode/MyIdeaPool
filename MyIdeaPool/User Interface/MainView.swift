//
//  MainView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: IdeasListViewModel
    
    @State var showingAddButton: Bool = false
    @State var showingIdeaEditor: Bool = false
    @State var showingEditingSheet: Bool = false
    
    private var ideaEditor: AnyView {
        CreateEditIdeaView(viewModel: CreateEditIdeaViewModel(idea: viewModel.ideaToEdit, cancelAction: {
            withAnimation {
                self.showingIdeaEditor = false
            }
        }, saveAction: { idea in
            self.viewModel.saveOrUpdateIdea(idea: idea) { completed in
                withAnimation {
                    if completed {
                        self.showingIdeaEditor = false
                    }
                }
            }
        }))
        .transition(.move(edge: .leading))
        .eraseToAnyView()
    }
    
    private var ideasList: AnyView {
        GeometryReader { g in
            ZStack {
                IdeasList(ideas: self.viewModel.ideas) { idea in
                    withAnimation {
                        self.showingEditingSheet = true
                        self.viewModel.ideaToEdit = idea
                    }
                }
                
                Button(action: {
                    withAnimation {
                        self.viewModel.ideaToEdit = nil
                        self.showingIdeaEditor = true
                    }
                }, label: {
                    Image("btn_add")
                })
                .shadow(radius: 8)
                .position(x: g.frame(in: .global).size.width - 48,
                          y: g.frame(in: .global).size.height - 64)
            }
        }
        .eraseToAnyView()
    }
    

    private var underlyingView: some View {
        if viewModel.loadingIdeas {
            return VStack {
                Spacer()
                ActivityIndicator(isAnimating: $viewModel.loadingIdeas, style: .large)
                Spacer()
            }.eraseToAnyView()
        }
        
        if showingIdeaEditor {
            return ideaEditor
        } else {
            return ideasList
        }
    }
    
    var body: some View {
        underlyingView
        .actionSheet(isPresented: $showingEditingSheet, content: { () -> ActionSheet in
            ActionSheet(title: Text("Actions"), message: nil, buttons: [
                ActionSheet.Button.default(Text("Edit"), action: {
                    withAnimation {
                        self.showingIdeaEditor = true
                    }
                }),
                ActionSheet.Button.destructive(Text("Delete"), action: {
                    self.viewModel.alert = Alert(title: Text("Are you sure?"), message: Text("This idea will be permanently deleted."), primaryButton: Alert.Button.default(Text("OK"), action: {
                        // delete
                        self.viewModel.delete(idea: self.viewModel.ideaToEdit!) { (deleted) in
                            self.viewModel.ideaToEdit = nil
                        }
                    }), secondaryButton: Alert.Button.cancel({
                        self.viewModel.ideaToEdit = nil
                    }))
                    
                    self.viewModel.showingAlert = true
                }),
                ActionSheet.Button.cancel({
                    self.viewModel.ideaToEdit = nil
                })
            ])
        })
    }
}
