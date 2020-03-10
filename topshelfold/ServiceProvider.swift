//
//  ServiceProvider.swift
//  topshelfold
//
//  Created by bi119aTe5hXk on 2019/08/22.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import TVServices

class ServiceProvider: NSObject, TVTopShelfProvider {
    let serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)
    let topShelfArr = UserDefaults.init(suiteName: UD_SUITE_NAME)!.array(forKey: UD_TOPSHELF_ARR)
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
                //print(dic["id"] as Any)
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
                //print(dic["id"] as Any)
                sectionItem.topShelfItems?.append(contentItemWithDataItem(dic, imageShape: .poster))
            }
        }
        sectionContentItems = [sectionItem]
        return sectionContentItems
    }

    fileprivate func contentItemWithDataItem(_ dataItem: Dictionary<String,Any>, imageShape: TVContentItemImageShape) -> TVContentItem {
        let idstr = "\(dataItem["id"])"
        let contentID = (idstr)
        guard let contentIdentifier:TVContentIdentifier = TVContentIdentifier(identifier: contentID, container: nil) else {
            fatalError("Error creating content identifier for section item.")
        }
        guard let contentItem:TVContentItem = TVContentItem(contentIdentifier: contentIdentifier) else {
            fatalError("Error creating section content item.")
        }
        contentItem.imageShape = .poster
        
        if serviceType! == "albireo"{
            contentItem.title = (dataItem["name"] as! String)
            if #available(tvOSApplicationExtension 11.0, *) {
                contentItem.setImageURL(URL(string: dataItem["image"] as! String), forTraits: .screenScale2x)
            } else {
                // Fallback on earlier versions
                contentItem.imageURL = URL(string: dataItem["image"] as! String)
            }
        }else if serviceType! == "sonarr" {
            contentItem.title = (dataItem["title"] as! String)
            
            let imgarr = dataItem["images"] as! Array<Any>
            for item in imgarr {//found poster in images array
                let dic = item as! Dictionary<String,String>
                if dic["coverType"] == "poster"{
                    let imgstr = SonarrURL() + dic["url"]!
                    
                    contentItem.imageURL = URL(string: imgstr)
                }
            }
            
            
        }else{
            print("Error: Service type unknown.")
        }
        
        
        contentItem.displayURL = URL(string: "moetv://detail/\(dataItem["id"]!)/")!
        return contentItem
    }
    
    func SonarrURL()->String{
        var urlstr = ""
        
        //add http basic auth info if needed
        if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_SONARR_USINGBASICAUTH) {
            let username = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_USERNAME)
            let password = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_PASSWORD)
            urlstr  = "\(username!):\(password!)@"
        }
        
        //append host name and port
        urlstr.append((UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR))!)
        
        //add http/https prefix
        urlstr = addPrefix(url: urlstr)
        
        return urlstr
    }
    func addPrefix(url:String) -> String{
        var urlstr = url
        if (UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_USING_HTTPS)){
                urlstr = "https://" + urlstr
            }else{
                urlstr = "http://" + urlstr
            }
        return urlstr
    }
}


