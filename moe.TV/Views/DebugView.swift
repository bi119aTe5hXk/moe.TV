//
//  DebugView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/12/30.
//

import SwiftUI

struct DebugView: View {
    
    @State private var iCloudEnabled = (FileManager.default.ubiquityIdentityToken != nil)
    @State private var syncWithBGMTV = isBGMTVlogined()
    @ObservedObject var debugVM:DebugViewModel
    
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
                        Text(getAlbireoServer())
                    }
                }
                Section(header: Text("BGM.TV") ) {
                    Toggle("BGM.TV Logined", isOn:$syncWithBGMTV )
                        .disabled(true)
                    HStack{
                        Text("AccessToken")
                        Spacer()
                        Text(debugVM.getBGMTVAccessToken())
                    }
                    HStack{
                        Text("RefreshToken")
                        Spacer()
                        Text(debugVM.getBGMTVRefreshToken())
                    }
                    HStack{
                        Text("ExpireTime")
                        Spacer()
                        Text("\(debugVM.getBGMExpireTime())")
                    }
                    Button {
                        debugVM.reSyncBGM()
                    } label: {
                        Text("Re-Sync with iCloud")
                    }

                }
            }
        }
    }
}
