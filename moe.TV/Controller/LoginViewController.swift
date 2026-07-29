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
	@Published var albireoV2APIServer = albireoV2DefaultAPIServerURL
    
    @Published var isValidServer = false
    @Published var isValidUsername = false
    @Published var isValidPassword = false
	@Published var isValidAlbireoV2APIServer = true
	@Published var isAlbireoV2ClientConfigured = !albireoV2ClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

	func loginWithAlbireoV2() {
		#if os(tvOS)
		toggleErrorView(msg: "box.moe login is not available on tvOS. Please log in on another device and enable iCloud sync.")
		return
		#else
		guard isAlbireoV2ClientConfigured else {
			toggleErrorView(msg: "Albireo V2 client id is empty.")
			return
		}
		guard isValidAlbireoV2APIServer else {
			toggleErrorView(msg: "Albireo V2 API server URL is invalid.")
			return
		}
		guard saveAlbireoV2OAuthSettings() else {
			toggleErrorView(msg: "Albireo V2 API server URL is invalid.")
			return
		}
		startAlbireoV2Login { result, message in
			if result {
				getAlbireoV2UserInfo { accountResult, accountData in
					DispatchQueue.main.async {
						if accountResult {
							self.isLoginSuccessd = true
							if let data = accountData as? Data,
							   let text = String(data: data, encoding: .utf8) {
								print("Albireo V2 user info: \(text)")
							}
						} else {
							self.toggleErrorView(msg: "\(message)\n\(accountData)")
						}
					}
				}
			} else {
				DispatchQueue.main.async {
					self.toggleErrorView(msg: message)
				}
			}
		}
		#endif
	}

	@discardableResult
	private func saveAlbireoV2OAuthSettings() -> Bool {
		guard let normalizedURL = validatedHTTPServerURL(albireoV2APIServer) else {
			return false
		}
		albireoV2APIServer = normalizedURL
		let settingsHandler = SettingsHandler()
		settingsHandler.registerSettings()
		settingsHandler.setAlbireoV2APIServerURL(normalizedURL)
		return true
	}
    
    init(){
		let settingsHandler = SettingsHandler()
		settingsHandler.registerSettings()
		if let Aserver = getAlbireoServer(){
			self.server = Aserver
		}
		let savedAlbireoV2APIServer = settingsHandler.getAlbireoV2APIServerURL()
		self.albireoV2APIServer = savedAlbireoV2APIServer.isEmpty ? albireoV2DefaultAPIServerURL : savedAlbireoV2APIServer
		self.isValidAlbireoV2APIServer = isValidHTTPServerURL(self.albireoV2APIServer)
		self.isAlbireoV2ClientConfigured = !albireoV2ClientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        $server.sink(receiveValue: {
            self.isValidServer = isValidHTTPServerURL($0)
        }).store(in: &disposables)

		$albireoV2APIServer.sink(receiveValue: {
			self.isValidAlbireoV2APIServer = isValidHTTPServerURL($0)
		}).store(in: &disposables)
        
        $username.sink(receiveValue: {
            self.isValidUsername = !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        $password.sink(receiveValue: {
            self.isValidPassword = !$0.isEmpty ? true : false
        }).store(in: &disposables)
        
        
        
        $isLoginButtonTapped.sink(receiveValue: { isTapped in
                        if isTapped == true {
							guard let normalizedServerURL = validatedHTTPServerURL(self.server) else {
								self.toggleErrorView(msg: "Server URL or Username / Password error.")
								self.isLoginButtonTapped = false
								return
							}
							self.server = normalizedServerURL
                            loginAlbireoServer(server: normalizedServerURL,
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
