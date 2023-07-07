//
//  LoginView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var loginVM: LoginViewModel
    
    var body: some View {
        VStack{
            Spacer()
            Text("Login to Albireo Server")
                .fontWeight(.bold)
                .font(.title)
                .padding(50)
            Spacer()
            TextField("Server URL", text: $loginVM.server)
                .padding(10)
            TextField("Username", text: $loginVM.username)
                .padding(10)
            SecureField("Password", text: $loginVM.password)
                .padding(10)
            Spacer()
            Button(action: {
                loginVM.isLoginButtonTapped = true
            }, label: {
                Text("Login")
                    .foregroundColor(.white)
            })
            .padding(10)
            .background(loginVM.isValidUsername && loginVM.isValidPassword && loginVM.isValidServer ? Color.blue : Color.gray)
                        .cornerRadius(10, antialiased: true)
                        .disabled(!loginVM.isValidUsername || !loginVM.isValidPassword || !loginVM.isValidServer)
                        .alert("Server URL or Username / Password error.", isPresented: $loginVM.showError) {
                                    Button("OK", role: .cancel) { }
                                }
            Spacer()
        }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView(viewModel: LoginViewModel())
//    }
//}
