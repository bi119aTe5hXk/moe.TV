//
//  BangumiDetailNavItemView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/19.
//

import SwiftUI

struct BangumiDetailNavItemView: View {
    @State var item:BangumiDetailModel
    var body: some View {
#if !os(tvOS)
        Button(action: {
            if let bgm_id = item.bgm_id{
                let urlString = "https://bgm.tv/subject/\(String(bgm_id))"
                openURLInApp(urlString: urlString)
            }
        }, label: {
            Image("bgmtv")
                .resizable()
                .frame(width: 30, height: 30)
        })
#endif
    }
}

//struct BangumiDetailNavItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailNavItemView()
//    }
//}
