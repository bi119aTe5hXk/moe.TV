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
    @State var showBGMDetailView:Bool = false
    @State var bgmID:String?
    @StateObject var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            MainView()
            
                //for URI scheme
                .sheet(
					isPresented: $showBGMDetailView,
					content: {
#if !os(tvOS)
                    HStack{
                        Button(action: {
                            self.showBGMDetailView.toggle()
                        }, label: {
                            Text("Close")
                        }).padding(20)
                        Spacer()
                    }
#endif
						if let id = bgmID{
							BangumiDetailView(
								selectedItem:
										.constant(
											BangumiItemModel(id: id, type: 0, status: 0, eps: 0)
										),
								detailVC: BangumiDetailViewController()
							)
                    }
                })
                .environmentObject(networkMonitor)
#if !os(tvOS)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
#endif
                .onOpenURL { url in
                    print(url.absoluteURL)
                    if let queryUrlComponents = URLComponents(string: url.absoluteString){
                        switch url.host{
                        case "detail":
                            if let i = queryUrlComponents.queryItems?.first(where: { $0.name == "id" })?.value{
                                print(i)
                                self.bgmID = i
                                self.showBGMDetailView.toggle()
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
