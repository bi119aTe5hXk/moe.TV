//
//  ContentView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/09.
//

import SwiftUI


struct MainView: View {
    @ObservedObject var viewModel: LoginViewModel
    var body: some View {
        
        MyBangumiView()
            .onAppear(perform: {
                viewModel.presentLoginView = !loadCookies()
            })
            .sheet(isPresented: $viewModel.presentLoginView, content: {
                LoginView(viewModel: viewModel)
            })
        }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: LoginViewModel())
    }
}
