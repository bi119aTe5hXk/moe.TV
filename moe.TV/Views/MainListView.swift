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
	
	//for tvOS
	@Binding var selectedFunc: FuncViewModel?
	@State private var presentedItem: BangumiItemModel?

//    @ObservedObject var settingsVM = SettingsViewModel()
    @State var presentSettingView = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
	@ObservedObject var loginVC: LoginViewController
	

    var body: some View {
        

#if os(tvOS)
		HStack(spacing: 0) {
			TVSidebar(selectedFunc: $selectedFunc, loginVC: loginVC)
				.frame(width: 320)

			BangumiListView(
				selectedItem: $selectedItem,
				selectedFunc: .constant(selectedFunc),
				loginVC: loginVC
			)
//			.id(selectedFunc)
		}
		.onChange(of: selectedItem) { _, newValue in
			if let item = newValue {
				presentedItem = item
			}
		}
		.fullScreenCover(item: $presentedItem, onDismiss: {
			presentedItem = nil
		}) { item in
			NavigationStack{
				BangumiDetailView(selectedItem: .constant(item))
					.background(.thinMaterial)
			}
		}

#else
		NavigationSplitView(columnVisibility: $columnVisibility) {
				//for iOS/macOS/visionOS
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
		} content: {
            if let dest = destination {
                BangumiListView(selectedItem: $selectedItem, selectedFunc: $destination, loginVC: loginVC)
                    .navigationTitle(dest.localizedName)
            }
        } detail: {
			BangumiDetailView(selectedItem: $selectedItem)
        }
		.navigationSplitViewStyle(.automatic)
		.sheet(isPresented: self.$presentSettingView, content: {
			HStack{
				Button(action: {
					self.presentSettingView.toggle()
				}, label: {
					Text("Close")
				}).padding(20)
				Spacer()
			}
			SettingsView(settingsVC: SettingsViewController(), loginVC: loginVC)
#if os(macOS)
				.frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
			Spacer()
		})
#endif


//#if !os(tvOS)
//			if horizontalSizeClass == .regular {
//				let _ = {columnVisibility = .automatic}
//			}
//#endif


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
