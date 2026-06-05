//
//  moe_TVApp.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/09.
//

import SwiftUI

@main
struct moe_TVApp: App {
#if os(iOS)
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
//    @State var showBGMDetailView:Bool = false
//    @State var bgmID:String?
    @StateObject var networkMonitor = NetworkMonitor()
	@StateObject var downloadManager = DownloadManager()
//	@State var selectedItem: BangumiItemModel?
	@State private var navigationPath: [String] = []


    var body: some Scene {
        WindowGroup {
#if os(tvOS)
			NavigationStack(path: $navigationPath) {
				MainView()
					.navigationDestination(for: String.self) { bgmID in
						BangumiDetailView(
							selectedItem: .constant(BangumiItemModel(id: bgmID, type: 0, status: 0, eps: 0)),
							detailVC: BangumiDetailViewController()
						)
					}
			}

			.onChange(of: navigationPath, initial: true, perform: { newValue in
				for element in navigationPath {
					print("element:", type(of: element), element)
				}
			})
			.environmentObject(networkMonitor)
			.environmentObject(downloadManager)
#else
			MainView()
				.environmentObject(networkMonitor)
				.environmentObject(downloadManager)
				.handlesExternalEvents(preferring: ["*"], allowing: ["*"])
#endif

                //for URI scheme
//#if os(tvOS)
//				.fullScreenCover(
//					isPresented: $showBGMDetailView,
//					content: {
//
//
//
//						if let id = bgmID{
//							BangumiDetailView(
//								selectedItem:
//										.constant(
//											BangumiItemModel(id: id, type: 0, status: 0, eps: 0)
//										),
//								detailVC: BangumiDetailViewController()
//							)
//							.background().edgesIgnoringSafeArea(.all)
//						}
//					})
//#endif
//#if !os(tvOS)
//                .sheet(
//					isPresented: $showBGMDetailView,
//					content: {
//
//                    HStack{
//                        Button(action: {
//                            self.showBGMDetailView.toggle()
//                        }, label: {
//                            Text("Close")
//                        }).padding(20)
//                        Spacer()
//                    }
//
//						if let id = bgmID{
//							BangumiDetailView(
//								selectedItem:
//										.constant(
//											BangumiItemModel(id: id, type: 0, status: 0, eps: 0)
//										),
//								detailVC: BangumiDetailViewController()
//							)
//                    }
//                })
//#endif


			Spacer()
                .onOpenURL { url in
                    print(url.absoluteURL)
                    if let queryUrlComponents = URLComponents(string: url.absoluteString){
                        switch url.host{
                        case "detail":
                            if let i = queryUrlComponents.queryItems?.first(where: { $0.name == "id" })?.value{
                                print(i)
//                                self.bgmID = i
//                                self.showBGMDetailView.toggle()
								self.navigationPath = [i]
                            }
                            break
                        case "bgmtv":
                            if let code = queryUrlComponents.queryItems?.first(where: { $0.name == "code" })?.value{
                                print(code)
								getBGMTVAccessToken(code: code){ isSuccess, result in
									if isSuccess{
										NotificationCenter.default
											.post(name: Notification.Name("getBGMUserInfo"), object: nil)
									}else{
										print("getBGMTVAccessToken failed: \(result)")
									}
								}
                            }
                            break
                            default:
                            print("unknown host")
                        }
                    }
                }
        }
#if !os(tvOS)
        .handlesExternalEvents(matching: [])
#endif
    }
    
    
}
