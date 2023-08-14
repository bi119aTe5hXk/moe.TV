//
//  SettingsView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct SettingsView: View {
    @State private var syncWithBGMTV = isBGMTVlogined()
    @State private var showDownloadList = false
    
//    @Binding var listVM:BangumiListViewModel
//    @Binding var loginVM:LoginViewModel
//    @Binding var myBGMVM:MyBangumiViewModel
    @ObservedObject var settingsVM:SettingsViewModel
    
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
                        .onAppear(){
                            if syncWithBGMTV{
                                getBGMUserInfo()
                            }
                        }
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
                    if settingsVM.isBGMUserInfoReady{
                        HStack{
                            VStack{
                                HStack{
                                    Text("Nickname: \(settingsVM.bgmNickname)")
                                    Spacer()
                                }
                                HStack{
                                    Text("Username: \(settingsVM.bgmUsername)")
                                    Spacer()
                                }
                                HStack{
                                    Text("ID: \(String(settingsVM.bgmID))")
                                    Spacer()
                                }
                                
                            }
                            Spacer()
                            AsyncImage(url: URL(string: settingsVM.avatar_url)) { image in
                                image.resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        HStack{
                            Text("Sign: \(settingsVM.bgmSign)")
                            Spacer()
                        }
                    }
                    
                }
                
                Section(header: Text("Download")) {
                    Button {
                        self.showDownloadList.toggle()
                    } label: {
                        Text("Open download manager")
                    }
                    .sheet(isPresented: self.$showDownloadList, content: {
                        HStack{
#if !os(tvOS)
                            Button(action: {
                                self.showDownloadList.toggle()
                            }, label: {
                                Text("Close")
                            }).padding(20)
                            Spacer()
#endif
                        }
                        DownloadListView( dlListVM: DownloadListViewModel())
                            .environmentObject(DownloadManager())
                            .environmentObject(OfflinePlaybackManager())
                    })
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
                                    logoutAlbireoServer { result, data in

                                    }
                                    //listVM.myBGMList = []
//                                    loginVM.presentLoginView = true //TODO: show login view after logout
//                                    loginVM.isLoginSuccessd = false
                                    //myBangumiVM.toggleSettingView()
                                    exit(0) //TODO: logout without exit
                                },
                                secondaryButton: .cancel()
                            )
                        }
                }
            }
        }
    }
    
    
    func getBGMUserInfo() {
        print("getBGMUserInfo")
        getBGMTVUserInfo(completion: { result, data in
            if result{
                if let d = data as? BGMTVUserInfoModel{
                    settingsVM.setBGMInfo(avatar_url: d.avatar?.large ?? "",
                                          bgmUsername: d.username ?? "",
                                          bgmNickname: d.nickname ?? "",
                                          bgmID: d.id ?? 0,
                                          bgmSign: d.sign ?? "")
                    settingsVM.showBGMUserInfo()
                }
            }else{
                print("bgm.tv oauth info invalid")
            }
        })
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView(loginViewModel: LoginViewModel())
//    }
//}
