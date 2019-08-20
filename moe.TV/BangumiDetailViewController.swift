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

class BangumiDetailViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {


    var bangumiUUID: String = ""
    var bgmDic = ["": ""] as Dictionary<String, Any>
    var bgmEPlist = [] as Array<Any>

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var summaryText: UITextView!
    
    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLabel.text = ""
        self.subtitleLabel.text = ""
        self.summaryText.text = ""
        
        
        
        print(bangumiUUID)
        // Do any additional setup after loading the view.
        if bangumiUUID.lengthOfBytes(using: .utf8) > 0 {
            getBangumiDetail(id: bangumiUUID) { (isSuccess, result) in
                if isSuccess {
                    self.bgmDic = result as! [String: Any]
                    print(result as Any)

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
                    //TODO - show error
                }
            }
        }
    }

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

        cell.titleText?.text = String(rowarr["episode_no"] as! Int) + "." + (rowarr["name"] as! String)
        //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
        let imgurlstr = "https://" + UserDefaults.standard.string(forKey: "serveraddr")! + (rowarr["thumbnail"] as! String)
        cell.iconView?.image = nil
        DispatchQueue.global().async {
            do {
                let imgdata = try Data.init(contentsOf: URL(string: imgurlstr)!)
                let image = UIImage.init(data: imgdata)

                DispatchQueue.main.async {
                    cell.iconView?.image = image
                }
            } catch { }
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
                let dic = result as! Dictionary<String,Any>
                let videoList = dic["video_files"] as! Array<Any>
                if videoList.count == 1{
                    //only one video
                    let arr = videoList[0] as! Dictionary<String,Any>
                    let videoURLstr = "https://" + UserDefaults.standard.string(forKey: "serveraddr")! + (arr["url"] as! String)
                    self.startPlayVideo(fromURL: videoURLstr)
                }else if videoList.count > 1{
                    //more than one video source, user shoule select
                }else{
                    //no video
                }
            }
        }
    }
    
    func startPlayVideo(fromURL:String) {
        let player = AVPlayer(url: URL(string: urlEncode(string: fromURL) )!)
        let controller = AVPlayerViewController()
        controller.player = player
        present(controller, animated: true) {
            player.play()
        }
    }
    
    func urlEncode(string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
    }

}
