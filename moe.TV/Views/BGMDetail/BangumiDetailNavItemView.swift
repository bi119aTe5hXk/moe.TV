//
//  BangumiDetailNavItemView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/19.
//

import SwiftUI

struct BangumiDetailNavItemView: View {
    @Binding var bgmItem:BangumiDetailModel?
#if !os(tvOS)
    var body: some View {
        Menu {
            //TODO:  download status
            Button("Download All", action: startDwonloadAll)
            Button("Show in bgm.tv", action: openBangumi)

        } label: {
            Image(systemName: "ellipsis")
        }
    }
    private  func openBangumi(){
        if let i = bgmItem{
            if let bgm_id = i.bgm_id{
                let urlString = "https://bgm.tv/subject/\(String(bgm_id))"
                openURLInApp(urlString: urlString)
            }
        }
    }
#endif
#if os(tvOS)
    var body: some View {
        Button("Download All", action: startDwonloadAll)
    }
#endif
    private func startDwonloadAll(){
        if let item = bgmItem {
            let m = DownloadManager()
            m.downloadAllEPs(bgmItem: item)
        }
    }
}


//struct BangumiDetailNavItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailNavItemView()
//    }
//}
