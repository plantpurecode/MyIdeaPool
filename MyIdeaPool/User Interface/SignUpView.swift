//
//  SignUpView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

class SignUpViewModel: BaseViewModel {
    var name = ""
    var email = ""
    var password = ""
    
    override var showingAlert: Bool {
        set {
            upstreamViewModel.showingAlert = newValue
        }
        
        get {
            upstreamViewModel.showingAlert
        }
    }
    
    override var errorMessage: String? {
        set {
            upstreamViewModel.errorMessage = newValue
        }
        
        get {
            upstreamViewModel.errorMessage
        }
    }

    private let accessTokenService: AccessTokenService
    private let upstreamViewModel: BaseViewModel
    
    init(accessTokenService: AccessTokenService, upstreamViewModel: BaseViewModel) {
        self.accessTokenService = accessTokenService
        self.upstreamViewModel = upstreamViewModel
    }
    
    func signUp(name: String, email: String, password: String) {
        reset()
                
        let allFields = [
            ("Name", name),
            ("Email", email),
            ("Password", password)
        ]
        
        let emptyFields = allFields.filter({ $0.1.isEmpty })
        guard emptyFields.isEmpty else {
            self.errorMessage = "\(emptyFields.map { $0.0 }.joined(separator: " and ")) must not be empty"
            self.showingAlert = true
            return
        }
        
        guard email.isValidEmail else {
            self.errorMessage = "You have entered an invalid email address!"
            self.showingAlert = true
            return
        }
                
        accessTokenService
            .signUp(user: UserToCreate(email: email, name: name, password: password))
            .map { $0 }
            .receive(on: RunLoop.main)
            .handleEvents(receiveSubscription: nil, receiveOutput: nil, receiveCompletion: { (completion) in
                switch completion {
                case .failure(let error):
                    switch error {
                    case .server(let reason):
                        self.errorMessage = reason
                        break
                    default:
                        self.errorMessage = error.localizedDescription
                        break
                    }
                default:
                    break
                }

                DispatchQueue.main.async {
                    self.showingAlert = self.errorMessage != nil
                }
            }, receiveCancel: nil, receiveRequest: nil)
            .ignoreOutput()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &objectWillChangeBindingSubscriptions)
    }
}

struct SignUpView: View {
    typealias SignUpAction = (String, String, String) -> Void
    
    @ObservedObject var viewModel: SignUpViewModel
    
    let signupAction: SignUpAction
    let switchToLoginViewAction: () -> Void
    
    @State var keyboardShowing: Bool = false

    func fields() -> [AnyView] {
        [
            TextField("Name", text: $viewModel.name)
                .disableAutocorrection(true)
                .autocapitalization(.words)
                .keyboardType(.alphabet)
                .eraseToAnyView(),
            TextField("Email", text: $viewModel.email)
                .disableAutocorrection(true)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .eraseToAnyView(),
            SecureField("Password", text: $viewModel.password)
                .eraseToAnyView()
        ]
    }

    func buttons() -> [AnyView] {
        [
            IdeaPoolButton(color: .green, title: "SIGN UP", action: {
                self.signupAction(self.viewModel.name, self.viewModel.email, self.viewModel.password)
            }).eraseToAnyView()
        ]
    }

    var body: some View {
        AuthenticationView(fields: fields(),
                           buttons: buttons(),
                           title: "Sign Up",
                           bottomLabelQuestion: "Already have an account?",
                           bottomLabelActionTitle: "Log in",
                           bottomLabelAction: self.switchToLoginViewAction)
    }
}
