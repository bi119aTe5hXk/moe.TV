//
//  DownloadListViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import Foundation
class DownloadListViewController: ObservableObject{
    @Published var fileList = [URL]()
    @Published var fileName = ""
    @Published var playbackPosition:Double?
    @Published var presentVideoView = false
    @Published var videoFilePath:URL?
    let offlinePBM = OfflinePlaybackManager()
    
    func setFileList(list:Array<URL>){
        self.fileList = list
    }
    func showVideoView(path:URL, filename:String){
        DispatchQueue.main.async {
            self.presentVideoView = false
            self.videoFilePath = path
            self.fileName = filename
            self.playbackPosition = nil
            if let pbItem = self.offlinePBM.getPlayBackStatus(filename: filename){
                print("getPosition:\(pbItem.position)")
                self.playbackPosition = pbItem.position
            }
            DispatchQueue.main.async {
                self.presentVideoView = true
            }
        }
    }
    func closePlayer(){
        DispatchQueue.main.async {
            self.presentVideoView = false
            self.videoFilePath = nil
            self.fileName = ""
            self.playbackPosition = nil
        }
    }
    
    
}
