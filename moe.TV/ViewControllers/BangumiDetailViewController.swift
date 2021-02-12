//
//  BangumiDetailViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Alamofire
import AlamofireImage

class BangumiDetailViewController: UIViewController,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    AVPlayerViewControllerDelegate {
        var serviceType = ""
        let playerController = AVPlayerViewController()
        var bangumiUUID: String = ""
        var bgmDic = ["": ""] as Dictionary<String, Any>
        var bgmEPlist = [] as Array<Any>

        @IBOutlet weak var iconView: UIImageView!
        @IBOutlet weak var titleLabel: UILabel!
        @IBOutlet weak var subtitleLabel: UILabel!
        @IBOutlet weak var summaryText: UITextView!
        @IBOutlet weak var summaryDetailButton: UIButton!

        @IBOutlet weak var collectionView: UICollectionView!

        override func viewWillDisappear(_ animated: Bool) {
            //cancelRequest()
        }
        override func viewDidLoad() {
            super.viewDidLoad()
            self.serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)!
            
            self.titleLabel.text = ""
            self.subtitleLabel.text = ""
            self.summaryText.text = ""
            summaryDetailButton.isHidden = true

            print("bangumiUUID:", bangumiUUID)
            // Do any additional setup after loading the view.
            if bangumiUUID.lengthOfBytes(using: .utf8) > 0 {
                
                if self.serviceType == "albireo"{
                    
                    AlbireoGetBangumiDetail(id: bangumiUUID) { (isSucceeded, result) in
                        self.summaryDetailButton.isHidden = false

                        if isSucceeded {
                            self.bgmDic = result as! [String: Any]
                            //print(result as Any)
                            self.bgmEPlist = self.bgmDic["episodes"] as! Array
                            self.titleLabel.text = (self.bgmDic["name"] as! String)
                            self.subtitleLabel.text = (self.bgmDic["name_cn"] as! String)
                            self.summaryText.text = (self.bgmDic["summary"] as! String)

                            let imgurlstr = self.bgmDic["image"] as! String
                            self.iconView.af_setImage(withURL: URL(string: imgurlstr)!,
                                                      placeholderImage: nil,
                                                      filter: .none,
                                                      progress: .none,
                                                      progressQueue: .main,
                                                      imageTransition: .noTransition,
                                                      runImageTransitionIfCached: true) { (data) in
                                                        self.iconView.roundedImage(corners: .allCorners, radius: 6)
                            }
                            self.collectionView.reloadData()

                        } else {
                            print(result as Any)
                            let err = result as! String
                            let alert = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                                //self.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                    
                    
                    
                }else if self.serviceType == "sonarr" {
                    let uuid = Int(bangumiUUID)
                    SonarrGetSeries(id: uuid!) { (isSucceeded, result) in
                        self.summaryDetailButton.isHidden = false
                        if isSucceeded {
                            self.bgmDic = result as! [String: Any]
                            //self.bgmEPlist = self.bgmDic["episodes"] as! Array
                            self.titleLabel.text = (self.bgmDic["title"] as! String)
                            self.subtitleLabel.text = (self.bgmDic["sortTitle"] as! String)
                            self.summaryText.text = (self.bgmDic["overview"] as! String)
                            
                            self.iconView.image = nil
                            let imgarr = self.bgmDic["images"] as! Array<Any>
                            for item in imgarr {//found poster in images array
                                let dic = item as! Dictionary<String,String>
                                if dic["coverType"] == "poster"{
                                    let imgstr = SonarrURL() + dic["url"]!
                                    self.iconView.af_setImage(withURL: URL(string: imgstr)!,
                                        placeholderImage: nil,
                                        filter: .none,
                                        progress: .none,
                                        progressQueue: .main,
                                        imageTransition: .noTransition,
                                        runImageTransitionIfCached: true) { (data) in
                                        self.iconView.roundedImage(corners: .allCorners, radius: 6)
                                    }
                                }
                            }
                            
                            SonarrGetEPList(seriesId: uuid!) {
                                (isSucceeded, result) in
                                if isSucceeded {
                                    //check if hasFile is true and add them to a new list
                                    var epFileList:Array<Any> = []
                                    let arr:Array<Any> = result as! Array<Any>
                                    for item in arr {
                                        let dic = item as! Dictionary<String,Any>
                                        let hasFile = dic["hasFile"] as! Bool
                                        if hasFile == true {
                                            epFileList.append(item)
                                        }
                                    }
                                    //print(epFileList)
                                    self.bgmEPlist = epFileList
                                    self.collectionView.reloadData()
                                }
                            }
                        }else {
                            print(result as Any)
                            let err = result as! Dictionary<String,String>
                            let alert = UIAlertController(title: "Error", message: err["error"], preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                                //self.dismiss(animated: true, completion: nil)
                            }))
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                }else{
                    print("BGMDetail viewDidLoad Error: Service type unknown.")
                }
                
                
            }
        }


        @IBAction func showMoreSummary(_ sender: Any) {
            let sumdetailvc = self.storyboard?.instantiateViewController(withIdentifier: "SummaryDetailViewController") as! SummaryDetailViewController
            if self.serviceType == "albireo"{
                sumdetailvc.summaryText = (self.bgmDic["summary"] as! String)
            }else if self.serviceType == "sonarr" {
                sumdetailvc.summaryText = (self.bgmDic["overview"] as! String)
            }else{
                print("BGMDetail showMoreSummary Error: Service type unknown.")
            }
            
            self.present(sumdetailvc, animated: true)
        }



        // MARK: - CollectionView

        func numberOfSections(in collectionView: UICollectionView) -> Int {
            // #warning Incomplete implementation, return the number of sections
            return 1
        }
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            // #warning Incomplete implementation, return the number of items
            return self.bgmEPlist.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EPCell", for: indexPath) as! EPCell
            guard let rowdic = bgmEPlist[indexPath.row] as? Dictionary<String, Any> else {
                return cell
            }
            
            if self.serviceType == "albireo"{
                if (rowdic["name"] as! String).lengthOfBytes(using: .utf8) > 0 {
                    cell.titleText?.text = String(rowdic["episode_no"] as! Int) + "." + (rowdic["name"] as! String)
                    //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
                    
                    let imgurlstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!) + (rowdic["thumbnail"] as! String)
                    cell.iconView.image = nil
                    cell.iconView.af_setImage(withURL: URL(string: imgurlstr)!,
                                              placeholderImage: nil,
                                              filter: .none,
                                              progress: .none,
                                              progressQueue: .main,
                                              imageTransition: .noTransition,
                                              runImageTransitionIfCached: true) { (data) in
                                                cell.iconView.roundedImage(corners: .allCorners, radius: 6)
                    }

                    if let watch_progress = rowdic["watch_progress"] {//watching or watched
                        let wpdic = watch_progress as! Dictionary<String, Any>
                        let percent = wpdic["percentage"] as! Double
                        //print("percent:",Float(percent))
                        cell.progressBar.isHidden = false
                        DispatchQueue.main.async {
                            cell.progressBar.setProgress(Float(percent), animated: true)//not work, TODO
                        }
                        
                    } else {
                        //unwatched
                        cell.progressBar.setProgress(0, animated: false)
                        cell.progressBar.isHidden = true
                    }
                } else {// name empty or not release yet
                    cell.iconView.image = nil
                    cell.titleText.text = String(rowdic["episode_no"] as! Int)
                    cell.progressBar.setProgress(0, animated: false)
                    cell.progressBar.isHidden = true
                }
                
            }else if self.serviceType == "sonarr" {
                cell.titleText?.text = String(rowdic["episodeNumber"] as! Int) + "." + (rowdic["title"] as! String)
                
                //no video preview image in Sonarr, using iconimage instand
                cell.iconView.image = self.iconView.image
                
                //no progress record in Sonarr
                cell.progressBar.isHidden = true
                
            }else{
                print("BGMDetail load collectionCell Error: Service type unknown.")
            }
            
            
            
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 280, height: 252)
        }

        /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let row = indexPath.row
            let rowdic = self.bgmEPlist[row] as! Dictionary<String, Any>
            

            if self.serviceType == "albireo"{
                let epid = rowdic["id"] as! String
                AlbireoGetEpisodeDetail(ep_id: epid) { (isSucceeded, result) in
                    if isSucceeded {
                        print(result as Any)
                        let dic = result as! Dictionary<String, Any>
                        if let videoList = dic["video_files"] {
                            let arr = videoList as! Array<Any>
                            if arr.count == 1 {
                                print("only one video")

                                let dic2 = arr[0] as! Dictionary<String, Any>
                                let videoURLstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!) + (dic2["url"] as! String)

                                self.askToSeek(videoURLstr: videoURLstr, outSideDic: dic)

                            } else if arr.count > 1 {
                                let alert = UIAlertController.init(title: "Multiple video source", message: "There're more than one source of this video, please select", preferredStyle: .alert)
                                for item in arr {
                                    let dic2 = item as! Dictionary<String, Any>
                                    alert.addAction(UIAlertAction.init(title: (dic2["file_name"] as! String), style: .default, handler: { (action) in

                                            let videoURLstr = addPrefix(url: UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!) + (dic2["url"] as! String)

                                            self.askToSeek(videoURLstr: videoURLstr, outSideDic: dic)
                                        }))

                                    self.present(alert, animated: true, completion: nil)
                                }
                            } else {
                                print("video list empty,ingore")
                            }
                        } else {
                            print("no video")
                            let alert = UIAlertController(title: "No video source", message: "Not boardcast yet or video deleted.", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }

                    }
                }
            }else if self.serviceType == "sonarr" {
                //get video file
                let episodeFile = rowdic["episodeFile"] as! Dictionary<String,Any>
                //print(episodeFile)
                
                //create API url for getting host
                var udurlstr = ""
                //add prefix to http
                udurlstr = addPrefix(url: udurlstr)
                //then append host name and port
                udurlstr.append(UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!)
                
                //replace api host port to WebDAV port
                let webdav_port = UserDefaults.init(suiteName: UD_SUITE_NAME)!.integer(forKey: UD_SONARR_WEBDAV_PORT)
                let udurl = URL(string: udurlstr)
                var udurldomian:String = ""
                //add basic auth info
                udurldomian = addBasicAuth(url: udurldomian)
                //add host name
                udurldomian.append(udurl!.host!)
                //add webdav port
                udurldomian.append(":\(webdav_port)")
                //add prefix back
                udurldomian = addPrefix(url: udurldomian)
                
                var videourl = "\(udurldomian)"
                
                //add video full path
                videourl.append("/")
                videourl.append(episodeFile["path"] as! String)
                
                //replace local path with WebDAV path
                SonarrGetRootFolder {
                    (isSucceeded, result) in
                    if isSucceeded {
                        let arr = result as! Array<Any>
                        let dic = arr[0] as! Dictionary<String,Any>
                        let path = dic["path"] as! String
                        
                        //replace HTML encoding
                        videourl = videourl.replacingOccurrences(of: path, with: "")
                        let urlStr = videourl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
                        print(urlStr)
                        
                        //check playable
                        let playableExtensions = ["mp4", "mov", "m4v"]
                        let url: URL? = NSURL(fileURLWithPath: urlStr) as URL
                        let pathExtention = url?.pathExtension
                        if playableExtensions.contains(pathExtention!)
                        {
                            self.startPlayVideo(fromURL: urlStr, seekTime: 0)
                        }else
                        {
                            //open url using vlc
                            
//                            let vlcUrl1 = URL(string:"vlc://\(urlStr)")
//                            let vlcUrl = URL(string: "vlc-x-callback://x-callback-url/stream?url=\(urlStr)")
//                            if UIApplication.shared.canOpenURL(vlcUrl!) {
//                                UIApplication.shared.open(vlcUrl!, options: [:], completionHandler: nil)
//                            }else if UIApplication.shared.canOpenURL(vlcUrl1!){
//                                UIApplication.shared.open(vlcUrl1!, options: [:], completionHandler: nil)
//                            }
                            
                            //using VLC player
                            let media: VLCMedia = VLCMedia(url: URL(string: urlStr)!)
                            let player = VLCMediaPlayer()
                            player.media = media
                            let playerViewController = VLCPlayerViewController.instantiate(player: player)
                            self.present(playerViewController, animated: true)
                        }
                        
                    }
                }
            }else{
                print("BGMDetail collectionView didSelectItemAt Error: Service type unknown.")
            }
            
        }

        //warning: watching progress record is outside of sub dictionary, should use root dir instand of "video_files"
        func askToSeek(videoURLstr: String, outSideDic: Dictionary<String, Any>) {
            var seektime = 0.0
            if self.serviceType == "albireo"{
                if let watchProgressDic = outSideDic["watch_progress"] { //not in dic2!!
                    let dic = watchProgressDic as! Dictionary<String, Any>
                    if (dic["watch_status"] as! Int) != 2 { //is marked as unwatch?
                        //waching in progress, ask to seek
                        let alert = UIAlertController(title: "Start form last watch position?", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in

                            let last_watch_position = dic["last_watch_position"]
                            seektime = (last_watch_position as! Double)
                            print("seekingto:", seektime)
                            self.startPlayVideo(fromURL: videoURLstr, seekTime: seektime)

                        }))
                        alert.addAction(UIAlertAction(title: "No, start from begening", style: .default, handler: { (action) in
                            self.startPlayVideo(fromURL: videoURLstr, seekTime: 0)
                        }))
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        //was wached, but should start from begening
                        self.startPlayVideo(fromURL: videoURLstr, seekTime: 0)
                    }
                } else {
                    //no watching record, start play form begening
                    self.startPlayVideo(fromURL: videoURLstr, seekTime: 0)
                }
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("BGMDetail askToSeek Error: Service type unknown.")
            }
            

        }




        // MARK: - Video Player
        func startPlayVideo(fromURL: String, seekTime: Double) {
            let player = AVPlayer(url: URL(string: urlEncode(string: fromURL))!)
            player.currentItem?.externalMetadata = makeExternalMetadata()
            playerController.player = player
            playerController.delegate = self

            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: nil)

            present(playerController, animated: true) {
                if seekTime > 0.0 {
                    //var currentTime:Float64 = CMTimeGetSeconds(player.currentTime())
                    //currentTime += seekTime
                    let time: Float64 = seekTime
                    player.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                }
                player.play()
            }
        }


        func makeExternalMetadata() -> [AVMetadataItem] {
            var metadata = [AVMetadataItem]()
            let indexPaths = self.collectionView.indexPathsForSelectedItems
            let indexPath = indexPaths![0] as NSIndexPath
            let dic = self.bgmEPlist[indexPath.row] as! Dictionary<String, Any>
            
            if self.serviceType == "albireo"{
                // Build title item
                let titleItem = makeMetadataItem(AVMetadataIdentifier.commonIdentifierTitle.rawValue, value: (self.bgmDic["name"] as! String) + " - " + String(dic["episode_no"] as! Int) + "." + (dic["name"] as! String))
                metadata.append(titleItem)
                

                // Build artwork item
                let imgurlstr = self.bgmDic["image"] as! String
                AF.request(imgurlstr).responseImage { (response) in
                    switch response.result {
                    case .success(let value):
                            let artworkItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierArtwork.rawValue, value: value)
                            metadata.append(artworkItem)
                        break

                    case .failure(let error):
                        // error handling
                        print(error)
                        break
                    }
                }
                
                // Build description item
                let descItem = makeMetadataItem(AVMetadataIdentifier.commonIdentifierDescription.rawValue, value: (self.bgmDic["summary"] as! String))
                metadata.append(descItem)
                
                // Build genre item
                var typeStr = ""
                switch (self.bgmDic["type"] as! Int) {
                case 2:
                    typeStr = "Anime"
                    break
                case 6:
                    typeStr = "TV Shows"
                    break
                default:
                    typeStr = "Other"
                    break
                }
                let genreItem = makeMetadataItem(AVMetadataIdentifier.quickTimeMetadataGenre.rawValue, value: typeStr)
                metadata.append(genreItem)
                
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("BGMDetail makeExternalMetadata Error: Service type unknown.")
            }
            

            

            // Build rating item
            let ratingItem = makeMetadataItem(AVMetadataIdentifier.iTunesMetadataContentRating.rawValue, value: "PG")
            metadata.append(ratingItem)

            

            return metadata
        }

        private func makeMetadataItem(_ identifier: String,
            value: Any) -> AVMetadataItem {
            let item = AVMutableMetadataItem()
            item.identifier = AVMetadataIdentifier(rawValue: identifier)
            item.value = value as? NSCopying & NSObjectProtocol
            item.extendedLanguageTag = "und"
            return item.copy() as! AVMetadataItem
        }


        @objc func playerDidFinishPlaying() {
            _ = self.playerViewControllerShouldDismiss(self.playerController)
            playerController.dismiss(animated: true, completion: nil)
        }
        func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
            let player = playerViewController.player
            let currentItem = player?.currentItem;
            let currentTime = CMTimeGetSeconds(currentItem!.currentTime())
            let percent = CMTimeGetSeconds(currentItem!.currentTime()) / CMTimeGetSeconds(currentItem!.duration)
            var isFinished = false
            if percent > 0.95 {
                print("log it as finished")
                isFinished = true
            }

            if self.serviceType == "albireo"{
                let indexPaths = self.collectionView.indexPathsForSelectedItems
                let indexPath = indexPaths![0] as NSIndexPath
                let dic = self.bgmEPlist[indexPath.row] as! Dictionary<String, Any>
                AlbireoSentEPWatchProgress(ep_id: (dic["id"] as! String),
                    bangumi_id: (dic["bangumi_id"] as! String),
                    last_watch_position: Float(currentTime),
                    percentage: percent,
                    is_finished: isFinished) { (isSucceeded, result) in
                    print(result as Any)

                }
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("BGMDetail playerViewControllerShouldDismiss Error: Service type unknown.")
            }
            
            return true
        }
        func playerViewController(_ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: (Bool) -> Void) {

        }

        func urlEncode(string: String) -> String {
            return string.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        }

}
