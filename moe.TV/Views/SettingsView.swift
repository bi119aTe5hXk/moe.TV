//
//  SettingsView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct SettingsView: View {
    @State private var syncWithBGMTV = isBGMTVlogined()
    
    @ObservedObject var loginVM: LoginViewModel
    @ObservedObject var myBangumiVM: MyBangumiViewModel
    
    var body: some View {
        VStack{
            HStack{
                Text("Settings")
                    .font(.largeTitle).bold()
                    .padding(10)
                Spacer()
            }
            
            List{
                Section(header: Text("Bgm.tv") ) {
#if os(tvOS)
                    Text("Bgm.tv setting on tvOS is not supported. But you can use iOS or macOS device to setup and will do sync with bgm.tv on tvOS.")
#endif
                    Toggle("Sync status with bgm.tv", isOn: $syncWithBGMTV)
#if os(tvOS)
                        .disabled(true)
#endif
                        .onChange(of: syncWithBGMTV) { value in
                            if value {
                                startBGMTVLogin()
                            }else{
                                syncWithBGMTV = false
                                logoutBGMTV()
                            }
                        }
                    
                }
                
                Section(header: Text("Sign out")) {
                    Button(action: {
                        logOutServer { result, data in
                            
                        }
                        myBangumiVM.myBGMList = []
                        //loginVM.toggleLoginView() //TODO: show login view after logout
                        myBangumiVM.toggleSettingView()
                        exit(0) //TODO: logout without exit
                    }, label: {
                        Text("Logout & Exit").foregroundColor(.red)
                    }).padding(10)
                }
            }
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView(loginViewModel: LoginViewModel())
//    }
//}
