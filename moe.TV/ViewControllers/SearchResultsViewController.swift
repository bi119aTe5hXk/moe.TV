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
                    //show all
                    //filteredDataItems = allDataItems
                    getAllBangumiList(page: pageNum, name: filterString) {
                        (isSuccess, result) in
                        if isSuccess {
                            //let resultDir = result as! Array<Any>//Dictionary<String,Any>
                            let arr = result as! Array<Any>
                            self.resultArr = arr//[arr[0]]
                            //print(self.resultArr as Any)
                            self.collectionView?.reloadData()
                        } else {

                        }
                    }
                } else {
                    //show search result
                    getAllBangumiList(page: pageNum, name: filterString) {
                        (isSuccess, result) in
                        if isSuccess {
                            //let resultDir = result as! Array<Any>//Dictionary<String,Any>
                            let arr = result as! Array<Any>
                            self.resultArr.append(arr[0])
                            //print(self.resultArr as Any)
                            self.collectionView?.reloadData()
                        } else {

                        }
                    }
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
            print("count:", self.resultArr.count)
            return self.resultArr.count
        }

        override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BangumiCell", for: indexPath) as! BangumiCell
            if let rowarr = resultArr[indexPath.row] as? Dictionary<String, Any> {
                print(rowarr["id"] as Any)
                // Configure the cell
                cell.titleTextField?.text = (rowarr["name"] as! String)
                //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
                let imgurlstr = rowarr["image"] as! String
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
                        break
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
//    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BangumiCell", for: indexPath) as! BangumiCell
//        if let rowarr = resultArr[indexPath.row] as? Dictionary<String, Any>{
//            print(rowarr["id"] as Any)
//            // Configure the cell
//            cell.titleTextField?.text = (rowarr["name"] as! String)
//            //cell.subTitleTextField?.text = (rowarr["name_cn"] as! String)
//            let imgurlstr = rowarr["image"] as! String
//            AF.request(imgurlstr).responseImage { (response) in
//                switch response.result {
//                case .success(let value):
//                    if let image = value as? Image{
//                        cell.iconView.image = image
//                    }
//                    break
//
//                case .failure(let error):
//                    // error handling
//                    print(error)
//                    break
//                }
//            }
//        }
//
//    }
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
