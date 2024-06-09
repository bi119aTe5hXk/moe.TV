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
    @Published var bgmDetailItem:BangumiDetailModel?
    
    
    //1
    func setSelectedEP(ep:EpisodeDetailModel){
        DispatchQueue.main.async {
            self.ep = ep
            self.checkLastWatchPosition(ep: ep)
        }
    }
    
    //2
    func checkLastWatchPosition(ep:EpisodeDetailModel){
        if let watchProgress = ep.watch_progress{
            if watchProgress.percentage != 0 ||
                watchProgress.percentage != 1{
                print("can seek")
                DispatchQueue.main.async {
                    self.presentContinuePlayAlert = true
                }
            }else{
                print("percentage 0 or 1")
                self.checkVideoSource(ep:ep, seekTime: 0)
            }
        }else{
            print("no watchProgress")
            self.checkVideoSource(ep:ep, seekTime: 0)
        }
    }
    
    //3
    func checkVideoSource(ep:EpisodeDetailModel,seekTime:Double){
        self.seek = seekTime
        if (ep.video_files ?? []).count > 1{
            print("more than one source")
            DispatchQueue.main.async {
                self.presentSourceSelectAlert = true
            }
            
        }else{
            if let vFile = ep.video_files{
                if let url0 = vFile[0].url{
                    let urlstr = fixPathNotCompete(path: url0).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!
                    self.showVideoView(url: urlstr, seekTime: seekTime)
                }else{
                    print("vFile[0].url is empty!")
                }
            }else{
                print("ep.video_files is empty!")
            }
        }
    }
    
    
    
    //4
    func showVideoView(url:String, seekTime:Double) {
        DispatchQueue.main.async {
            self.seek = seekTime
            self.videoURL = url
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
    
    
    func getBGMDetail(id:String){
        print("getBGMDetail:\(id)")
        getBangumiDetail(id: id) { result, data in
            if !result{
                return
            }
            if let bgmItem = data as? BangumiDetailModel{
                DispatchQueue.main.async {
                    self.bgmDetailItem = bgmItem
                }
            }
        }
    }
    
    
}
