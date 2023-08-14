//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct MyBangumiView: View {
    @State var selectedItem: MyBangumiItemModel?
    @State var profileIconURL:String?
    
    @ObservedObject var settingsVM = SettingsViewModel()
    
    var body: some View {
        
        NavigationSplitView {
            BangumiListView(selectedItem: $selectedItem)
                
                .navigationTitle("My Bangumi")
                .toolbar(content: {
#if os(macOS)
                    Spacer()
#endif
                    Button(action: {
                        settingsVM.showSettingView()
                    }, label: {
                        SettingsButtonView(profileIconURL: $profileIconURL)
                    })
                })
            
        } detail: {
            BangumiDetailView(selectedItem: $selectedItem)
        }
        
        .onAppear(){
            //check bgm.tv login status
            if isBGMTVlogined(){
                if (profileIconURL ?? "").isEmpty{
                    fetchBGMProfileIcon()
                }
            }
        }
        
        .sheet(isPresented: $settingsVM.presentSettingView, content: {
            HStack{
#if !os(tvOS)
                Button(action: {
                    settingsVM.dismissSettingView()
                }, label: {
                    Text("Close")
                }).padding(20)
                Spacer()
#endif
            }
            SettingsView(settingsVM: settingsVM)
#if os(macOS)
        .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
            Spacer()
        })
    }
    
    
    func fetchBGMProfileIcon(){
        if isBGMTVlogined(){
            getBGMTVUserInfo(completion: { result, data in
                if result{
                    if let d = data as? BGMTVUserInfoModel{
                        let url = d.avatar?.large ?? ""
                        if !url.isEmpty{
//                            print("set profile icon url:\(url)")
                            self.profileIconURL = url
                        }else{
                            print("profile icon url is empty")
                        }
                    }else{
                        print("bgm.tv user info invalid, should delete bgm.tv user info")
                        logoutBGMTV()
                    }
                }else{
                    print("bgm.tv oauth info invalid")
                    //logoutBGMTV()
                }
            })
        }
    }
}

//struct MyBangumiView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyBangumiView(myBGMList: <#T##[MyBangumiItemModel]#>, myBangumiVM: <#T##MyBangumiViewModel#>)
//    }
//}
