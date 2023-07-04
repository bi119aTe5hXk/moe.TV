//
//  ContentView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/09.
//

import SwiftUI


struct MainView: View {
    @ObservedObject var loginVM: LoginViewModel
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
                
                if isBGMTVlogined(){
                    getBGMTVUserInfo { result, _ in
                        if !result{
                            print("bgm.tv oauth info invalid, cleaning...")
                            logoutBGMTV()
                        }
                    }
                }
                
            })
            .sheet(isPresented: $loginVM.presentLoginView, content: {
                LoginView(viewModel: loginVM)
            })
        }
}


//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView(viewModel: LoginViewModel())
//    }
//}
