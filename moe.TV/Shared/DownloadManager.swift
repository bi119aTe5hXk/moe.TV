//
//  DownloadManager.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import Foundation

final class DownloadManager: ObservableObject {
    @Published var isDownloading = false
    
    func downloadFile(urlString:String,savedAs:String) {
        print("start download url:\(urlString)")
        DispatchQueue.main.async {
            self.isDownloading = true
        }
        let url = URL(string: urlString)!
        print("filename:\(savedAs)")
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
                        let destinationUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(savedAs)
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
        dataTask.resume()
    }
    func checkFileExists(fileName:String) -> Bool {
        let fileList = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for file in fileList {
            let destinationUrl = file.appendingPathComponent(fileName)
            if (FileManager().fileExists(atPath: destinationUrl.path)) {
                return true
            }
        }
        return false
    }
    
    func getDownloadList(completion:@escaping (Array<URL>) -> Void){
        do{
            let path = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,appropriateFor: nil, create: false)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            completion(directoryContents)
        }catch{
            print(error)
        }
    }

    func deleteFile(fileName:String) {
        let fileList = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        for file in fileList {
            let destinationUrl = file.appendingPathComponent(fileName)
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
        let docsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first

        let destinationUrl = docsUrl?.appendingPathComponent(filename)
        if let destinationUrl = destinationUrl {
            if (FileManager().fileExists(atPath: destinationUrl.path)) {
                return destinationUrl
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
