//
//  ContentProvider.swift
//  topshelf
//
//  Created by bi119aTe5hXk on 2019/08/19.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import TVServices


class ContentProvider: TVTopShelfContentProvider {
    //let topitems = TVTopShelfContent()
        
    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Fetch content and call completionHandler
        let topShelfArr = UserDefaults.init(suiteName: "topShelf")?.array(forKey: "topShelfArr")
        print(topShelfArr as Any)
        if topShelfArr != nil && topShelfArr!.count > 0 {
            
            
            
            let content  = TVTopShelfSectionedItem(identifier: "id")
            completionHandler((content as! TVTopShelfContent));
        }else{
            completionHandler(nil);
        }
    }
    
    

}

