//
//  BangumiDetailCellView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/13.
//

import SwiftUI
import CachedAsyncImage
struct EPCellView: View {
    @State var epItem:BGMEpisode
    @ObservedObject var detailVM : BangumiDetailViewModel
    
    var body: some View {
        HStack{
            Button(action: {
                getEpisodeDetail(ep_id: epItem.id) { result, data in
                    if result{
                        if let epDetail = data as? EpisodeDetailModel{
                            detailVM.setSelectedEP(ep: epDetail)
                            detailVM.checkVideoSource()
                        }
                    }else{
                        print(data as Any)
                    }
                }
            }, label: {
                if let thumbnail = epItem.thumbnail{
                    CachedAsyncImage(url: URL(string: fixPathNotCompete(path: thumbnail))){ image in
                        image.resizable()
                    } placeholder:{
                        ProgressView()
                    }.frame(width: 250,height: 150,alignment: .center)
                        .padding(5)
                        .background(Color.clear)
                }
                
            })
                .padding(10)
                .buttonStyle(.plain)
                .frame(minHeight: 80)
            
//            Spacer()
            if !((epItem.name ?? "").isEmpty){
                Text("\(epItem.episode_no ?? 0). \(epItem.name ?? "")")
                    .background(Color.clear)
            }
            
            Spacer()
#if !os(tvOS)
            Button(action: {
                if let bgm_eps_id = epItem.bgm_eps_id{
                    let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"
                    openURLInApp(urlString: urlString)
                }
            }, label: {
                Image("bgmtv")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .padding(5)
            }).padding(10)
#endif
            EPCellProgressView(progress: .constant(CGFloat(epItem.watch_progress?.percentage ?? 0)),
                               color:.constant(epItem.watch_progress?.watch_status == 2 ? Color.green : Color.orange))
                .frame(width: 80,height: 80)
                .padding(10)
            
        }.background(Color.clear)
            .padding(10)
    }
}

//struct EPCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        EPCellView(epItem: BGMEpisode(id: "test", bangumi_id: "test", bgm_eps_id: 1, name: "test", thumbnail: "", status: 2, episode_no: 1, duration: "test"))
//    }
//}
