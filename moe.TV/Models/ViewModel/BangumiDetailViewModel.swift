//
//  BangumiDetailViewModel.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/07/04.
//

import Foundation
class BangumiDetailViewModel : ObservableObject {
    @Published var presentVideoView = false
    @Published var presentContinuePlayAlert = false
    @Published var presentSourceSelectAlert = false
    @Published var videoURL:String = ""
    @Published var seek:Double = 0.0
    @Published var ep:EpisodeDetailModel?
    
    func setSelectedEP(ep:EpisodeDetailModel){
        self.ep = ep
    }
    func setVideoURL(url:String){
        videoURL = url
    }
    func showVideoView() {
        self.presentContinuePlayAlert = false
        self.presentSourceSelectAlert = false
        self.presentVideoView = true
    }
    func closePlayer(){
        presentVideoView.toggle()
    }
    func showContinuePlayAlert(){
        self.presentContinuePlayAlert = true
    }
    func showSourceSelectAlert(){
        self.presentSourceSelectAlert = true
    }
    func setSeekTime(time:Double){
        self.seek = time
    }
    
}
