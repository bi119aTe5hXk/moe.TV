//
//  MyBangumiListViewController.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2019/08/16.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class MyBangumiListViewController: UICollectionViewController {
    var bgmList:Array<Any> = []
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
        
        getMyBangumiList {
            (isSuccess,result) in
            print(result as Any)
            
            if isSuccess {
                self.bgmList = result as! Array<Any>
                self.collectionView.reloadData()
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BangumiCell", for: indexPath)
        guard let rowarr = bgmList[indexPath.row] as? Dictionary<String, Any> else{
            return cell
        }
        let iconView = cell.contentView.viewWithTag(2) as! UIImageView
        let titleTextField = cell.contentView.viewWithTag(1) as! UILabel
        // Configure the cell
        titleTextField.text = (rowarr["name"] as! String)
        //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
        if let imgurlstr = rowarr["image"] {
        if (imgurlstr as! String).lengthOfBytes(using: .utf8) <= 0{
                           //no img
                           iconView.image = nil
                       }else{
                           iconView.image = nil
                           DispatchQueue.global().async {
                               do {
                                let imgdata = try Data.init(contentsOf: URL(string: imgurlstr as! String)!)
                                   let image = UIImage.init(data: imgdata)
                                   
                                   DispatchQueue.main.async {
                                       iconView.image = image
                                   }
                               } catch { }
                           }
               }
               
        }
        
    
        return cell
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
