//
//  BangumiDetailViewModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/04.
//

import Foundation
class BangumiDetailViewModel : ObservableObject {
    @Published var isPresentVideoView = false
    @Published var videoURL:String = ""
    @Published var seek:Double = 0.0
    @Published var ep:EpisodeDetailModel?
    
    func presentVideoView(url:String, seekTime:Double, selectEP:EpisodeDetailModel) {
        print(url)
        videoURL = url
        seek = seekTime
        ep = selectEP
        isPresentVideoView.toggle()
    }
    func closePlayer(){
        isPresentVideoView.toggle()
    }
}
