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
	let newEPItem: NewEPItem
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State var showVideoFileExisitAlert = false
    @State var showNotDownloadableAlert = false
    @State private var loadFailed = false
    @State private var resolvedLocalOfflineItem: OfflineVideoItem?
	@State private var feedbackEpisode: EpisodeDetailModel?
	@State private var showFeedbackLoadError = false
	@State private var feedbackLoadErrorMessage = ""

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

	private var downloadMenuTitle: LocalizedStringKey {
        if let activeDownload {
            return "Downloading \(Int(activeDownload.progress * 100))%"
        }
        if localOfflineItem != nil {
            return "Downloaded"
        }
        return "Download"
    }

	private var canReportVideoIssue: Bool {
		SettingsHandler().getAlbireoAuthMode() == .albireoV2OAuth
	}

	private var isDownloadButtonDisabled: Bool {
		isEmptyEP || activeDownload != nil || localOfflineItem != nil
	}

	private var isEmptyEP: Bool {
		newEPItem.ep.status != 2 && activeDownload == nil && localOfflineItem == nil
	}

	private var thumbnailWidth: CGFloat {
		#if os(tvOS)
		return 300
		#else
		return horizontalSizeClass == .compact ? 120 : 260
		#endif
	}

	private var thumbnailHeight: CGFloat {
		thumbnailWidth * 9 / 16
	}

    var body: some View {
        HStack(spacing: 12) {
            Button(
                action: playEpisode,
                label: {
					HStack(spacing: 12) {
						ZStack {
							Color.black.opacity(0.18)

							if newEPItem.ep.status != 2 || loadFailed {
								Text("No Picture")
									.font(.caption)
									.foregroundColor(.secondary)
							} else if let thumbnail = newEPItem.ep.thumbnail,
								  let thumbnailURL = resizedImageURL(
									fixPathNotCompete(path: thumbnail),
									pixelWidth: 600,
									pixelHeight: 338
								  ) {
								WebImage(
									url: thumbnailURL,
									options: [.retryFailed]
								) { image in
									image.resizable()
								} placeholder: {
									ProgressView {
										Text("Loading...")
									}
								}
								.onFailure { error in
									print("Episode thumbnail failed: \(thumbnailURL.absoluteString), error: \(error)")
									DispatchQueue.main.async {
										loadFailed = true
									}
								}
								.resizable()
								.scaledToFit()

								if !isEmptyEP {
									Image(systemName: "play.circle.fill")
										.font(.largeTitle)
										.foregroundColor(.gray)
								}
							}
						}
						.frame(width: thumbnailWidth, height: thumbnailHeight)
						.clipShape(RoundedRectangle(cornerRadius: 10))

						VStack(alignment: .leading, spacing: 4) {
							HStack(spacing: 4) {
								Text("\(newEPItem.ep.episode_no ?? 0).")
								if let name = newEPItem.ep.name, !name.isEmpty {
									Text(name)
										.lineLimit(1)
								}
							}

							if let nameCN = newEPItem.ep.name_cn, !nameCN.isEmpty {
								Text(nameCN)
									.lineLimit(1)
									.foregroundColor(.secondary)
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
						.frame(maxWidth: .infinity, alignment: .leading)

                    EPCellProgressView(
                        bgmWatchStatus: .constant(newEPItem.bgmEP?.type ?? 0),
                        progress: .constant(CGFloat(newEPItem.ep.watch_progress?.percentage ?? 0)),
                        color: .constant(newEPItem.ep.watch_progress?.watch_status == 2 ? Color.green : Color.orange)
                    )
                    .frame(maxWidth: 100, maxHeight: 100)
                    .padding(10)
					}
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
				if canReportVideoIssue {
					Button(action: prepareFeedback) {
						Label("Report video issue", systemImage: "exclamationmark.bubble")
					}
				}
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
		.sheet(item: $feedbackEpisode) { episode in
			EpisodeFeedbackView(episode: episode)
		}
		.alert("Unable to open feedback", isPresented: $showFeedbackLoadError) {
			Button("OK", role: .cancel) {}
		} message: {
			Text(feedbackLoadErrorMessage)
		}
        .alert("Already downloaded, if you want to replace the file, please delete it in download manager.", isPresented: self.$showVideoFileExisitAlert) {
        }
        .alert("No video file.", isPresented: self.$showNotDownloadableAlert) {
        }
        .onAppear {
            resolveLocalDownloadIfNeeded()
        }
    }

	private func prepareFeedback() {
		getAlbireoEPDetail(ep_id: newEPItem.ep.id) { success, result in
			DispatchQueue.main.async {
				guard success, let episode = result as? EpisodeDetailModel else {
					feedbackLoadErrorMessage = result as? String
						?? String(localized: "Unable to open feedback")
					showFeedbackLoadError = true
					return
				}
				guard episode.video_files?.isEmpty == false else {
					feedbackLoadErrorMessage = String(localized: "No video source is available for feedback.")
					showFeedbackLoadError = true
					return
				}
				feedbackEpisode = episode
			}
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
