//
//  OnAirListViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
private let reuseIdentifier = "Cell"

class OnAirListViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout {
    var bgmList: Array<Any> = []
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView.delegate = self
        // Do any additional setup after loading the view.
        self.loadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        self.loadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        //cancelRequest()
    }
    
    func loadData(){
        let loggedin = UserDefaults.standard.bool(forKey: "loggedin")
        if loggedin {
            if self.bgmList.count <= 0 {
                print("getOnAirList")
                self.loadingIndicator.isHidden = false
                self.loadingIndicator.startAnimating()
                getOnAirList(completion: {
                    (isSuccess, result) in
                    //print(result as Any)
                    self.loadingIndicator.isHidden = true
                    self.loadingIndicator.stopAnimating()
                    if isSuccess {
                        self.bgmList = result as! Array<Any>
                        self.collectionView.reloadData()
                        UserDefaults.init(suiteName: "group.moe.TV")?.set(self.bgmList, forKey: "topShelfArr")
                    }else{
                        print(result as Any)
                        let err = result as! String
//                        let alert = UIAlertController(title: "Error", message: err, preferredStyle: .alert)
//                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
//                            //self.dismiss(animated: true, completion: nil)
//                        }))
//                        self.present(alert, animated: true, completion: nil)
                    }
                })
            }
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
        cell.titleTextField?.text = (rowarr["name"] as! String)
        //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
        let imgurlstr = rowarr["image"] as! String
        cell.iconView.image = nil
        AF.request(imgurlstr).responseImage { (response) in
            switch response.result {
            case .success(let value):
                if let image = value as? Image{
                    cell.iconView.image = image
                    cell.iconView.adjustsImageWhenAncestorFocused = true
                    cell.iconView.roundedImage(corners: UIRectCorner.allCorners, radius: 6)
                }
                break
                
            case .failure(let error):
                // error handling
                print(error)
                cell.iconView.image = nil
                break
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 359, height: 600)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        let arr = self.bgmList[row] as! Dictionary<String, Any>
        let detailvc = self.storyboard?.instantiateViewController(withIdentifier: "BangumiDetailViewController") as! BangumiDetailViewController
        detailvc.bangumiUUID = arr["id"] as! String
        self.present(detailvc, animated: true)
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

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
