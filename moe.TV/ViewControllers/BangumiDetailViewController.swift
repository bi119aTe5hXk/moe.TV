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
            self.serviceType = UserDefaults.standard.string(forKey: UD_SERVICE_TYPE)!
            
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
                    
                }else{
                    print("Error: Service type unknown.")
                }
                
                
            }
        }


        @IBAction func showMoreSummary(_ sender: Any) {
            let sumdetailvc = self.storyboard?.instantiateViewController(withIdentifier: "SummaryDetailViewController") as! SummaryDetailViewController
            sumdetailvc.summaryText = (self.bgmDic["summary"] as! String)
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
            guard let rowarr = bgmEPlist[indexPath.row] as? Dictionary<String, Any> else {
                return cell
            }
            
            if self.serviceType == "albireo"{
                
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            
            if (rowarr["name"] as! String).lengthOfBytes(using: .utf8) > 0 {
                cell.titleText?.text = String(rowarr["episode_no"] as! Int) + "." + (rowarr["name"] as! String)
                //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
                let imgurlstr = getServerAddr() + (rowarr["thumbnail"] as! String)
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

                if let watch_progress = rowarr["watch_progress"] {//watching or watched
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
                cell.titleText.text = String(rowarr["episode_no"] as! Int)
                cell.progressBar.setProgress(0, animated: false)
                cell.progressBar.isHidden = true
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
            let arr = self.bgmEPlist[row] as! Dictionary<String, Any>
            let epid = arr["id"] as! String

            if self.serviceType == "albireo"{
                
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            AlbireoGetEpisodeDetail(ep_id: epid) { (isSucceeded, result) in
                if isSucceeded {
                    print(result as Any)
                    let dic = result as! Dictionary<String, Any>
                    if let videoList = dic["video_files"] {
                        let arr = videoList as! Array<Any>
                        if arr.count == 1 {
                            print("only one video")

                            let dic2 = arr[0] as! Dictionary<String, Any>
                            let videoURLstr = getServerAddr() + (dic2["url"] as! String)

                            self.askToSeek(videoURLstr: videoURLstr, outSideDic: dic)

                        } else if arr.count > 1 {
                            let alert = UIAlertController.init(title: "Multiple video source", message: "There're more than one source of this video, please select", preferredStyle: .alert)
                            for item in arr {
                                let dic2 = item as! Dictionary<String, Any>
                                alert.addAction(UIAlertAction.init(title: (dic2["file_name"] as! String), style: .default, handler: { (action) in

                                        let videoURLstr = getServerAddr() + (dic2["url"] as! String)

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
        }

        //warning: watching progress record is outside of sub dictionary, should use root dir instand of "video_files"
        func askToSeek(videoURLstr: String, outSideDic: Dictionary<String, Any>) {
            var seektime = 0.0

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

        }




        // MARK: - Video
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
                
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            // Build title item
            let titleItem = makeMetadataItem(AVMetadataIdentifier.commonIdentifierTitle.rawValue, value: (self.bgmDic["name"] as! String) + " - " + String(dic["episode_no"] as! Int) + "." + (dic["name"] as! String))
            metadata.append(titleItem)
            

            // Build artwork item
            let imgurlstr = self.bgmDic["image"] as! String
            AF.request(imgurlstr).responseImage { (response) in
                switch response.result {
                case .success(let value):
                    if let image:UIImage = value {
                        let artworkItem = self.makeMetadataItem(AVMetadataIdentifier.commonIdentifierArtwork.rawValue, value: image)
                        metadata.append(artworkItem)
                    }
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

            // Build rating item
            let ratingItem = makeMetadataItem(AVMetadataIdentifier.iTunesMetadataContentRating.rawValue, value: "PG")
            metadata.append(ratingItem)

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
                
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
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
            return true
        }
        func playerViewController(_ playerViewController: AVPlayerViewController,
            restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: (Bool) -> Void) {

        }

        func urlEncode(string: String) -> String {
            return string.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        }

}
