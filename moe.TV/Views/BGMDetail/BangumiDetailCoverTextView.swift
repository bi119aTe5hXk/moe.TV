//
//  BangumiDetailCoverTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/20.
//

import SwiftUI
import CachedAsyncImage
struct BangumiDetailCoverTextView: View {
    @State var item:BangumiDetailModel
    var body: some View {
        HStack{
            Spacer()
            
            if let coverURL = item.image{
                GeometryReader { geo in
                    CachedAsyncImage(url: URL(string: coverURL)){ image in
                        image.resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: geo.size.width,
                           height: geo.size.height,
                           alignment: .center)
                }
                .padding(10)
            }
            
            //Spacer()
            
            Text((item.summary ?? ""))
                .lineLimit(10)
                .padding(10)
            
            Spacer()
            
        }.padding(10)
    }
}

struct BangumiDetailCoverTextView_Previews: PreviewProvider {
    static var previews: some View {
        BangumiDetailCoverTextView(item: BangumiDetailModel(id: "3032ab99-06a1-4ea9-9df1-c98ab8bfb972", summary: "这是“闪光”与“黑衣剑士”在被如此称呼之前的故事——某一天，偶然戴上NERvGear的结城明日奈，原本是与网络游戏无缘的初中三年级少女。游戏管理员告知。", image: "https://lain.bgm.tv/r/400/pic/cover/l/63/24/315375_1ivNC.jpg", type: 2, status: 2, eps: 1))
    }
}
