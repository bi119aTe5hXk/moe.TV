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
    AVPlayerViewControllerDelegate{


        var bangumiUUID: String = ""
        var bgmDic = ["": ""] as Dictionary<String, Any>
        var bgmEPlist = [] as Array<Any>

        @IBOutlet weak var iconView: UIImageView!
        @IBOutlet weak var titleLabel: UILabel!
        @IBOutlet weak var subtitleLabel: UILabel!
        @IBOutlet weak var summaryText: UITextView!
        @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

        @IBOutlet weak var collectionView: UICollectionView!

        override func viewWillDisappear(_ animated: Bool) {
            //cancelRequest()
        }
        override func viewDidLoad() {
            super.viewDidLoad()

            self.titleLabel.text = ""
            self.subtitleLabel.text = ""
            self.summaryText.text = ""

            print("bangumiUUID:", bangumiUUID)
            // Do any additional setup after loading the view.
            if bangumiUUID.lengthOfBytes(using: .utf8) > 0 {
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()

                getBangumiDetail(id: bangumiUUID) { (isSuccess, result) in

                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()

                    if isSuccess {
                        self.bgmDic = result as! [String: Any]
                        //print(result as Any)
                        self.bgmEPlist = self.bgmDic["episodes"] as! Array
                        self.titleLabel.text = (self.bgmDic["name"] as! String)
                        self.subtitleLabel.text = (self.bgmDic["name_cn"] as! String)
                        self.summaryText.text = (self.bgmDic["summary"] as! String)

                        let imgurlstr = self.bgmDic["image"] as! String
                        DispatchQueue.global().async {
                            do {
                                let imgdata = try Data.init(contentsOf: URL(string: imgurlstr)!)
                                let image = UIImage.init(data: imgdata)

                                DispatchQueue.main.async {
                                    self.iconView?.image = image
                                }
                            } catch { }
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
            cell.loadingIndicator.isHidden = false
            cell.loadingIndicator.startAnimating()

            if (rowarr["name"] as! String).lengthOfBytes(using: .utf8) > 0 {
                cell.titleText?.text = String(rowarr["episode_no"] as! Int) + "." + (rowarr["name"] as! String)
                //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
                let imgurlstr = getServerAddr() + (rowarr["thumbnail"] as! String)

                AF.request(imgurlstr).responseImage { (response) in

                    cell.loadingIndicator.isHidden = true
                    cell.loadingIndicator.stopAnimating()

                    switch response.result {
                    case .success(let value):
                        if let image = value as? Image {
                            cell.iconView.image = image
                        }
                        break

                    case .failure(let error):
                        cell.loadingIndicator.isHidden = true
                        cell.loadingIndicator.stopAnimating()

                        // error handling
                        print(error)
                        break
                    }
                }
//            cell.iconView?.image = nil
//            DispatchQueue.global().async {
//                do {
//                    let imgdata = try Data.init(contentsOf: URL(string: imgurlstr)!)
//                    let image = UIImage.init(data: imgdata)
//
//                    DispatchQueue.main.async {
//                        cell.iconView?.image = image
//                    }
//                } catch { }
//            }

                if let watch_progress = rowarr["watch_progress"] {
                    let wpdic = watch_progress as! Dictionary<String, Any>
                    let percent = wpdic["percentage"] as! Double
                    //print("percent:",Float(percent))
                    cell.progressBar.isHidden = false
                    cell.progressBar.setProgress(Float(percent), animated: true)//not work, TODO

                } else {
                    cell.progressBar.setProgress(0, animated: false)
                    cell.progressBar.isHidden = true
                }
            } else {
                cell.iconView.image = nil
                cell.titleText.text = String(rowarr["episode_no"] as! Int)
                cell.progressBar.setProgress(0, animated: false)
                cell.progressBar.isHidden = true
                cell.loadingIndicator.isHidden = true
                cell.loadingIndicator.stopAnimating()
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
            

            getEpisodeDetail(ep_id: epid) { (isSuccess, result) in
                if isSuccess {
                    print(result as Any)
                    let dic = result as! Dictionary<String, Any>
                    if let videoList = dic["video_files"] {
                        let arr = videoList as! Array<Any>
                        if arr.count == 1 {
                            //only one video
                            
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
                            //no video,ingore
                        }
                    }

                }
            }
        }
    
    //warning: watching progress record is outside of sub dictionary, should use root dir instand of "video_files"
    func askToSeek(videoURLstr:String, outSideDic:Dictionary<String,Any>) {
        var seektime = 0.0
        if let watchProgressDic = outSideDic["watch_progress"] { //not in dic2!!
            //waching in progress, ask to seek
            let alert = UIAlertController(title: "Start form beginning?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
                self.startPlayVideo(fromURL: videoURLstr, seekTime: 0)
            }))
            alert.addAction(UIAlertAction(title: "Continue from last watching", style: .default, handler: { (action) in
                let dic3 = watchProgressDic as! Dictionary<String, Any>
                let last_watch_position = dic3["last_watch_position"]
                seektime = (last_watch_position as! Double)
                print("seekingto:", seektime)
                self.startPlayVideo(fromURL: videoURLstr, seekTime: seektime)
            }))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    
    // MARK: - Video
    
        func startPlayVideo(fromURL: String, seekTime: Double) {
            let player = AVPlayer(url: URL(string: urlEncode(string: fromURL))!)
            let controller = AVPlayerViewController()
            controller.player = player
            controller.delegate = self
            present(controller, animated: true) {
                if seekTime > 0.0 {
                    //var currentTime:Float64 = CMTimeGetSeconds(player.currentTime())
                    //currentTime += seekTime
                    let time: Float64 = seekTime
                    player.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC)), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
                }
                player.play()
            }
        }
        func playerViewControllerShouldDismiss(_ playerViewController: AVPlayerViewController) -> Bool {
            let player = playerViewController.player
            let currentItem = player?.currentItem;
            let currentTime = CMTimeGetSeconds(currentItem!.currentTime())
            let percent = CMTimeGetSeconds(currentItem!.currentTime()) / CMTimeGetSeconds(currentItem!.duration)
            var isFinished = false
            if percent > 0.95{
                isFinished = true
            }
            
            let indexPaths = self.collectionView.indexPathsForSelectedItems
            let indexPath = indexPaths![0] as NSIndexPath
            let dic = self.bgmEPlist[indexPath.row] as! Dictionary<String,Any>
            sentEPWatchProgress(ep_id: (dic["id"] as! String),
                                bangumi_id: (dic["bangumi_id"] as! String),
                                last_watch_position: Float(currentTime),
                                percentage: percent,
                                is_finished: isFinished) { (isSuccess, result) in
                                    if !isSuccess{
                                        print("log progress failed:",result as Any)
                                    }
            }
            return true
        }

        func urlEncode(string: String) -> String {
            return string.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        }

}
