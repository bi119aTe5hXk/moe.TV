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
        completionHandler(nil);
    }

}

