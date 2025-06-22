//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct MainListView: View {
    @State var selectedItem: BangumiItemModel?
    @State var destination:FuncViewModel?
    
//    @ObservedObject var settingsVM = SettingsViewModel()
    @State var presentSettingView = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

//	@Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedDestination: $destination)
                .background(Color.clear)
#if os(macOS)
                .listStyle(SidebarListStyle())
#endif
                .toolbar(content: {
#if os(macOS)
                    Spacer()
#endif
                    Button(action: {
                        self.presentSettingView = true
                    }, label: {
                        SettingsButtonView()//(profileIconURL: settingsVM.avatar_url)
                    })
                })
                .navigationTitle("moe.TV")
//#if !os(tvOS)
//			if horizontalSizeClass == .regular {
//				let _ = {columnVisibility = .automatic}
//			}
//#endif
        } content: {
            if let dest = destination {
                BangumiListView(selectedItem: $selectedItem, selectedFunc: $destination)
                    .navigationTitle(dest.localizedName)
            }
        } detail: {
			BangumiDetailView(selectedItem: $selectedItem)
        }
#if !os(tvOS)
		.navigationSplitViewStyle(.automatic)
#endif
#if os(tvOS)
		.navigationSplitViewStyle(.balanced)
#endif

        .sheet(isPresented: self.$presentSettingView, content: {
            HStack{
#if !os(tvOS)
                Button(action: {
                    self.presentSettingView = false
                }, label: {
                    Text("Close")
                }).padding(20)
                Spacer()
#endif
            }
			SettingsView(settingsVC: SettingsViewController())
#if os(macOS)
        .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
            Spacer()
        })
        
        
    }
    
    
    
//    func fetchBGMProfileIcon(){
//        if isBGMTVlogined(){
//            getBGMTVUserInfo(completion: { result, data in
//                if result{
//                    if let d = data as? BGMTVUserInfoModel{
//                        let url = d.avatar?.large ?? ""
//                        if !url.isEmpty{
////                            print("set profile icon url:\(url)")
//                            settingsVM.avatar_url = url
//                        }else{
//                            print("profile icon url is empty")
//                        }
//                    }else{
//                        print("bgm.tv user info invalid, should delete bgm.tv user info")
//                        logoutBGMTV()
//                    }
//                }else{
//                    print("bgm.tv oauth info invalid")
//                    //logoutBGMTV()
//                }
//            })
//        }
//    }
}

//struct MyBangumiView_Previews: PreviewProvider {
//    static var previews: some View {
//        MyBangumiView(myBGMList: <#T##[MyBangumiItemModel]#>, myBangumiVM: <#T##MyBangumiViewModel#>)
//    }
//}
