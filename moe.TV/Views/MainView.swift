//
//  ContentView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/09.
//

import SwiftUI


struct MainView: View {
    @ObservedObject var loginVM = LoginViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    
    var body: some View {
        if networkMonitor.isConnected {
        LoginView()
        
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
                
                OfflineView()
                
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
