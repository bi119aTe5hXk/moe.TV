//
//  ContentProvider.swift
//  topshelfold
//
//  Created by bi119aTe5hXk on 2019/08/22.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import TVServices

class ServiceProvider: NSObject, TVTopShelfProvider {
    
    var topShelfStyle: TVTopShelfContentStyle = .sectioned
    
    var topShelfItems: [TVContentItem]{
        return sectionedTopShelfItems
    }
    
    fileprivate var sectionedTopShelfItems: [TVContentItem]{
        let topShelfArr = UserDefaults.init(suiteName: "group.moe.TV")?.array(forKey: "topShelfArr")
        //var items = [] as Array<TVContentItem>
        var sectionContentItems: [TVContentItem] = []
        let sectionTitle = "MyBangumiList"
        guard let sectionIdentifier:TVContentIdentifier = TVContentIdentifier(identifier: sectionTitle, container: nil) else { fatalError("Error creating content identifier for section item.") }
        guard let sectionItem:TVContentItem = TVContentItem(contentIdentifier: sectionIdentifier) else { fatalError("Error creating section content item.") }
        print("loading topshelf")
        print(topShelfArr as Any)
        if topShelfArr != nil && topShelfArr!.count > 0 {
            for item in topShelfArr! {
                let dic = item as! Dictionary<String,Any>
                print(dic["id"] as Any)
                
                let contentID = (dic["id"] as! String)
                guard let contentIdentifier:TVContentIdentifier = TVContentIdentifier(identifier: contentID, container: nil) else {
                    fatalError("Error creating content identifier for section item.")
                    
                }
                guard let contentItem:TVContentItem = TVContentItem(contentIdentifier: contentIdentifier) else {
                    fatalError("Error creating section content item.")
                    
                }
                contentItem.imageShape = .poster
                contentItem.title = (dic["name"] as! String)
                contentItem.setImageURL(URL(string: dic["image"] as! String), forTraits: .screenScale2x)
                contentItem.displayURL = URL(string: "moetv://detail/\(dic["id"]!)/")!
                sectionItem.topShelfItems?.append(contentItem)
            }
        }
        sectionContentItems = [sectionItem]
        return sectionContentItems
    }
}

