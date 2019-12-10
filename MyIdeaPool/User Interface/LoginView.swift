//
//  LoginView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI

class LoginViewModel: BaseViewModel {
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
        
        super.init()
    }
    
    func login(email: String, password: String) {
        reset()
        
        let allFields = [
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
            .login(email: email, password: password)
            .receive(on: RunLoop.main)
            .ignoreOutput()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    withAnimation {
                        self.errorMessage = error.description
                        self.showingAlert = true
                    }
                    
                    self.objectWillChange.send()
                default:
                    break
                }
            }, receiveValue: { _ in })
            .store(in: &objectWillChangeBindingSubscriptions)
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    typealias LoginAction = (String, String) -> Void
    
    let loginAction: LoginAction
    let switchToSignUpViewAction: () -> Void
        
    var body: some View {
        AuthenticationView(fields: [
            TextField("Email", text: $viewModel.email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .eraseToAnyView(),
            SecureField("Password", text: $viewModel.password)
                .textContentType(.password)
                .eraseToAnyView()
        ], buttons: [
            IdeaPoolButton(color: .green, title: "LOG IN", action: {
                self.loginAction(self.viewModel.email, self.viewModel.password)
            }).eraseToAnyView()
        ], title: "Log In",
           bottomLabelQuestion: "Don't have an account?",
           bottomLabelActionTitle: "Create one",
           bottomLabelAction: self.switchToSignUpViewAction)
    }
}
