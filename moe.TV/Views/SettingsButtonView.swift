//
//  SettingsButtonView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/10.
//

import SwiftUI

struct SettingsButtonView: View {
    @Binding var profileIconURL:String?
    var body: some View {
        if let iconURL = profileIconURL{
            AsyncImage(url: URL(string: iconURL)) { image in
                image.resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
            }
        }else{
            Image(systemName: "gear")
        }
    }
}

//struct SettingsButtonView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsButtonView()
//    }
//}
