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
            CachedAsyncImage(url: URL(string: fixPathNotCompete(path: epItem.thumbnail ?? "") )){ image in
                image.resizable()
            } placeholder:{
                ProgressView()
            }.frame(width: 100,height: 50,alignment: .center)
                .padding(5)
                .background(Color.clear)
            
            HStack{
                Text("\(epItem.episode_no ?? 0). \(epItem.name ?? "")")
                    .background(Color.clear)
                Spacer()
                EPCellProgressView(progress: .constant(CGFloat(epItem.watch_progress?.percentage ?? 0)),color:.constant(epItem.watch_progress?.watch_status == 2 ? Color.green : Color.orange)  )
                    .frame(width: 50,height: 50)
                    .padding(10)
                
            }
            
            
        }.background(Color.clear)
        
    }
}

//struct EPCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        EPCellView(epItem: BGMEpisode(id: "test", bangumi_id: "test", bgm_eps_id: 1, name: "test", thumbnail: "", status: 2, episode_no: 1, duration: "test"))
//    }
//}
