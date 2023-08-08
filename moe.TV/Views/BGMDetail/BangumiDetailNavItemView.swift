//
//  BangumiDetailNavItemView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/19.
//

import SwiftUI

struct BangumiDetailNavItemView: View {
    @State var item:BangumiDetailModel
#if !os(tvOS)
    var body: some View {
        Menu {
            //TODO:  download status
            Button("Download All", action: startDwonloadAll).disabled(true)
            Button("Show in bgm.tv", action: openBangumi)

        } label: {
            Image(systemName: "ellipsis")
        }
    }
    private  func openBangumi(){
        if let bgm_id = item.bgm_id{
            let urlString = "https://bgm.tv/subject/\(String(bgm_id))"
            openURLInApp(urlString: urlString)
        }
    }
#endif
#if os(tvOS)
    var body: some View {
        Button("Download All", action: startDwonloadAll).disabled(true)
    }
#endif
    private func startDwonloadAll(){
        //TODO: Download all EPs
    }
}


//struct BangumiDetailNavItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailNavItemView()
//    }
//}
