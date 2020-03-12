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
    
    var serviceType = ""
    
        func updateSearchResults(for searchController: UISearchController) {
            filterString = searchController.searchBar.text ?? ""
        }
        var resultArr = [] as Array<Any>
        var pageNum: Int = 1

        var filterString = "" {
            didSet {
                if self.serviceType == "albireo"{
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
                }else if self.serviceType == "sonarr" {
                    
                }else{
                    print("Error: Service type unknown.")
                }
                
                
            }
        }

        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: 359, height: 600)
        }

        static let storyboardIdentifier = "SearchResultsViewController"

        override func viewDidLoad() {
            super.viewDidLoad()
            self.serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)!
            // Uncomment the following line to preserve selection between presentations
            // self.clearsSelectionOnViewWillAppear = false

            // Register cell classes
            self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
            self.collectionView?.delegate = self
            // Do any additional setup after loading the view.
            //first time
            
            
            if self.serviceType == "albireo"{
                self.getBangumiList(name: "")
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            
        }
        func getBangumiList(name: String) {
            
            if self.serviceType == "albireo"{
                AlbireoGetAllBangumiList(page: pageNum, name: name) {
                    (isSucceeded, result) in
                    if isSucceeded {
                        //let resultDir = result as! Array<Any>//Dictionary<String,Any>
                        let arr = result as! Array<Any>
                        self.resultArr = arr//[arr[0]]
                        //print(self.resultArr as Any)
                        self.collectionView?.reloadData()
                    }
                }
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
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

//        override func numberOfSections(in collectionView: UICollectionView) -> Int {
//            // #warning Incomplete implementation, return the number of sections
//            return 1
//        }


        override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            // #warning Incomplete implementation, return the number of items
            //print("cell count:", self.resultArr.count)
            return self.resultArr.count
        }

        override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BangumiCell", for: indexPath) as! BangumiCell
            
            if self.serviceType == "albireo"{
                if let rowarr = resultArr[indexPath.row] as? Dictionary<String, Any> {
                    //print(rowarr["id"] as Any)
                    // Configure the cell
                    cell.titleTextField?.text = (rowarr["name"] as! String)
                    //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
                    let imgurlstr = rowarr["image"] as! String
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

                }
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            
            
            
            return cell
        }

        // MARK: UICollectionViewDelegate

        override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let row = indexPath.row
            let arr = self.resultArr[row] as! Dictionary<String, Any>
            let detailvc = self.storyboard?.instantiateViewController(withIdentifier: "BangumiDetailViewController") as! BangumiDetailViewController
            if self.serviceType == "albireo"{
                detailvc.bangumiUUID = arr["id"] as! String
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            
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
            
            if self.serviceType == "albireo"{
                if indexPath.row == (self.resultArr.count - 1) { //will load more page at the end of the row
                    //print("start insert to", indexPath)
                    pageNum += 1
                    AlbireoGetAllBangumiList(page: pageNum, name: filterString) {
                        (isSucceeded, result) in
                        if isSucceeded {
                            //let resultDir = result as! Array<Any>//Dictionary<String,Any>
                            let arr = result as! Array<Any>
                            //print(self.resultArr as Any)
                            //self.collectionView?.reloadData()
                            if arr.count > 0 {
                                var paths = [IndexPath]()
                                for item in 0..<arr.count {
                                    let count = self.resultArr.count + item
                                    let index = IndexPath(row: count, section: indexPath.section)
                                    //print(index)
                                    paths.append(index)
                                }
                                self.collectionView.performBatchUpdates({
                                    self.resultArr += arr
                                    //print("cell count2:", self.resultArr.count)
                                    self.collectionView.insertItems(at: paths)
                                }, completion: nil)
                                
                            }


                        }
                    }
                }
            }else if self.serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
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
