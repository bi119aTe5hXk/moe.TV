//
//  ServiceProvider.swift
//  topshelfold
//
//  Created by bi119aTe5hXk on 2019/08/22.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import TVServices

class ServiceProvider: NSObject, TVTopShelfProvider {
    
    let topShelfArr = UserDefaults.init(suiteName: "group.moe.TV")?.array(forKey: "topShelfArr")
    var topShelfStyle: TVTopShelfContentStyle = .sectioned
    
    var topShelfItems: [TVContentItem]{
        print("topshelfold init.")
        switch topShelfStyle {
        case .sectioned:
            return sectionedTopShelfItems
        case .inset:
            return insetTopShelfItems
        @unknown default:
            return []
        }
    }
    
    fileprivate var insetTopShelfItems: [TVContentItem] {
        var contentItems: [TVContentItem] = []
        // Get an array of `DataItem`s to show on the Top Shelf.
        if topShelfArr != nil && topShelfArr!.count > 0 {
            for item in topShelfArr! {
                let dic = item as! Dictionary<String,Any>
                print(dic["id"] as Any)
                contentItems.append(contentItemWithDataItem(dic, imageShape: .poster))
            }
        }
        return contentItems
    }

    fileprivate var sectionedTopShelfItems: [TVContentItem]{
        var sectionContentItems: [TVContentItem] = []
        let sectionTitle = "My Bangumi List"
        guard let sectionIdentifier:TVContentIdentifier = TVContentIdentifier(identifier: sectionTitle, container: nil) else { fatalError("Error creating content identifier for section item.") }
        guard let sectionItem:TVContentItem = TVContentItem(contentIdentifier: sectionIdentifier) else { fatalError("Error creating section content item.") }

        print(topShelfArr as Any)
        if topShelfArr != nil && topShelfArr!.count > 0 {
            for item in topShelfArr! {
                let dic = item as! Dictionary<String,Any>
                print(dic["id"] as Any)
                sectionItem.topShelfItems?.append(contentItemWithDataItem(dic, imageShape: .poster))
            }
        }
        sectionContentItems = [sectionItem]
        return sectionContentItems
    }

    fileprivate func contentItemWithDataItem(_ dataItem: Dictionary<String,Any>, imageShape: TVContentItemImageShape) -> TVContentItem {
        let contentID = (dataItem["id"] as! String)
        guard let contentIdentifier:TVContentIdentifier = TVContentIdentifier(identifier: contentID, container: nil) else {
            fatalError("Error creating content identifier for section item.")
        }
        guard let contentItem:TVContentItem = TVContentItem(contentIdentifier: contentIdentifier) else {
            fatalError("Error creating section content item.")
        }
        contentItem.imageShape = .poster
        contentItem.title = (dataItem["name"] as! String)
        if #available(tvOSApplicationExtension 11.0, *) {
            contentItem.setImageURL(URL(string: dataItem["image"] as! String), forTraits: .screenScale2x)
        } else {
            // Fallback on earlier versions
            contentItem.imageURL = URL(string: dataItem["image"] as! String)
        }
        contentItem.displayURL = URL(string: "moetv://detail/\(dataItem["id"]!)/")!

        return contentItem
    }
    
}

