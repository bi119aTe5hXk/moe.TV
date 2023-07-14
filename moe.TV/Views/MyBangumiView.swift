//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct MyBangumiView: View {
    @ObservedObject var myBangumiVM: MyBangumiViewModel
    @State private var selectedItem:MyBangumiItemModel? = nil
    
    var body: some View {
        NavigationView {
            let _ = {
                if myBangumiVM.myBGMList.count <= 0{
                    print("init.getBGMList")
                    Task.init(operation: {
                        await getBGMList()
                    })
                }
                if isBGMTVlogined() && myBangumiVM.getBGMProfileIcon().isEmpty{
                    fetchBGMProfileIcon()
                }
            }()
            BangumiListView(animeArr: $myBangumiVM.myBGMList)
                .refreshable {
                    myBangumiVM.myBGMList = []
                    print("pulled")
                    await getBGMList()
                }
                .navigationTitle("My Bangumi")
                .toolbar(content: {
                    Spacer()
                    Button(action: {
                        myBangumiVM.toggleSettingView()
                    }, label: {
                        if isBGMTVlogined(){
                            AsyncImage(url: URL(string: myBangumiVM.getBGMProfileIcon())) { image in
                                image.resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                            }
                        }else{
                            Image(systemName: "gear")
                        }
                    })
                })
            BangumiDetailView(bgmID: .constant(selectedItem?.id))
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
    func getBGMList() async {
        getMyBangumiList { result, data in
            if !result{
                //TODO: login failed, cookie expired
                return
            }
            if let bgmList = data as? [MyBangumiItemModel]{
                myBangumiVM.setBGMList(list: bgmList)
#if os(tvOS)
            let save = SaveHandler()
            save.setTopShelf(array: myBangumiVM.getBGMList())
#endif
            }
        }
    }
    
    func fetchBGMProfileIcon(){
        if isBGMTVlogined(){
            getBGMTVUserInfo(refreshToken: true, completion: { result, data in
                if result{
                    if let d = data as? BGMTVUserInfoModel{
                        let url = d.avatar?.large ?? ""
                        myBangumiVM.setBGMProfileIcon(url: url)
                    }
                }else{
                    print("bgm.tv oauth info invalid, cleaning...")
                    logoutBGMTV()
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
