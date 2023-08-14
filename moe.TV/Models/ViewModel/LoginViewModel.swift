//
//  LoginViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/12.
//

import Foundation
import Combine
import AuthenticationServices

class LoginViewModel: ObservableObject {
    @Published var server = ""
    @Published var username = ""
    @Published var password = ""
    
    @Published var isValidServer = false
    @Published var isValidUsername = false
    @Published var isValidPassword = false
    @Published var isLoginButtonTapped = false
    @Published var showError = false
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
    func toggleErrorView(){
        self.showError = true
    }
    
    init(){
        self.server = getAlbireoServer()
        
        $server.sink(receiveValue: {
            self.isValidServer = $0.isValidURL && !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        $username.sink(receiveValue: {
            self.isValidUsername = $0.isAlphanumeric && !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        $password.sink(receiveValue: {
            self.isValidPassword = $0.isAlphanumeric && !$0.isEmpty ? true : false
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
                                    self.toggleErrorView()
                                    print("login error")
                                }
                            }
                        }
                    })
                    .store(in: &disposables)
    }
}

extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
