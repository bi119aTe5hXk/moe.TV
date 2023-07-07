//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI

struct MyBangumiView: View {
    @State private var selectedItem:MyBangumiItemModel? = nil
    
    @ObservedObject var myBangumiVM: MyBangumiViewModel
    
    
    var body: some View {
        NavigationView {
            let _ = {
                if myBangumiVM.myBGMList.count <= 0{
                    print("init.getBGMList")
                    getBGMList()
                }
            }()
            BangumiListView(animeArr: $myBangumiVM.myBGMList)
                .refreshable {
                    print("pulled")
                    getBGMList()
                }
                .navigationTitle("My Bangumi")
                .toolbar(content: {
                    Button(action: {
                        myBangumiVM.toggleSettingView()
                    }, label: {
                        Image(systemName: "gear")
                            
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
    func getBGMList() {
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
}


//struct MyBangumiView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyBangumiView(myBGMList: <#T##[MyBangumiItemModel]#>, myBangumiVM: <#T##MyBangumiViewModel#>)
//    }
//}
