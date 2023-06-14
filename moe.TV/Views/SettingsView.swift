//
//  SettingsView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct SettingsView: View {
    @State private var syncWithBGMTV = false
    var body: some View {
        VStack{
            HStack{
                Text("Settings")
                    .font(.largeTitle).bold()
                    .padding(10)
                Spacer()
            }
            
            List{
                //TODO: bgm.tv login
                Section(header: Text("bgm.tv")) {
                    Toggle("Sync play status with bgm.tv", isOn: $syncWithBGMTV).disabled(true)
                }
                Section(header: Text("Sign out")) {
                    Button(action: {
                        logOutServer { result, data in
                            clearCookie()
                            exit(0)
                        }
                    }, label: {
                        Text("Logout & Exit").foregroundColor(.red)
                    }).padding(10)
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
