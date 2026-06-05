//
//  DownloadListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import SwiftUI

struct DownloadListView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var offlinePBM: OfflinePlaybackManager
    @ObservedObject var dlListVC: DownloadListViewController
    var onPlayVideo: ((URL, String, Double?) -> Void)? = nil
    @State private var editMode: EditMode = .inactive
    @State private var selectedFiles = Set<URL>()

    var body: some View {
        List(selection: $selectedFiles) {
            if !downloadManager.activeDownloads.isEmpty {
                Section(header: Text("Active Downloads")) {
                    ForEach(downloadManager.activeDownloads) { item in
                        activeDownloadRow(item)
                    }
                }
            }

            Section(header: Text("Downloaded Videos")) {
                if dlListVC.fileList.count > 0 {
                    ForEach(dlListVC.fileList, id: \.self) { fileURL in
                        downloadedVideoRow(fileURL)
                            .tag(fileURL)
#if !os(tvOS)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteFiles([fileURL])
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
#endif
                    }
                    .onDelete(perform: delete)
                } else {
                    Text("No video cached.")
                }
            }
        }
        .refreshable {
            getDownloadList()
        }
        .onAppear {
            getDownloadList()
        }
        .onReceive(downloadManager.$activeDownloads) { _ in
            getDownloadList()
        }
        .environment(\.editMode, $editMode)
        .toolbar {
#if !os(tvOS)
            if !dlListVC.fileList.isEmpty {
                ToolbarItemGroup(placement: .automatic) {
                    EditButton()
                    if editMode.isEditing {
                        Button(role: .destructive) {
                            deleteSelectedFiles()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .disabled(selectedFiles.isEmpty)
                    }
                }
            }
#endif
        }
#if os(iOS) || os(tvOS)
        .fullScreenCover(isPresented: $dlListVC.presentVideoView,
                         onDismiss: { },
                         content: {
            if let path = dlListVC.videoFilePath {
                ZStack(alignment: .topLeading) {
                    VideoPlayerView(url: path,
                                    seekTime: dlListVC.playbackPosition ?? 0,
                                    bgmItem: .constant(nil),
                                    ep: nil,
                                    isOffline: true,
                                    filename: dlListVC.fileName,
                                    isBGMTVWatched: false)
                    Button(action: {
                        dlListVC.closePlayer()
                    }, label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    })
                    .buttonStyle(.plain)
                    .padding(20)
                }
            }
        })
#endif
#if os(macOS)
        .sheet(isPresented: $dlListVC.presentVideoView) {
            if let path = dlListVC.videoFilePath {
                ZStack(alignment: .topLeading) {
                    VideoPlayerView(url: path,
                                    seekTime: dlListVC.playbackPosition ?? 0,
                                    bgmItem: .constant(nil),
                                    ep: nil,
                                    isOffline: true,
                                    filename: dlListVC.fileName,
                                    isBGMTVWatched: false)
                        .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
                    Button(action: {
                        dlListVC.closePlayer()
                    }, label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 15, height: 15)
                            .foregroundColor(.white)
                    }).buttonStyle(.plain)
                }
            } else {
                Text("Error: Video URL is empty")
				Button(action: {
					dlListVC.closePlayer()
				}, label: {
					Text("OK")
				}).buttonStyle(.plain)
            }
        }
#endif
    }

    @ViewBuilder
    private func downloadedVideoRow(_ fileURL: URL) -> some View {
        let filename = fileURL.lastPathComponent
        let status = offlinePBM.getPlayBackStatus(filename: filename)
        let metadata = downloadManager.getDownloadMetadata(filename: filename)

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle(filename: filename, metadata: metadata, item: status))
                    .lineLimit(2)
                if metadata != nil || status != nil {
                    Text(filename)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let status {
                Text("\(secondsToHoursMinutesSeconds(seconds: status.position))")
                    .foregroundColor(.secondary)
            }
            Button {
                playDownloadedVideo(fileURL)
            } label: {
                Image(systemName: "play.circle")
            }
            .buttonStyle(.borderless)
#if os(tvOS)
			Button(role: .destructive) {
				deleteFiles([fileURL])
			} label: {
				Image(systemName: "trash")
			}
			.buttonStyle(.borderless)
#endif
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !editMode.isEditing {
                playDownloadedVideo(fileURL)
            }
        }
    }

    @ViewBuilder
    private func activeDownloadRow(_ item: DownloadItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayTitle(request: item.request))
                        .lineLimit(2)
                    Text(item.filename)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(role: .destructive) {
                    downloadManager.cancelDownload(filename: item.filename)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
            }

            ProgressView(value: item.progress)

            HStack {
                Text(downloadStateText(item.state))
                Spacer()
                Text("\(Int(item.progress * 100))%")
                if item.totalBytes > 0 {
                    Text("\(formatBytes(item.receivedBytes)) / \(formatBytes(item.totalBytes))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    func delete(at offsets: IndexSet) {
        deleteFiles(offsets.map { dlListVC.fileList[$0] })
    }

    private func deleteSelectedFiles() {
        deleteFiles(Array(selectedFiles))
        selectedFiles.removeAll()
        editMode = .inactive
    }

    private func deleteFiles(_ files: [URL]) {
        files.forEach { deleteItem in
            print("delete:\(deleteItem.lastPathComponent)")
            downloadManager.deleteFile(fileName: deleteItem.lastPathComponent)
            offlinePBM.deletePlayBackStatus(filename: deleteItem.lastPathComponent)
        }
        selectedFiles.subtract(files)
        getDownloadList()
    }

    private func playDownloadedVideo(_ fileURL: URL) {
        let filename = fileURL.lastPathComponent
        if let playerItem = downloadManager.getVideoFileAsset(filename: filename) {
            let position = offlinePBM.getPlayBackStatus(filename: filename)?.position
            if let onPlayVideo {
                onPlayVideo(playerItem, filename, position)
            } else {
                dlListVC.showVideoView(path: playerItem, filename: filename)
            }
        }
    }

    func getDownloadList() {
        downloadManager.getDownloadList { list in
            dlListVC.setFileList(list: list.sorted(by: { i, j in
                displayTitle(filename: i.lastPathComponent) < displayTitle(filename: j.lastPathComponent)
            }))
        }
    }

    func secondsToHoursMinutesSeconds(seconds: Double) -> String {
        let (hr, minf) = modf(seconds / 3600)
        let (min, secf) = modf(60 * minf)
        return "\(formatDoubleToString(number: hr)):\(formatDoubleToString(number: min)):\(formatDoubleToString(number: 60 * secf))"
    }

    func formatDoubleToString(number: Double) -> String {
        if number > 0 && number < 10 {
            return "0\(Int(number))"
        } else if number > 10 {
            return "\(Int(number))"
        } else {
            return "00"
        }
    }

    private func downloadStateText(_ state: DownloadState) -> String {
        switch state {
        case .pending:
            return "Pending"
        case .downloading:
            return "Downloading"
        case .completed:
            return "Completed"
        case .failed(let message):
            return "Failed: \(message)"
        case .cancelled:
            return "Cancelled"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        guard bytes > 0 else { return "0 B" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func displayTitle(request: DownloadRequest) -> String {
        formattedDisplayTitle(
            bangumiName: request.bangumiName,
            episodeNo: request.episodeNo,
            episodeName: request.episodeName,
            fallback: request.filename
        )
    }

    private func displayTitle(
        filename: String,
        metadata: DownloadMetadataItem? = nil,
        item: OfflineVideoItem? = nil
    ) -> String {
        let metadata = metadata ?? downloadManager.getDownloadMetadata(filename: filename)
        if let metadata {
            return formattedDisplayTitle(
                bangumiName: metadata.bangumiName,
                episodeNo: metadata.episodeNo,
                episodeName: metadata.episodeName,
                fallback: filename
            )
        }

        let item = item ?? offlinePBM.getPlayBackStatus(filename: filename)
        return formattedDisplayTitle(
            bangumiName: item?.bangumiName,
            episodeNo: item?.episodeNo,
            episodeName: item?.episodeName,
            fallback: filename
        )
    }

    private func formattedDisplayTitle(
        bangumiName: String?,
        episodeNo: Int?,
        episodeName: String?,
        fallback: String
    ) -> String {
        let trimmedBangumiName = bangumiName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEpisodeName = episodeName?.trimmingCharacters(in: .whitespacesAndNewlines)
        var parts: [String] = []

        if let trimmedBangumiName, !trimmedBangumiName.isEmpty {
            parts.append(trimmedBangumiName)
        }

        var episodeParts: [String] = []
        if let episodeNo {
            episodeParts.append("EP\(episodeNo)")
        }
        if let trimmedEpisodeName, !trimmedEpisodeName.isEmpty {
            episodeParts.append(trimmedEpisodeName)
        }
        if !episodeParts.isEmpty {
            parts.append(episodeParts.joined(separator: " "))
        }

        return parts.isEmpty ? fallback : parts.joined(separator: " - ")
    }
}
