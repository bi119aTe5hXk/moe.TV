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
    @Published var server:String = ""
    @Published var username:String = ""
    @Published var password:String = ""
    
    //TODO: HTTP proxy support
    
    @Published var isValidServer: Bool = false
    @Published var isValidUsername: Bool = false
    @Published var isValidPassword: Bool = false
    @Published var isLoginButtonTapped: Bool = false
    @Published var showError: Bool = false
    @Published var presentLoginView: Bool = false
    
    private var disposables = [AnyCancellable]()
    
    
    init(){
        self.server = initNetwork()
        
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
                            loginServer(server:self.server,
                                                      username: self.username,
                                                      password: self.password) { result, data in
                                if result {
                                    self.showError = false
                                    self.presentLoginView = false
                                    print("logined")
                                }else{
                                    self.showError = true
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
