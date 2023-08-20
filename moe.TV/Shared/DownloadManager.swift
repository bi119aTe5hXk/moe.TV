//
//  DownloadManager.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import Foundation

final class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    @Published var downloadProgress:Double = 0.0
    private let videoFolder = "videos"
    private var observation: NSKeyValueObservation?
    
    func getVideoPath(write:Bool) -> URL?{
        do {
            let vPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,appropriateFor: nil,create: write).appendingPathComponent(videoFolder)
//            print(vPath)
            if !FileManager.default.fileExists(atPath: vPath.path) {
                print("create video folder")
                do {
                    try FileManager.default.createDirectory(atPath: vPath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription)
                }
            }
            return vPath
        }catch{
            print(error)
            return nil
        }
    }
    
    func downloadFile(urlString:String, savedAs:String) {
        print("start download url:\(urlString)")
        DispatchQueue.main.async {
            self.isDownloading = true
        }
        let url = URL(string: urlString)!
        print("saveAs:\(savedAs)")
        if checkFileExists(fileName: savedAs){
            print("file exists, skip download")
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in

            if let error = error {
                DispatchQueue.main.async {
                    print("Request error: ", error)
                    self.isDownloading = false
                }
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            if response.statusCode == 200 {
                guard let data = data else {
                    self.isDownloading = false
                    return
                }
                DispatchQueue.main.async {
                    do {
                        let destinationUrl = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(self.videoFolder).appendingPathComponent(savedAs)
                        try data.write(to: destinationUrl, options: Data.WritingOptions.atomic)

                        DispatchQueue.main.async {
                            self.isDownloading = false
                        }
                    } catch let error {
                        DispatchQueue.main.async {
                            print("Error decoding: ", error)
                            self.isDownloading = false
                        }
                    }
                }
            }
        }
        observation = dataTask.progress.observe(\.fractionCompleted) { progress, _ in
          print("fractionCompleted:\(progress.fractionCompleted)")
            DispatchQueue.main.async {
                self.downloadProgress = progress.fractionCompleted
            }
        }
        dataTask.resume()
    }
    func checkFileExists(fileName:String) -> Bool {
        var isFileExists = false
        if let path = getVideoPath(write: false){
            let destinationUrl = path.appendingPathComponent(fileName)
            if (FileManager().fileExists(atPath: destinationUrl.path)) {
                print("FileISExisit:\(destinationUrl)")
                isFileExists = true
            }
        }
        return isFileExists
    }
    
    func getDownloadList(completion:@escaping (Array<URL>) -> Void){
        if let path = getVideoPath(write: false){
            do {
                let fileList = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
                completion(fileList)
            }catch{
                print(error)
            }
        }
    }

    func deleteFile(fileName:String) {
        if let path = getVideoPath(write: true){
            let destinationUrl = path.appendingPathComponent(fileName)
            if FileManager().fileExists(atPath: destinationUrl.path) {
                do {
                    try FileManager().removeItem(atPath: destinationUrl.path)
                    print("File deleted successfully")
                } catch let error {
                    print("Error while deleting video file: ", error)
                }
            }
        }
    }

    

    func getVideoFileAsset(filename:String) -> URL? {
        do{
            let vPath = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask,appropriateFor: nil,create: true).appendingPathComponent(videoFolder)
            let destinationUrl = vPath.appendingPathComponent(filename)
            if (FileManager().fileExists(atPath: destinationUrl.path)) {
                return destinationUrl
            } else {
                return nil
            }
        }catch{
            print(error)
        }
        return nil
    }
}
