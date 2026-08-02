//
//  ContentProvider.swift
//  topShelf
//
//  Created by bi119aTe5hXk on 2023/06/14.
//

import TVServices

class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        // Fetch content and call completionHandler
        print("topshelf init.")
        
        let save = SettingsHandler()
        if let j = save.getTopShelf(){
            var tvTSItems = [] as Array<TVTopShelfItem>
            j.forEach { bgmItem in
                let tsItem  = TVTopShelfSectionedItem(identifier:bgmItem.id)
                tsItem.imageShape = .poster
                if let coverPath = bgmItem.resolvedCoverImageURL {
                    let coverURL = completeServerPath(
                        baseURL: save.getAlbireoServerAddr(),
                        path: coverPath
                    )
                    tsItem.setImageURL(
                        resizedImageURL(
                            coverURL,
                            pixelWidth: 202,
                            pixelHeight: 304,
                            preserveAspectRatio: true
                        ),
                        for: .screenScale1x
                    )
                    tsItem.setImageURL(
                        resizedImageURL(
                            coverURL,
                            pixelWidth: 404,
                            pixelHeight: 608,
                            preserveAspectRatio: true
                        ),
                        for: .screenScale2x
                    )
                }
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
