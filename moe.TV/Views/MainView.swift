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
    
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var showNetworkAlert = false
    @State private var showDownloadList = false
    
    var body: some View {
        if networkMonitor.isConnected {
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
        
        }else{
            VStack{
                Spacer()
                Text("No Internet").font(.title)
                    .padding(10)
                Image(systemName: "wifi.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .padding(10)
                Text("Online service is not available.")
                    .padding(10)
                
                Button(action: {
                    self.showDownloadList.toggle()
                }, label: {
                    Text("Show download list")
                })
                .padding(10)
                .sheet(isPresented: self.$showDownloadList, content: {
                    DownloadListView()
                })
                
                Spacer()
            }
        }
        
    }
}


//struct MainView_Previews: PreviewProvider {
//    static var previews: some View {
//        MainView(viewModel: LoginViewModel())
//    }
//}
