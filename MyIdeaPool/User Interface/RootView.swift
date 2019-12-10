//
//  ContentView.swift
//  MyIdeaPool
//
//  Created by Jacob Relkin on 15/10/19.
//  Copyright © 2019 Jacob Relkin. All rights reserved.
//

import SwiftUI
import Combine

class BaseViewModel: ObservableObject {
    @Published var showingAlert: Bool = false
    
    var alert: Alert? = nil
    var errorMessage: String? = nil {
        didSet {
            DispatchQueue.main.async {
                UIApplication.shared.endEditing(force: true)
            }
        }
    }
    
    var objectWillChangeBindingSubscriptions = [AnyCancellable]()
    
    func reset() {
        self.alert = nil
        self.errorMessage = nil
        self.showingAlert = false
    }
}

class RootViewModel: BaseViewModel {
    fileprivate private(set) var wasLoggedIn = false
    fileprivate private(set) var isLoggedIn = false {
        didSet {
            if let session = self.accessTokenService.session, oldValue == false, self.isLoggedIn == true {
                if self.ideasListViewModel == nil {
                    self.ideasListViewModel = IdeasListViewModel(ideasService: IdeasService(session: session), upstreamViewModel: self)
                }
            }
       
            if oldValue == true, self.isLoggedIn == false {
                // User logged out. Remove and recreate the access token service.
                let _ = AccessTokenStorage().remove()
                self.accessTokenService = AccessTokenService()
            }
            
             if oldValue != self.isLoggedIn, wasLoggedIn != oldValue {
                withAnimation {
                    objectWillChange.send()
                }
            } else {
                objectWillChange.send()
            }
 
            self.wasLoggedIn = oldValue
        }
    }
    
    var loggingOut = false {
        willSet {
            if newValue != self.loggingOut {
                objectWillChange.send()
            }
        }
    }

    var showingActivityIndicator = true {
        willSet {
            if newValue != self.showingActivityIndicator {
                objectWillChange.send()
            }
        }
    }
    
    private var accessTokenService: AccessTokenService {
        didSet {
            self.authenticationAreaViewModel = AuthenticationAreaViewModel(accessTokenService: accessTokenService, upstreamViewModel: self)
            self.bindToAccessTokenService()
        }
    }
    
    private var refreshingAccessTokens: Bool = false {
        didSet {
            if let session = self.accessTokenService.session, session.isValid, oldValue == true && self.refreshingAccessTokens == false {
                // Request ideas when we are finished refreshing access tokens.
                if ideasListViewModel == nil {
                    ideasListViewModel = IdeasListViewModel(ideasService: IdeasService(session: session), upstreamViewModel: self)
                }
                
                ideasListViewModel?.requestAllIdeas()
            }
            
            self.showingActivityIndicator = self.refreshingAccessTokens
        }
    }
    
    private var ideasListViewModel: IdeasListViewModel?
    private(set) var authenticationAreaViewModel: AuthenticationAreaViewModel!
    
    override init() {
        self.accessTokenService = (try? AccessTokenStorage().get() ?? nil) ?? AccessTokenService()
        self.wasLoggedIn = self.accessTokenService.hasValidSession
            
        super.init()
        
        self.bindToAccessTokenService()
        self.authenticationAreaViewModel = AuthenticationAreaViewModel(accessTokenService: accessTokenService, upstreamViewModel: self)
        self.showingActivityIndicator = true
    }
    
    override func reset() {
        super.reset()
    
        self.loggingOut = false
        self.showingActivityIndicator = false
    }
    
    func mainView() -> MainView? {
        guard let ideasListViewModel = ideasListViewModel else {
            return nil
        }
            
        return MainView(viewModel: ideasListViewModel)
    }

    func logout() {
        self.showingActivityIndicator = true
        
        accessTokenService.logout()
        .replaceError(with: false)
        .sink { _ in
            DispatchQueue.main.async {
                self.ideasListViewModel = nil
                
                withAnimation {
                    self.loggingOut = true
                    self.isLoggedIn = false
                }
                
                self.reset()
            }
        }
        .store(in: &objectWillChangeBindingSubscriptions)
    }

    var showsLogoutBarItem: Bool {
        isLoggedIn
    }
    
    private func bindToAccessTokenService() {
        self.accessTokenService.$authenticating
            .receive(on: RunLoop.main)
            .assign(to: \.showingActivityIndicator, on: self)
            .store(in: &objectWillChangeBindingSubscriptions)

        self.accessTokenService.$refreshing
            .receive(on: RunLoop.main)
            .assign(to: \.refreshingAccessTokens, on: self)
            .store(in: &objectWillChangeBindingSubscriptions)
        
        self.accessTokenService.$hasValidSession
            .receive(on: RunLoop.main)
            .assign(to: \.isLoggedIn, on: self)
            .store(in: &objectWillChangeBindingSubscriptions)
    }
}

struct RootView: View {
    @ObservedObject var viewModel = RootViewModel()

    private var logoutButton: AnyView {
        let button = Button(action: {
            self.viewModel.logout()
        }, label: {
            Text("Log out")
                .foregroundColor(.white)
        })

        return button.eraseToAnyView()
    }

    var body: some View {
        HeaderWrapperView(rightItem: viewModel.showsLogoutBarItem ? logoutButton : nil, animations: {
            if viewModel.loggingOut {
                return $0.transition(.opacity).eraseToAnyView()
            }

            if viewModel.isLoggedIn {
                return $0.transition(.asymmetric(insertion: .move(edge: .bottom), removal: .offset(x: 0, y: 1000))).eraseToAnyView()
            }

            return $0.transition(.slide).eraseToAnyView()
        }, content: {
            if viewModel.showingActivityIndicator {
                VStack {
                    Spacer()
                    ActivityIndicator(isAnimating: $viewModel.showingActivityIndicator, style: .large)
                    Spacer()
                }.eraseToAnyView()
            } else if viewModel.isLoggedIn {
                viewModel.mainView().eraseToAnyView()
            } else {
                AuthenticationAreaView(viewModel: viewModel.authenticationAreaViewModel)
            }
        })
        .alert(isPresented: $viewModel.showingAlert) {
            if viewModel.errorMessage != nil {
                return Alert(title: Text("Error"), message: Text(self.viewModel.errorMessage ?? ""), dismissButton: Alert.Button.cancel(Text("OK")) {
                    self.viewModel.errorMessage = nil
                })
            } else if let alert = viewModel.alert {
                return alert
            } else {
                return Alert(title: Text("Error"), message: Text("An unknown error occurred"), dismissButton: Alert.Button.cancel(Text("OK")))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView(viewModel: RootViewModel())
    }
}
