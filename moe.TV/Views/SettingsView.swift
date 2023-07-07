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
    @ObservedObject var settingsVM: SettingsViewModel
    
    var body: some View {
        VStack{
            HStack{
                Text("Settings")
                    .font(.largeTitle).bold()
                    .padding(10)
                Spacer()
            }
            
            List{
                //TODO: BGMTV profile name/icon etc.
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
                                if !isBGMTVlogined(){
                                    startBGMTVLogin()
                                }
                            }else{
                                settingsVM.showLogoutBGMTVAlert()
                            }
                        }
                        .alert(isPresented: $settingsVM.presentLogoutBGMTVAlert) {
                            Alert(
                                title: Text("Are you sure you want to logout from bgm.tv?"),
                                primaryButton: .destructive(Text("Logout")) {
                                    syncWithBGMTV = false
                                    logoutBGMTV()
                                },
                                secondaryButton: .cancel(){
                                    syncWithBGMTV = true
                                }
                            )
                        }
                    
                }
                
                Section(header: Text("Sign out")) {
                    Button(action: {
                        settingsVM.showLogoutAlbireoAlert()
                    }, label: {
                        Text("Logout & Exit").foregroundColor(.red)
                    }).padding(10)
                    
                        .alert(isPresented: $settingsVM.presentLogoutAlbireoAlert) {
                            Alert(
                                title: Text("Are you sure you want to logout and exit app?"),
                                            primaryButton: .destructive(Text("Logout")) {
                                                logOutServer { result, data in
                                                    
                                                }
                                                myBangumiVM.myBGMList = []
                                                //loginVM.toggleLoginView() //TODO: show login view after logout
                                                myBangumiVM.toggleSettingView()
                                                exit(0) //TODO: logout without exit
                                            },
                                            secondaryButton: .cancel()
                                )
                        }
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
