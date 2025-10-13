//
//  DebugView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/12/30.
//

import SwiftUI
import SDWebImageSwiftUI
struct DebugView: View {
    @State private var iCloudEnabled = (FileManager.default.ubiquityIdentityToken != nil)
    @State private var syncWithBGMTV = isBGMTVlogined()
    @State private var albireoCookiesArray:Array<String> = []
    @ObservedObject var debugVC:DebugViewController

    var body: some View {
        VStack{
            HStack{
                Text("Debug")
                    .font(.largeTitle).bold()
                    .padding(10)
                Spacer()
            }
            List{
                Section(header: Text("iCloud") ) {
                    Toggle("iCloud Available", isOn:$iCloudEnabled )
                        .disabled(true)
                    
                }
                Section(header: Text("Albireo") ) {
                    HStack{
                        Text("Server URL")
                        Spacer()
                        Text(getAlbireoServer() ?? "")
                    }
                    ForEach(albireoCookiesArray, id: \.self) { string in
                        Text(string)
                    }
                }
                
                Section(header: Text("BGM.TV") ) {
                    Toggle("BGM.TV Logined", isOn:$syncWithBGMTV )
                        .disabled(true)
                    HStack{
                        Text("AccessToken")
                        Spacer()
						Text(debugVC.getBGMTVAccessTokenDEBUG())
                    }
                    HStack{
                        Text("RefreshToken")
                        Spacer()
						Text(debugVC.getBGMTVRefreshTokenDEBUG())
                    }
                    HStack{
                        Text("ExpireTime")
                        Spacer()
                        Text("\(debugVC.getBGMExpireTimeDEBUG())")
                    }
                    Button {
						refreshBGMTVToken(){ isSuccess, result in
							if isSuccess{
								print("refreshBGMTVToken success")
							}else{
								print("refreshBGMTVToken failed: \(result)")
							}
						}
                    } label: {
                        Text("Refresh BGM Access Token")
                    }
                    Button {
						debugVC.reSyncBGM()
                    } label: {
                        Text("Re-Sync with iCloud")
                    }
                }

				Section(header: Text("Functions")) {
					Button{
//						imageCache.removeCache()
						SDImageCache.shared.clear(with: .all, completion: {
							print("Image cache cleared")
						})
					}label: {
						Text("Clear image cache")
					}
				}
            }
        }
        .onAppear(){
            getAllCookies { arr in
                albireoCookiesArray = arr
            }
        }
    }
}
