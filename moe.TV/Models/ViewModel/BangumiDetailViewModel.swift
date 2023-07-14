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
            self.presentVideoView = false
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
    
    
    func checkVideoSource(){
        if let ep = self.ep{
            if (ep.video_files ?? []).count > 1{
                print("more than one source")
                self.showSourceSelectAlert()
            }else{
                self.setVideoURL(url: fixPathNotCompete(path: ep.video_files![0].url ?? "").addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!)
                
            }
            checkLastWatchPosition()
        }
    }
    func checkLastWatchPosition(){
        if let ep = self.ep{
            if let watchProgress = ep.watch_progress{
                if watchProgress.percentage != 0 ||
                    watchProgress.percentage != 1{
                    print("can seek")
                    self.showContinuePlayAlert()
                }else{
                    print("percentage 0 or 1")
                    self.setSeekTime(time: 0)
                    self.showVideoView()
                }
            }else{
                print("no watchProgress")
                self.setSeekTime(time: 0)
                self.showVideoView()
            }
        }
    }
}
