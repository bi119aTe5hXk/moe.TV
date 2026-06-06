//
//  MyBangumiView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

private struct DownloadedVideoPlaybackItem: Identifiable {
    let id = UUID()
    let url: URL
    let filename: String
    let position: Double
}

struct MainListView: View {
	@State var selectedItem: BangumiItemModel?
    @State var destination:FuncViewModel?
	
	//for tvOS
	@Binding var selectedFunc: FuncViewModel?
	@State private var presentedItem: BangumiItemModel?

//    @ObservedObject var settingsVM = SettingsViewModel()
    @State var presentSettingView = false
	@State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var downloadedVideoPlaybackItem: DownloadedVideoPlaybackItem?
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
			SidebarView(selectedDestination: guardedDestination)
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
                BangumiListView(selectedItem: guardedSelectedItem, selectedFunc: guardedDestination, loginVC: loginVC)
                    .navigationTitle(dest.localizedName)
            }
        } detail: {
			BangumiDetailView(selectedItem: guardedSelectedItem)
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
			SettingsView(settingsVC: SettingsViewController(), loginVC: loginVC) { url, filename, position in
                presentSettingView = false
                DispatchQueue.main.async {
                    downloadedVideoPlaybackItem = DownloadedVideoPlaybackItem(
                        url: url,
                        filename: filename,
                        position: position ?? 0
                    )
                }
            }
#if os(macOS)
				.frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
			Spacer()
		})
#if os(iOS)
        .fullScreenCover(item: $downloadedVideoPlaybackItem) { item in
            downloadedVideoPlayerView(item)
        }
#endif
#if os(macOS)
        .sheet(item: $downloadedVideoPlaybackItem) { item in
            downloadedVideoPlayerView(item)
#if os(macOS)
                .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
#endif
        }
#endif
#endif


//#if !os(tvOS)
//			if horizontalSizeClass == .regular {
//				let _ = {columnVisibility = .automatic}
//			}
//#endif


    }

#if !os(tvOS)
    private var guardedDestination: Binding<FuncViewModel?> {
        Binding(
            get: {
                destination
            },
            set: { newValue in
                guard !PlayerPresentationState.shared.isPlayerPresented else { return }
                destination = newValue
            }
        )
    }

    private var guardedSelectedItem: Binding<BangumiItemModel?> {
        Binding(
            get: {
                selectedItem
            },
            set: { newValue in
                guard !PlayerPresentationState.shared.isPlayerPresented else { return }
                selectedItem = newValue
            }
        )
    }

    @ViewBuilder
    private func downloadedVideoPlayerView(_ item: DownloadedVideoPlaybackItem) -> some View {
        ZStack(alignment: .topLeading) {
            VideoPlayerView(url: item.url,
                            seekTime: item.position,
                            bgmItem: .constant(nil),
                            ep: nil,
                            isOffline: true,
                            filename: item.filename,
                            isBGMTVWatched: false)
            Button(action: {
                downloadedVideoPlaybackItem = nil
            }, label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            })
            .buttonStyle(.plain)
            .padding(20)
		}
		.background(.black)
    }
#endif

    
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
