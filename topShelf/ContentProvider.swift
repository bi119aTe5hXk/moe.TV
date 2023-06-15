//
//  ContentProvider.swift
//  topShelf
//
//  Created by billgateshxk on 2023/06/14.
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Fetch content and call completionHandler
        print("topshelf init.")
        
        let save = SaveHandler()
        if let j = save.getTopShelf(){
            var tvTSItems = [] as Array<TVTopShelfItem>
            j.forEach { bgmItem in
                let tsItem  = TVTopShelfSectionedItem(identifier:bgmItem.id)
                tsItem.imageShape = .poster
                tsItem.setImageURL(URL(string: bgmItem.image ?? "")!, for: .screenScale2x)
                tsItem.title = bgmItem.name
                
                if let unwatchCount = bgmItem.unwatched_count{
                    tsItem.playbackProgress = Double(unwatchCount) / Double(bgmItem.eps)
                }
                
                tsItem.displayAction = TVTopShelfAction(url: URL(string: "moetv://detail?id=\(bgmItem.id)")!)
                tvTSItems.append(tsItem)
            }
            let collection = TVTopShelfItemCollection(items: tvTSItems)
            collection.title = "My Bangumi List"
            let itemConllections = [collection]
            
            let content = TVTopShelfSectionedContent(sections: itemConllections as! [TVTopShelfItemCollection<TVTopShelfSectionedItem>])
            completionHandler(content);
            
        }else{
            print("no item")
            completionHandler(nil)
        }
    }

}

