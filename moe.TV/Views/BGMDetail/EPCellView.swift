//
//  BangumiDetailCellView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/13.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct EPCellView: View {
    @State var isEmptyEP: Bool = false
    @State var newEPItem: NewEPItem
    @State var showVideoFileExisitAlert = false
    @State var showNotDownloadableAlert = false
    @State private var loadFailed = false
    @State private var resolvedLocalOfflineItem: OfflineVideoItem?

    @ObservedObject var detailVC: BangumiDetailViewController
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var offlinePBM: OfflinePlaybackManager

    private var activeDownload: DownloadItem? {
        downloadManager.activeDownloads.first { $0.request.epID == newEPItem.ep.id }
    }

    private var localOfflineItem: OfflineVideoItem? {
        if let resolvedLocalOfflineItem {
            return resolvedLocalOfflineItem
        }
        if let item = offlinePBM.getPlayBackStatus(epID: newEPItem.ep.id),
           downloadManager.getVideoFileAsset(filename: item.filename) != nil {
            return item
        }
        if let item = offlinePBM.getPlayBackStatus(bgmEpsID: newEPItem.ep.bgm_eps_id),
           downloadManager.getVideoFileAsset(filename: item.filename) != nil {
            return item
        }
        return nil
    }

    private var downloadMenuTitle: String {
        if let activeDownload {
            return "Downloading \(Int(activeDownload.progress * 100))%"
        }
        if localOfflineItem != nil {
            return "Downloaded"
        }
        return "Download"
    }

    private var isDownloadButtonDisabled: Bool {
        isEmptyEP || activeDownload != nil || localOfflineItem != nil
    }

    var body: some View {
        HStack {
            Button(
                action: playEpisode,
                label: {
                    if loadFailed {
                        Text("No Picture")
                    } else {
                        ZStack {
                            if let thumbnail = newEPItem.ep.thumbnail {
                                WebImage(url: URL(string: fixPathNotCompete(path: thumbnail))) { image in
                                    image.resizable()
                                } placeholder: {
                                    ZStack {
                                        ProgressView() {
                                            VStack {
                                                Text("Loading...")
                                            }
                                        }
                                    }
                                }
                                .onFailure { error in
                                    print("error \(error)")
                                    DispatchQueue.main.async {
                                        self.isEmptyEP = true
                                        loadFailed = true
                                    }
                                }
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 300)
                                .cornerRadius(10)

                                if !self.isEmptyEP {
                                    Image(systemName: "play.circle.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }

                    Spacer()

                    VStack {
                        HStack {
                            Text("\(newEPItem.ep.episode_no ?? 0). ")
                            if !((newEPItem.ep.name ?? "").isEmpty) {
                                Text("\(newEPItem.ep.name ?? "")")
                                    .lineLimit(1)
                                    .background(Color.clear)
                            }
                        }
                        if !((newEPItem.ep.name_cn ?? "").isEmpty) {
                            Text("\(newEPItem.ep.name_cn ?? "")")
                                .lineLimit(1)
                                .background(Color.clear)
                        }

                        if let activeDownload {
                            VStack(alignment: .leading, spacing: 4) {
                                ProgressView(value: activeDownload.progress)
                                Text("Downloading \(Int(activeDownload.progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: 220)
                        }
                    }

                    Spacer()

                    EPCellProgressView(
                        bgmWatchStatus: .constant(newEPItem.bgmEP?.type ?? 0),
                        progress: .constant(CGFloat(newEPItem.ep.watch_progress?.percentage ?? 0)),
                        color: .constant(newEPItem.ep.watch_progress?.watch_status == 2 ? Color.green : Color.orange)
                    )
                    .frame(maxWidth: 100, maxHeight: 100)
                    .padding(10)
                }
            )
            .buttonStyle(.plain)

#if !os(tvOS)
            Menu {
                Button(downloadMenuTitle, action: startDwonload)
                    .disabled(isDownloadButtonDisabled)
                if let activeDownload {
                    Button("Cancel Download", role: .destructive) {
                        downloadManager.cancelDownload(filename: activeDownload.filename)
                    }
                }
                Button("Show in bgm.tv", action: openBangumi)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .padding(10)
            }
#else
            Button(downloadMenuTitle, action: startDwonload)
                .disabled(isDownloadButtonDisabled)
#endif
        }
        .background(Color.clear)
        .padding(10)
        .alert("Already downloaded, if you want to replace the file, please delete it in download manager.", isPresented: self.$showVideoFileExisitAlert) {
        }
        .alert("No video file.", isPresented: self.$showNotDownloadableAlert) {
        }
        .onAppear {
            resolveLocalDownloadIfNeeded()
        }
    }

    private func playEpisode() {
        detailVC.selectedID = newEPItem.ep.id
        getAlbireoEPDetail(ep_id: newEPItem.ep.id) { result, data in
            if result, let epDetail = data as? EpisodeDetailModel {
                if let request = downloadManager.makeDownloadRequest(epDetail: epDetail),
                   let localURL = downloadManager.getVideoFileAsset(filename: request.filename) {
                    offlinePBM.setPlayBackStatus(
                        item: OfflineVideoItem(
                            epID: epDetail.id,
                            bgm_eps_id: epDetail.bgm_eps_id,
                            filename: request.filename,
                            position: epDetail.watch_progress?.last_watch_position ?? 0,
                            isFinished: false,
                            bangumiName: request.bangumiName,
                            episodeNo: request.episodeNo,
                            episodeName: request.episodeName
                        )
                    )
                    detailVC.ep = epDetail
                    detailVC.showVideoView(
                        url: localURL.absoluteString,
                        seekTime: epDetail.watch_progress?.last_watch_position ?? 0,
                        isOffline: true,
                        filename: request.filename
                    )
                } else {
                    detailVC.setSelectedEP(ep: epDetail)
                }
            } else {
                print(data as Any)
            }
        }
    }

    func startDwonload() {
        getAlbireoEPDetail(ep_id: newEPItem.ep.id) { result, data in
            if result, let epDetail = data as? EpisodeDetailModel {
                guard let request = downloadManager.makeDownloadRequest(epDetail: epDetail) else {
                    DispatchQueue.main.async {
                        self.showNotDownloadableAlert.toggle()
                    }
                    return
                }

                switch downloadManager.status(epID: request.epID, filename: request.filename) {
                case .downloaded:
                    DispatchQueue.main.async {
                        self.saveOfflineItem(epDetail: epDetail, request: request)
                        self.resolvedLocalOfflineItem = self.offlinePBM.getPlayBackStatus(filename: request.filename)
                        self.showVideoFileExisitAlert.toggle()
                    }
                case .downloading:
                    print("Video file is already downloading")
                case .failed, .notDownloaded:
                    downloadManager.enqueueDownload(request)
                    saveOfflineItem(epDetail: epDetail, request: request)
                }
            } else {
                print(data as Any)
            }
        }
    }

    private func resolveLocalDownloadIfNeeded() {
		if let item = offlinePBM.getPlayBackStatus(epID: newEPItem.ep.id),
		   downloadManager.getVideoFileAsset(filename: item.filename) != nil {
			resolvedLocalOfflineItem = item
			return
		}
		if let item = offlinePBM.getPlayBackStatus(bgmEpsID: newEPItem.ep.bgm_eps_id),
		   downloadManager.getVideoFileAsset(filename: item.filename) != nil {
			resolvedLocalOfflineItem = item
		}
    }

    private func saveOfflineItem(epDetail: EpisodeDetailModel, request: DownloadRequest) {
        downloadManager.recordDownloadMetadata(request)
        offlinePBM.setPlayBackStatus(
            item: OfflineVideoItem(
                epID: epDetail.id,
                bgm_eps_id: epDetail.bgm_eps_id,
                filename: request.filename,
                position: epDetail.watch_progress?.last_watch_position ?? 0,
                isFinished: false,
                bangumiName: request.bangumiName,
                episodeNo: request.episodeNo,
                episodeName: request.episodeName
            )
        )
    }

#if !os(tvOS)
    func openBangumi() {
        if let bgm_eps_id = newEPItem.ep.bgm_eps_id {
            let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"
            openURLInApp(urlString: urlString)
        }
    }
#endif
}
