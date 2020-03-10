//
//  MyBangumiListViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
private let reuseIdentifier = "Cell"

class MyBangumiListViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var bgmList: Array<Any> = []
    var serviceType = ""

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.delegate = self
        // Do any additional setup after loading the view.
        self.serviceType = UserDefaults.standard.string(forKey: UD_SERVICE_TYPE)!
        //self.loadData()
        
    }
    override func viewDidAppear(_ animated: Bool) {
        self.serviceType = UserDefaults.standard.string(forKey: UD_SERVICE_TYPE)!
        //self.loadData()
    }
    override func viewWillAppear(_ animated: Bool) {
        //load service type first
        self.serviceType = UserDefaults.standard.string(forKey: UD_SERVICE_TYPE)!
        self.loadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        //cancelRequest()
    }

    func loadData() {
        let loggedin = UserDefaults.standard.bool(forKey: UD_LOGEDIN)
        if loggedin {
            if self.bgmList.count <= 0 {
                print("getingMyBangumiList")
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()

                
                if self.serviceType == "albireo" {
                    AlbireoGetMyBangumiList {
                        (isSucceeded, result) in
                        self.loadDataToTable(isSucceeded: isSucceeded, result: result as Any)
                    }
                } else if self.serviceType == "sonarr" {
                    SonarrGetSeries(id: -1) {
                        (isSucceeded, result) in
                            self.loadDataToTable(isSucceeded: isSucceeded, result: result as Any)
                        }
                    
                } else {
                    print("MyBangumiList loadData Error: Service type unknown.")
                    return
                }
            }

            }
        }
        func loadDataToTable(isSucceeded:Bool, result:Any){
            //print(result as Any)
            self.loadingIndicator.isHidden = true
            self.loadingIndicator.stopAnimating()

            if isSucceeded {
                //print(result)
                self.bgmList = result as! Array<Any>
                self.collectionView.reloadData()
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(self.bgmList, forKey: UD_TOPSHELF_ARR)
                UserDefaults.init(suiteName: UD_SUITE_NAME)?.synchronize()
                print("saved to topShelfArr")
            } else {
                print(result as Any)
                //let err = result as! String
                //                        let alert = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
                //                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                //                            //self.dismiss(animated: true, completion: nil)
                //                        }))
                //                        self.present(alert, animated: true, completion: nil)
            }
        }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.bgmList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BangumiCell", for: indexPath) as! BangumiCell
        guard let rowarr = bgmList[indexPath.row] as? Dictionary<String, Any> else {
            return cell
        }

        // Configure the cell
        if self.serviceType == "albireo"{
            cell.titleTextField?.text = (rowarr["name"] as! String)
            //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
            let imgurlstr = rowarr["image"] as! String
            cell.iconView.image = nil
            //cell.iconView.af_setImage(withURL: URL(string: imgurlstr)!)


            cell.iconView.af_setImage(withURL: URL(string: imgurlstr)!,
                placeholderImage: nil,
                filter: .none,
                progress: .none,
                progressQueue: .main,
                imageTransition: .noTransition,
                runImageTransitionIfCached: true) { (data) in
                cell.iconView.roundedImage(corners: .allCorners, radius: 6)
            }
        }else if self.serviceType == "sonarr" {
            cell.titleTextField?.text = (rowarr["title"] as! String)
            //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
            
            cell.iconView.image = nil
            let imgarr = rowarr["images"] as! Array<Any>
            for item in imgarr {//found poster in images array
                let dic = item as! Dictionary<String,String>
                if dic["coverType"] == "poster"{
                    let imgstr = SonarrURL() + dic["url"]!
                    
                    cell.iconView.af_setImage(withURL: URL(string: imgstr)!,
                        placeholderImage: nil,
                        filter: .none,
                        progress: .none,
                        progressQueue: .main,
                        imageTransition: .noTransition,
                        runImageTransitionIfCached: true) { (data) in
                        cell.iconView.roundedImage(corners: .allCorners, radius: 6)
                    }
                }
            }
            
        }else{
            print("MyBangumiList cell Error: Service type unknown.")
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 359, height: 600)
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        let arr = self.bgmList[row] as! Dictionary<String, Any>
        let detailvc = self.storyboard?.instantiateViewController(withIdentifier: "BangumiDetailViewController") as! BangumiDetailViewController
        
        if self.serviceType == "albireo"{
            detailvc.bangumiUUID = arr["id"] as! String
        }else if self.serviceType == "sonarr" {
            let uuid = arr["id"] as! Int
            detailvc.bangumiUUID = String(uuid)
        }else{
            print("MyBangumiList didSelectItemAt Error: Service type unknown.")
        }
        
        self.present(detailvc, animated: true)
    }

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
    }
    */

}

