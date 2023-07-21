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
            GeometryReader { geo in
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
                            ZStack{
                                image.resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                Image(systemName: "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            }
                        } placeholder:{
                            ProgressView()
                        }
                    }
                    
                })
                
                .buttonStyle(.plain)
                .frame(width: geo.size.width,height: geo.size.height,alignment: .center)
                
            }
            .frame(maxWidth: 400)
            
            
            
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
                .frame(maxWidth: 100,maxHeight: 100)
                .padding(10)
            
        }.background(Color.clear)
            .padding(10)
    }
}

struct EPCellView_Previews: PreviewProvider {
    static var previews: some View {
        EPCellView(epItem: BGMEpisode(id: "test", bangumi_id: "test", bgm_eps_id: 1, name: "test VERY LONG NAMEEEEEEEEE", thumbnail: "https://suki.moe/pic/e0d1939d-298d-491a-9ddd-2c61de104f02/thumbnails/1.png?size=170x0", status: 2, episode_no: 1, duration: "6",watch_progress: watchProgress(id: "12341234",watch_status: 3, percentage: 0.5)), detailVM: BangumiDetailViewModel())
    }
}
