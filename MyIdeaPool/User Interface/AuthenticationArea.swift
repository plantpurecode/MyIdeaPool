//
//  AuthenticationArea.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 04/01/2020.
//  Copyright © 2020 Jacob Relkin. All rights reserved.
//

import SwiftUI

class AuthenticationAreaViewModel: ObservableObject {
    let loginViewModel: LoginViewModel
    let signupViewModel: SignUpViewModel
    
    var showingSignUpView: Bool = true {
        willSet {
            if newValue != self.showingSignUpView {
                objectWillChange.send()
            }
        }
    }
    
    init(accessTokenService: AccessTokenService, upstreamViewModel: BaseViewModel) {
        loginViewModel = LoginViewModel(accessTokenService: accessTokenService, upstreamViewModel: upstreamViewModel)
        signupViewModel = SignUpViewModel(accessTokenService: accessTokenService, upstreamViewModel: upstreamViewModel)
    }
}

struct AuthenticationAreaView: View {
    @ObservedObject var viewModel: AuthenticationAreaViewModel

    var body: some View {
        if viewModel.showingSignUpView {
            return SignUpView(viewModel: viewModel.signupViewModel, signupAction: {
                self.viewModel.signupViewModel.signUp(name: $0, email: $1, password: $2)
            }, switchToLoginViewAction: {
                UIApplication.shared.endEditing(force: true)
                self.viewModel.showingSignUpView = false
            }).eraseToAnyView()
        }
        
        return LoginView(viewModel: viewModel.loginViewModel, loginAction: {
            self.viewModel.loginViewModel.login(email: $0, password: $1)
        }, switchToSignUpViewAction: {
            UIApplication.shared.endEditing(force: true)
            self.viewModel.showingSignUpView = true
        }).eraseToAnyView()
    }
}
