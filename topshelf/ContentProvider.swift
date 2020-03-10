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
        print("topshelf init.")
        // Fetch content and call completionHandler
        
        
        let topShelfArr = UserDefaults.init(suiteName: UD_SUITE_NAME)!.array(forKey: UD_TOPSHELF_ARR)
        let serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)
        //print(topShelfArr as Any)
        //print(serviceType)
        
        if topShelfArr != nil && topShelfArr!.count > 0 {
        var items = [] as Array<TVTopShelfItem>
        for item in topShelfArr! {
            let dic = item as! Dictionary<String,Any>
            //print(dic["id"] as Any)
            let idstr = "\(dic["id"])"
            let item  = TVTopShelfSectionedItem(identifier:idstr)
            item.imageShape = .poster
            
            if serviceType == "albireo"{
                item.setImageURL(URL(string: dic["image"] as! String), for: .screenScale2x)
                item.title = (dic["name"] as! String)
                
                if let unwatched_count = dic["unwatched_count"] {
                    let count = unwatched_count as! Int
                    let ep_count = (dic["eps"] as! Int)
                    let progress = Double(count) / Double(ep_count)
                    item.playbackProgress = progress
                }
                    
            }else if serviceType == "sonarr" {
                item.title = (dic["title"] as! String)
                
                let imgarr = dic["images"] as! Array<Any>
                for img in imgarr {//found poster in images array
                    let dic = img as! Dictionary<String,String>
                    if dic["coverType"] == "poster"{
                        let imgstr = SonarrURL() + dic["url"]!
                        
                        item.setImageURL(URL(string: imgstr), for: .screenScale2x)
                    }
                }
            }else{
                print("Error: Service type unknown.")
            }
            
            item.displayAction = TVTopShelfAction(url: URL(string: "moetv://detail/\(dic["id"]!)/")!)
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
    
    
    func SonarrURL()->String{
        var urlstr = ""
        
        //add http basic auth info if needed
        if UserDefaults.init(suiteName: UD_SUITE_NAME)!.bool(forKey: UD_SONARR_USINGBASICAUTH) {
            let username = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_USERNAME)
            let password = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SONARR_PASSWORD)
            urlstr  = "\(username!):\(password!)@"
        }
        
        //append host name and port
        urlstr.append((UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVER_ADDR)!))
        
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


