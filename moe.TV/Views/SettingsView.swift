//
//  SettingsView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack{
            Text("Settings")
                .font(.title)
                .padding(10)
            Spacer()
            Button(action: {
                clearCookie()
                exit(0)
            }, label: {
                Text("Logout & Exit")
            }).padding(10)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
