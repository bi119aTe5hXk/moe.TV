//
//  BangumiDetailViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/04.
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
        DispatchQueue.main.async {
            self.ep = ep
        }
    }
    func setVideoURL(url:String){
        DispatchQueue.main.async {
            self.videoURL = url
        }
    }
    func showVideoView() {
        DispatchQueue.main.async {
            self.presentContinuePlayAlert = false
            self.presentSourceSelectAlert = false
            self.presentVideoView = true
        }
    }
    func closePlayer(){
        DispatchQueue.main.async {
            self.presentVideoView.toggle()
        }
    }
    func showContinuePlayAlert(){
        DispatchQueue.main.async {
            self.presentContinuePlayAlert = true
        }
    }
    func showSourceSelectAlert(){
        DispatchQueue.main.async {
            self.presentSourceSelectAlert = true
        }
    }
    func setSeekTime(time:Double){
        DispatchQueue.main.async {
            self.seek = time
        }
    }
    
}
