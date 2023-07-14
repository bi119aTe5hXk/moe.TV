//
//  ContentView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/09.
//

import SwiftUI


struct MainView: View {
    @ObservedObject var loginVM: LoginViewModel
    @ObservedObject var myBangumiVM: MyBangumiViewModel
    var body: some View {
        
        MyBangumiView(myBangumiVM: MyBangumiViewModel())
            .onAppear(perform: {
                if loadAlbireoCookies(){
                    isAlbireoLoginValid { result in
                        if !result{
                            loginVM.showLoginView()
                        }
                    }
                }else{
                    loginVM.showLoginView()
                }
                
                
            })
            .sheet(isPresented: $loginVM.presentLoginView, content: {
                LoginView(loginVM: loginVM)
            })
        }
}


//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView(viewModel: LoginViewModel())
//    }
//}
