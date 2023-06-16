//
//  SettingsView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct SettingsView: View {
    @State private var syncWithBGMTV = isBGMTVlogined()
    var body: some View {
        VStack{
            HStack{
                Text("Settings")
                    .font(.largeTitle).bold()
                    .padding(10)
                Spacer()
            }
            
            List{
                //TODO: bgm.tv login
                Section(header: Text("Bgm.tv") ) {
#if os(tvOS)
                    Text("Bgm.tv setting on tvOS is not supported. You can use iOS or macOS device to setup and will do sync with bgm.tv on tvOS.")
#endif
                    Toggle("Sync status with bgm.tv", isOn: $syncWithBGMTV)
#if os(tvOS)
                        .disabled(true)
#endif
                        .onChange(of: syncWithBGMTV) { value in
                            if value {
                                loginBGMServer { result, data in
                                    syncWithBGMTV = result
                                    if result {
                                        print("success login to bgmtv")
                                    }else{
                                        print("login to bgmtv failed")
                                    }
                                }
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
                        exit(0)
                    }, label: {
                        Text("Logout & Exit").foregroundColor(.red)
                    }).padding(10)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
