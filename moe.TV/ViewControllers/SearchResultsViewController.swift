//
//  SearchViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
private let reuseIdentifier = "Cell"

class SearchResultsViewController: UICollectionViewController,
    UISearchResultsUpdating,
    UICollectionViewDelegateFlowLayout {
        func updateSearchResults(for searchController: UISearchController) {
            filterString = searchController.searchBar.text ?? ""
        }
        var resultArr = [] as Array<Any>
        var pageNum: Int = 1

        var filterString = "" {
            didSet {
                // Return if the filter string hasn't changed.
                guard filterString != oldValue else { return }
                
                // Apply the filter or show all items if the filter string is empty.
                if filterString.isEmpty {
                    //clear all, reset
                    self.resultArr.removeAll(keepingCapacity: false)
                    self.collectionView?.reloadData()
                    self.pageNum = 1
                    
                    //show all
                    self.getBangumiList(name: "")
                } else {
                    //show search result
                    self.getBangumiList(name: filterString)
                }
            }
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 359, height: 600)
        }

        static let storyboardIdentifier = "SearchResultsViewController"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.delegate = self
        // Do any additional setup after loading the view.
        //first time
        self.getBangumiList(name: "")
    }
    func getBangumiList(name:String){
        getAllBangumiList(page: pageNum, name: name) {
            (isSuccess, result) in
            if isSuccess {
                //let resultDir = result as! Array<Any>//Dictionary<String,Any>
                let arr = result as! Array<Any>
                self.resultArr = arr//[arr[0]]
                //print(self.resultArr as Any)
                self.collectionView?.reloadData()
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

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {//no need if using didselect
//        super.prepare(for: segue, sender: sender)
//
//        // Check if a DataItemViewController is being presented.
////        if let dataItemViewController = segue.destination as? DataItemViewController {
////            // Pass the selected `DataItem` to the `DataItemViewController`.
////            guard let indexPath = collectionView?.indexPathsForSelectedItems?.first else { fatalError("Expected a cell to have been selected") }
////            dataItemViewController.configure(with: filteredDataItems[indexPath.row])
////        }
//    }

        // MARK: UICollectionViewDataSource

        override func numberOfSections(in collectionView: UICollectionView) -> Int {
            // #warning Incomplete implementation, return the number of sections
            return 1
        }


        override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            // #warning Incomplete implementation, return the number of items
            return self.resultArr.count
        }

        override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BangumiCell", for: indexPath) as! BangumiCell
            if let rowarr = resultArr[indexPath.row] as? Dictionary<String, Any> {
                //print(rowarr["id"] as Any)
                // Configure the cell
                cell.titleTextField?.text = (rowarr["name"] as! String)
                //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
                let imgurlstr = rowarr["image"] as! String
                cell.iconView.image = nil
                AF.request(imgurlstr).responseImage { (response) in
                    switch response.result {
                    case .success(let value):
                        if let image = value as? Image {
                            cell.iconView.image = image
                        }
                        break
                    case .failure(let error):
                        // error handling
                        print(error)
                        cell.iconView.image = nil
                        break
                    }
                }
                
            }
            return cell
        }

        // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        let arr = self.resultArr[row] as! Dictionary<String, Any>
        let detailvc = self.storyboard?.instantiateViewController(withIdentifier: "BangumiDetailViewController") as! BangumiDetailViewController
        detailvc.bangumiUUID = arr["id"] as! String
        self.present(detailvc, animated: true)
    }
    
    
        /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        //print(indexPath.row)
        if indexPath.row == (self.resultArr.count - 4){
            
            pageNum += 1
            getAllBangumiList(page: pageNum, name: filterString) {
                (isSuccess, result) in
                if isSuccess {
                    //let resultDir = result as! Array<Any>//Dictionary<String,Any>
                    let arr = result as! Array<Any>
                    //print(self.resultArr as Any)
                    //self.collectionView?.reloadData()
                    var paths = [IndexPath]()
                    for item in 0..<arr.count {
                        let index = IndexPath(row: item + self.resultArr.count, section: 0)
                        paths.append(index)
                    }
                    self.resultArr.append(arr[0])
                    self.collectionView.insertItems(at: paths)
                }
            }
        }
    }
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
