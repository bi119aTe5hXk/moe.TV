//
//  LoginView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct LoginView: View {
	@ObservedObject var loginVC = LoginViewController()
    var body: some View {
        if loadAlbireoCookies() || loginVC.isLoginSuccessd{
            MainListView()
        }else{
            HStack{
                Spacer()
                    
                VStack{
                    Spacer()
                    Text("Connect to Albireo Services")
                        .lineLimit(2)
                        .fontWeight(.bold)
                        .font(.title)
                        .padding(50)
                    
                    Spacer()
                    
                    TextField("Server URL", text: $loginVC.server)
                        .padding(10)
                    TextField("Username", text: $loginVC.username)
                        .padding(10)
                    SecureField("Password", text: $loginVC.password)
                        .padding(10)
						.onSubmit {
							loginVC.isLoginButtonTapped = true
						}
                    Spacer()
                    Button(action: {
                        loginVC.isLoginButtonTapped = true
                        
                    }, label: {
                        Text("Login")
                            .foregroundColor(.white)
                    })
                    .padding(10)
                    .background(loginVC.isValidUsername && loginVC.isValidPassword && loginVC.isValidServer ? Color.blue : Color.gray)
                    .cornerRadius(10, antialiased: true)
                    .disabled(!loginVC.isValidUsername || !loginVC.isValidPassword || !loginVC.isValidServer)
					
					.alert(
						loginVC.errorMessage,
						isPresented: $loginVC.showError
					) {
                        Button("OK", role: .cancel) { }
                    }
                    Spacer()
                    
                    OfflineView().padding(10)
                }
                Spacer()
            }
        }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView(viewModel: LoginViewModel())
//    }
//}
