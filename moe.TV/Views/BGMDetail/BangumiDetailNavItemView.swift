//
//  BangumiDetailNavItemView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/19.
//

import SwiftUI

struct BangumiDetailNavItemView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @Binding var bgmItem: BangumiDetailModel?

    var body: some View {
        Menu {
            Button("Download All", action: startDownloadAll)
#if !os(tvOS)
            Button("Show in bgm.tv", action: openBangumi)
#endif
        } label: {
            Image(systemName: "ellipsis")
        }
        .alert("All video download failed.", isPresented: $downloadManager.isAllDownloadFailed) {
        }
    }

#if !os(tvOS)
    private func openBangumi() {
        if let item = bgmItem {
            if let bgmID = item.bgm_id {
                let urlString = "https://bgm.tv/subject/\(String(bgmID))"
                openURLInApp(urlString: urlString)
            }
        }
    }
#endif

    private func startDownloadAll() {
        if let item = bgmItem {
            downloadManager.downloadAllEPs(bgmItem: item)
        }
    }
}

//struct BangumiDetailNavItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailNavItemView()
//    }
//}
