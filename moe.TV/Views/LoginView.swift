//
//  LoginView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    
    var body: some View {
        VStack{
            Spacer()
            Text("Login to Albireo Server")
                .fontWeight(.bold)
                .font(.title)
                .padding(50)
            Spacer()
            TextField("Server URL", text: $viewModel.server)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(10)
            Spacer()
            Button(action: {
                viewModel.isLoginButtonTapped = true
            }, label: {
                Text("Login")
                    .foregroundColor(.white)
            })
            .buttonStyle(.borderless)
            .padding(10)
            .background(viewModel.isValidUsername && viewModel.isValidPassword && viewModel.isValidServer ? Color.blue : Color.gray)
                        .cornerRadius(10, antialiased: true)
                        .disabled(!viewModel.isValidUsername || !viewModel.isValidPassword || !viewModel.isValidServer)
                        .alert("Server URL or Username / Password error.", isPresented: $viewModel.showError) {
                                    Button("OK", role: .cancel) { }
                                }
            Spacer()
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel())
    }
}
