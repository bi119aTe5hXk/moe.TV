//
//  DownloadManager.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import Foundation

enum DownloadState: Equatable {
    case pending
    case downloading
    case completed
    case failed(String)
    case cancelled
}

struct DownloadRequest: Equatable {
    let epID: String
    let bgmID: String?
    let bgmEpsID: Int?
    let bangumiName: String?
    let episodeNo: Int?
    let episodeName: String?
    let filename: String
    let urlString: String
}

struct DownloadMetadataItem: Codable, Equatable {
    let filename: String
    let epID: String?
    let bgmEpsID: Int?
    let bangumiName: String?
    let episodeNo: Int?
    let episodeName: String?
}

struct DownloadItem: Identifiable, Equatable {
    var id: String { filename }
    let request: DownloadRequest
    var progress: Double
    var receivedBytes: Int64
    var totalBytes: Int64
    var state: DownloadState

    var filename: String { request.filename }
}

enum DownloadStatus: Equatable {
    case notDownloaded
    case downloading(Double)
    case downloaded
    case failed(String)
}

final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var isAllDownloadFailed = false
    @Published var activeDownloads: [DownloadItem] = []

    private let videoFolder = "videos"
    private let kDownloadMetadataList = "downloadMetadataList"
    private let settingsHandler = SettingsHandler()
    private var tasksByFilename: [String: URLSessionDownloadTask] = [:]
    private var filenamesByTaskIdentifier: [Int: String] = [:]

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        return URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
    }()

    var isDownloading: Bool {
        activeDownloads.contains { item in
            item.state == .pending || item.state == .downloading
        }
    }

    var downloadProgress: Double {
        guard !activeDownloads.isEmpty else { return 0 }
        return activeDownloads.map(\.progress).reduce(0, +) / Double(activeDownloads.count)
    }

    func getVideoPath(write: Bool) -> URL? {
        do {
            let vPath = try FileManager.default
                .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: write)
                .appendingPathComponent(videoFolder)
            if !FileManager.default.fileExists(atPath: vPath.path) {
                print("create video folder")
                try FileManager.default.createDirectory(atPath: vPath.path, withIntermediateDirectories: true, attributes: nil)
            }
            return vPath
        } catch {
            print(error)
            return nil
        }
    }

    func downloadFile(urlString: String, savedAs: String) {
        let request = DownloadRequest(
            epID: savedAs,
            bgmID: nil,
            bgmEpsID: nil,
            bangumiName: nil,
            episodeNo: nil,
            episodeName: nil,
            filename: savedAs,
            urlString: urlString
        )
        enqueueDownload(request)
    }

    func enqueueDownload(_ request: DownloadRequest) {
        DispatchQueue.main.async {
            self.recordDownloadMetadata(request)
            guard !self.checkFileExists(fileName: request.filename) else {
                print("file exists, skip download: \(request.filename)")
                return
            }
            guard self.tasksByFilename[request.filename] == nil else {
                print("file is already downloading: \(request.filename)")
                return
            }
            guard let url = URL(string: request.urlString) else {
                self.setFailedDownload(request: request, message: "Invalid URL")
                return
            }

            print("start download url:\(request.urlString)")
            let task = self.session.downloadTask(with: URLRequest(url: url))
            self.tasksByFilename[request.filename] = task
            self.filenamesByTaskIdentifier[task.taskIdentifier] = request.filename
            self.upsertDownloadItem(
                DownloadItem(
                    request: request,
                    progress: 0,
                    receivedBytes: 0,
                    totalBytes: 0,
                    state: .pending
                )
            )
            task.resume()
        }
    }

    func cancelDownload(filename: String) {
        DispatchQueue.main.async {
            self.tasksByFilename[filename]?.cancel()
            self.tasksByFilename[filename] = nil
            self.updateDownload(filename: filename) { item in
                item.state = .cancelled
            }
            self.activeDownloads.removeAll { $0.filename == filename }
        }
    }

    func status(epID: String? = nil, filename: String?) -> DownloadStatus {
        if let filename, checkFileExists(fileName: filename) {
            return .downloaded
        }
        if let item = activeDownloads.first(where: { item in
            item.filename == filename || (epID != nil && item.request.epID == epID)
        }) {
            switch item.state {
            case .pending, .downloading:
                return .downloading(item.progress)
            case .completed:
                return .downloaded
            case .failed(let message):
                return .failed(message)
            case .cancelled:
                return .notDownloaded
            }
        }
        return .notDownloaded
    }

    func recordDownloadMetadata(_ request: DownloadRequest) {
        let item = DownloadMetadataItem(
            filename: request.filename,
            epID: request.epID,
            bgmEpsID: request.bgmEpsID,
            bangumiName: request.bangumiName,
            episodeNo: request.episodeNo,
            episodeName: request.episodeName
        )
        upsertDownloadMetadata(item)
    }

    func getDownloadMetadata(filename: String) -> DownloadMetadataItem? {
        getDownloadMetadataList()?.first(where: { $0.filename == filename })
    }

    func checkFileExists(fileName: String) -> Bool {
        var isFileExists = false
        if let path = getVideoPath(write: false) {
            let destinationUrl = path.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                print("FileISExisit:\(destinationUrl)")
                isFileExists = true
            }
        }
        return isFileExists
    }

    func getDownloadList(completion: @escaping (Array<URL>) -> Void) {
        if let path = getVideoPath(write: false) {
            do {
                let fileList = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
                completion(fileList)
            } catch {
                print(error)
            }
        }
    }

    func deleteFile(fileName: String) {
        if isDownloading(filename: fileName) {
            cancelDownload(filename: fileName)
        }
        deleteDownloadMetadata(filename: fileName)
        if let path = getVideoPath(write: true) {
            let destinationUrl = path.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                do {
                    try FileManager.default.removeItem(atPath: destinationUrl.path)
                    print("File deleted successfully")
                } catch let error {
                    print("Error while deleting video file: ", error)
                }
            }
        }
    }

    func getVideoFileAsset(filename: String) -> URL? {
        do {
            let vPath = try FileManager.default
                .url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent(videoFolder)
            let destinationUrl = vPath.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                return destinationUrl
            } else {
                return nil
            }
        } catch {
            print(error)
        }
        return nil
    }

    func downloadAllEPs(bgmItem: BangumiDetailModel) {
        guard let eps = bgmItem.episodes, !eps.isEmpty else {
            print("epIDList.count <= 0")
            DispatchQueue.main.async {
                self.isAllDownloadFailed.toggle()
            }
            return
        }

        var didQueueAnyDownload = false
        let group = DispatchGroup()

        for ep in eps {
            group.enter()
            getAlbireoEPDetail(ep_id: ep.id) { result, data in
                defer { group.leave() }
                guard result, let epDetail = data as? EpisodeDetailModel else {
                    print(data as Any)
                    return
                }
                if let request = self.makeDownloadRequest(epDetail: epDetail) {
                    let status = self.status(epID: request.epID, filename: request.filename)
                    if status == .notDownloaded {
                        didQueueAnyDownload = true
                        self.enqueueDownload(request)
                    }
                }
            }
        }

        group.notify(queue: .main) {
            if !didQueueAnyDownload {
                print("all failed")
                self.isAllDownloadFailed.toggle()
            }
        }
    }

    func makeDownloadRequest(epDetail: EpisodeDetailModel) -> DownloadRequest? {
        guard let videoFile = epDetail.video_files?.first else {
            print("epDetail.video_files is empty")
            return nil
        }
        guard let url = videoFile.url else {
            print("url is missing")
            return nil
        }
        guard let filename = videoFile.file_path else {
            print("filename is missing")
            return nil
        }
        guard let fileURL = fixPathNotCompete(path: url).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("invalid download url")
            return nil
        }
        return DownloadRequest(
            epID: epDetail.id,
            bgmID: epDetail.bangumi_id ?? videoFile.bangumi_id,
            bgmEpsID: epDetail.bgm_eps_id,
            bangumiName: epDetail.bangumi?.name_cn?.isEmpty == false ? epDetail.bangumi?.name_cn : epDetail.bangumi?.name,
            episodeNo: epDetail.episode_no,
            episodeName: epDetail.name_cn?.isEmpty == false ? epDetail.name_cn : epDetail.name,
            filename: filename,
            urlString: fileURL
        )
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let filename = filenamesByTaskIdentifier[downloadTask.taskIdentifier] else { return }
        let progress: Double
        if totalBytesExpectedToWrite > 0 {
            progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        } else {
            progress = 0
        }
        DispatchQueue.main.async {
            self.updateDownload(filename: filename) { item in
                item.progress = progress
                item.receivedBytes = totalBytesWritten
                item.totalBytes = totalBytesExpectedToWrite
                item.state = .downloading
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let filename = filenamesByTaskIdentifier[downloadTask.taskIdentifier] else { return }
        guard let destinationFolder = getVideoPath(write: true) else { return }
        let destinationUrl = destinationFolder.appendingPathComponent(filename)

        do {
            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                try FileManager.default.removeItem(at: destinationUrl)
            }
            try FileManager.default.moveItem(at: location, to: destinationUrl)
            DispatchQueue.main.async {
                self.updateDownload(filename: filename) { item in
                    item.progress = 1
                    item.state = .completed
                }
                self.activeDownloads.removeAll { $0.filename == filename }
            }
        } catch {
            DispatchQueue.main.async {
                self.updateDownload(filename: filename) { item in
                    item.state = .failed(error.localizedDescription)
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let filename = filenamesByTaskIdentifier[task.taskIdentifier] else { return }
        DispatchQueue.main.async {
            self.tasksByFilename[filename] = nil
            self.filenamesByTaskIdentifier[task.taskIdentifier] = nil

            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
                    self.activeDownloads.removeAll { $0.filename == filename }
                } else {
                    self.updateDownload(filename: filename) { item in
                        item.state = .failed(error.localizedDescription)
                    }
                }
            }
        }
    }

    private func isDownloading(filename: String) -> Bool {
        tasksByFilename[filename] != nil
    }

    private func upsertDownloadItem(_ item: DownloadItem) {
        if let index = activeDownloads.firstIndex(where: { $0.filename == item.filename }) {
            activeDownloads[index] = item
        } else {
            activeDownloads.append(item)
        }
    }

    private func updateDownload(filename: String, update: (inout DownloadItem) -> Void) {
        guard let index = activeDownloads.firstIndex(where: { $0.filename == filename }) else { return }
        update(&activeDownloads[index])
    }

    private func setFailedDownload(request: DownloadRequest, message: String) {
        upsertDownloadItem(
            DownloadItem(
                request: request,
                progress: 0,
                receivedBytes: 0,
                totalBytes: 0,
                state: .failed(message)
            )
        )
    }

    private func getDownloadMetadataList() -> [DownloadMetadataItem]? {
        let arr = settingsHandler.readArrayFromPList(key: kDownloadMetadataList)
        var decodedItems = [DownloadMetadataItem]()
        arr?.forEach { item in
            if let data = item as? Data,
               let decodedData = try? PropertyListDecoder().decode(DownloadMetadataItem.self, from: data) {
                decodedItems.append(decodedData)
            }
        }
        return decodedItems.isEmpty ? nil : decodedItems
    }

    private func setDownloadMetadataList(_ list: [DownloadMetadataItem]) {
        var encodedItems = [Any]()
        list.forEach { item in
            if let encoded = try? PropertyListEncoder().encode(item) {
                encodedItems.append(encoded)
            }
        }
        settingsHandler.saveToPList(key: kDownloadMetadataList, data: encodedItems)
    }

    private func upsertDownloadMetadata(_ item: DownloadMetadataItem) {
        var list = getDownloadMetadataList() ?? []
        list.removeAll { $0.filename == item.filename }
        list.append(item)
        setDownloadMetadataList(list)
    }

    private func deleteDownloadMetadata(filename: String) {
        var list = getDownloadMetadataList() ?? []
        list.removeAll { $0.filename == filename }
        setDownloadMetadataList(list)
    }
}
