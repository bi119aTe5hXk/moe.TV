//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct MyBangumiView: View {
    @ObservedObject var myBangumiVM: MyBangumiViewModel
    @State var selectedItem: MyBangumiItemModel?
    @State var profileIconURL:String?
    
    var body: some View {
        NavigationSplitView {
            BangumiListView(listVM: BangumiListViewModel(),selectedItem: $selectedItem)
                
                .navigationTitle("My Bangumi")
                .toolbar(content: {
#if os(macOS)
                    Spacer()
#endif
                    Button(action: {
                        myBangumiVM.toggleSettingView()
                    }, label: {
                        SettingsButtonView(profileIconURL: $profileIconURL)
                    })
                })
            
        } detail: {
            BangumiDetailView(selectedItem: $selectedItem)
        }
        .onAppear(){
            if isBGMTVlogined(){
                if (profileIconURL ?? "").isEmpty{
                    fetchBGMProfileIcon()
                }
            }
        }
        
        .sheet(isPresented: $myBangumiVM.presentSettingView, content: {
            HStack{
#if !os(tvOS)
                Button(action: {
                    myBangumiVM.toggleSettingView()
                }, label: {
                    Text("Close")
                }).padding(20)
                Spacer()
#endif
            }
            SettingsView(loginVM: LoginViewModel(),
                         myBangumiVM: myBangumiVM,
                         settingsVM: SettingsViewModel())
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
