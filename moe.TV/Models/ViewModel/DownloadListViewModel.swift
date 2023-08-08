//
//  DownloadListViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import Foundation
class DownloadListViewModel: ObservableObject{
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
        self.videoFilePath = path
        self.fileName = filename
        if let pbItem = offlinePBM.getPlayBackStatus(filename: filename){
            print("getPosition:\(pbItem.position)")
            self.playbackPosition = pbItem.position
        }
        self.presentVideoView.toggle()
    }
    
    
}
