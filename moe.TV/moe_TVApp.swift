//
//  moe_TVApp.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/09.
//

import SwiftUI

@main
struct moe_TVApp: App {
    @State var showBGMDetailView:Bool = false
    @State var bgmID:String?
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: LoginViewModel())
                .sheet(isPresented: $showBGMDetailView, content: {
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
                    BangumiDetailView(bgmID:$bgmID)
                })
#if !os(tvOS)
                .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
#endif
                .onOpenURL { url in
                    if let queryUrlComponents = URLComponents(string: url.absoluteString){
                        switch url.host{
                        case "detail":
                            if let i = queryUrlComponents.queryItems?.first(where: { $0.name == "id" })?.value{
                                print(i)
                                self.bgmID = i
                                self.showBGMDetailView.toggle()
                            }
                            break
                            default:
                            print("not vaild host")
                        }
                    }
                }
        }
#if !os(tvOS)
        .handlesExternalEvents(matching: [])
#endif
    }
    
    
}
