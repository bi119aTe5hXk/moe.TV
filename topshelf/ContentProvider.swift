//
//  ContentProvider.swift
//  topshelf
//
//  Created by bi119aTe5hXk on 2019/08/19.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {
    
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Fetch content and call completionHandler
        let topShelfArr = UserDefaults.init(suiteName: "group.moe.TV")?.array(forKey: "topShelfArr")
        //print(topShelfArr as Any)
        if topShelfArr != nil && topShelfArr!.count > 0 {
            var items = [] as Array<TVTopShelfItem>
            for item in topShelfArr! {
                let dic = item as! Dictionary<String,Any>
                //print(dic["id"] as Any)
                let item  = TVTopShelfSectionedItem(identifier:dic["id"] as! String)
                item.imageShape = .poster
                item.setImageURL(URL(string: dic["image"] as! String), for: .screenScale2x)
                item.title = (dic["name"] as! String)
                item.displayAction = TVTopShelfAction(url: URL(string: "moetv://detail/\(dic["id"]!)/")!)
                
                if let unwatched_count = dic["unwatched_count"] {
                    let count = unwatched_count as! Int
                    let ep_count = (dic["eps"] as! Int)
                    let progress = Double(count) / Double(ep_count)
                    item.playbackProgress = progress
                }
                
                items.append(item)
            }
            
            let collection = TVTopShelfItemCollection(items: items)
            collection.title = "My Bangumi List"
            let itemConllections = [collection]
            
            let content = TVTopShelfSectionedContent(sections: itemConllections as! [TVTopShelfItemCollection<TVTopShelfSectionedItem>])
            completionHandler(content);
        }else{
            completionHandler(nil);
        }
    }
    
    

}

