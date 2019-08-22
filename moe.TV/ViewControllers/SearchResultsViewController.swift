//
//  SearchViewController.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class SearchResultsViewController: UICollectionViewController, UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterString = searchController.searchBar.text ?? ""
    }
    var resultArr = [] as Array<Any>
    var pageNum:Int = 1
    var filterString = "" {
        didSet {
            // Return if the filter string hasn't changed.
            guard filterString != oldValue else { return }

            // Apply the filter or show all items if the filter string is empty.
            if filterString.isEmpty {
                //show all
                //filteredDataItems = allDataItems
                
            }
            else {
                //show search result
                //filteredDataItems = allDataItems.filter { $0.title.localizedStandardContains(filterString) }
                getAllBangumiList(page: pageNum, name: filterString) {
                    (isSuccess, result) in
                    if isSuccess{
                        let resultDir = result as! Dictionary<String,Any>
                        let arr = resultDir["data"] as! Array<Any>
                        self.resultArr.append(arr)
                    }
                }
            }
            // Reload the collection view to reflect the changes.
            collectionView?.reloadData()
        }
    }
    
    static let storyboardIdentifier = "SearchResultsViewController"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
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
        return self.resultArr.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
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
