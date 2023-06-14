//
//  BangumiDetailCellView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/13.
//

import SwiftUI
import CachedAsyncImage
struct EPCellView: View {
    @State var epItem:BGMEpisode
    var body: some View {
        HStack{
            CachedAsyncImage(url: URL(string: epItem.thumbnail)){ image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }.frame(width: 200,height: 150,alignment: .leading)
                .padding(5)
                .background(Color.clear)
            
            HStack{
                Text(epItem.name)
                    .background(Color.clear)
                Spacer()
                EPCellProgressView(progress: .constant(CGFloat(epItem.watch_progress?.percentage ?? 0)))
                    .frame(width: 100,height: 100)
                    .padding(10)
                
            }
            
            
        }.background(Color.clear)
        
    }
}

struct EPCellView_Previews: PreviewProvider {
    static var previews: some View {
        EPCellView(epItem: BGMEpisode(id: "test", bangumi_id: "test", bgm_eps_id: 1, name: "test", thumbnail: "test", status: 1, episode_no: 1, duration: "test"))
    }
}
