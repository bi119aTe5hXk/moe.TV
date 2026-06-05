//
//  LoginViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/12.
//

import Foundation
import Combine
import AuthenticationServices

class LoginViewController: ObservableObject {
    @Published var server = ""
    @Published var username = ""
    @Published var password = ""
    
    @Published var isValidServer = false
    @Published var isValidUsername = false
    @Published var isValidPassword = false
    @Published var isLoginButtonTapped = false
    @Published var showError = false
	@Published var errorMessage = "Server URL or Username / Password error."
    @Published var presentLoginView = false
    
    @Published var isLoginSuccessd = false
    
    private var disposables = [AnyCancellable]()
    
    func showLoginView(){
        print("showLoginView")
        self.presentLoginView = true
    }
    
    func dismissLoginView(){
//        DispatchQueue.main.async {
            print("dismiss login view")
        self.presentLoginView = false
//        }
    }
    func toggleErrorView(msg: String?){
		if let msg = msg {
			self.errorMessage = msg
		}
        self.showError = true
    }
    
    func logout() {
        logoutAlbireoServer { _, _ in
            DispatchQueue.main.async {
                self.username = ""
                self.password = ""
                self.isLoginButtonTapped = false
                self.showError = false
                self.isLoginSuccessd = false
            }
        }
    }
    
    init(){
		if let Aserver = getAlbireoServer(){
			self.server = Aserver
		}
        $server.sink(receiveValue: {
            self.isValidServer = $0.isValidURL && !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        $username.sink(receiveValue: {
            self.isValidUsername = !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        $password.sink(receiveValue: {
            self.isValidPassword = !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        
        
        $isLoginButtonTapped.sink(receiveValue: { isTapped in
                        if isTapped == true {
                            loginAlbireoServer(server:self.server,
                                      username: self.username,
                                      password: self.password)
                            { result, data in
                                if result {
                                    //self.dismissLoginView()
                                    DispatchQueue.main.async {
                                        self.isLoginSuccessd = true
                                    }
                                    print("logined")
                                }else{
									self.toggleErrorView(msg: data)
                                    print("login error")
                                }
                            }
                        }
                    })
                    .store(in: &disposables)
    }
}
