//
//  DownloadListViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/08/06.
//

import Foundation
class DownloadListViewModel: ObservableObject{
    @Published var fileList = [URL]()
    @Published var presentVideoView = false
    @Published var videoFilePath:URL?
    
    func setFileList(list:Array<URL>){
        self.fileList = list
    }
    func showVideoView(path:URL){
        self.videoFilePath = path
        self.presentVideoView.toggle()
    }
    
    
}
