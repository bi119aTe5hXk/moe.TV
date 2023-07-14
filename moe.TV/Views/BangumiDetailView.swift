//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI
import CachedAsyncImage

struct BangumiDetailView: View {
    @Binding var bgmID:String?
    @State var bgmDetailItem:BangumiDetailModel?
    @ObservedObject var detailVM : BangumiDetailViewModel = BangumiDetailViewModel()
    
    var body: some View {
        let _ = {
            if let item = bgmID{
                getBGMDetail(id: item)
            }
            
        }()
        if let item = bgmDetailItem{
            HStack{
                Spacer()
                if let coverURL = item.image{
                    CachedAsyncImage(url: URL(string: coverURL)){ image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }.frame(width: 150,height: 200,alignment: .leading)
                        .padding(10)
                }
                Spacer()
                VStack{
                    //Spacer()
                    Text(item.name ?? "").font(.title)
                    Text(item.name_cn ?? "").font(.title3)
                    Divider()
                    HStack{
                        Spacer()
                        Text(item.summary ?? "")
                        //Spacer()
#if !os(tvOS)
                        Button(action: {
                            let urlString = "https://bgm.tv/subject/\(String(describing: item.bgm_id))"
                            openURLInApp(urlString: urlString)
                        }, label: {
                            Image("bgmtv")
                                .resizable()
                                .frame(width: 30, height: 30)
                        })
#endif
                        Spacer()
                    }
                }
                
                Spacer()
            }.padding(10)
            
            Divider()
            
            List{
                ForEach(item.episodes ?? []){ ep in
                    
                    Button(action: {
                        getEpisodeDetail(ep_id: ep.id) { result, data in
                            if result{
                                if let epDetail = data as? EpisodeDetailModel{
                                    detailVM.setSelectedEP(ep: epDetail)
                                    checkVideoSource()
                                }
                            }else{
                                print(data as Any)
                            }
                        }
                    }, label: {
                        EPCellView(epItem: ep)
                    }).buttonStyle(.plain)
                    .padding(5)
                    .frame(minHeight: 50)
                }
            }
            .refreshable {
                if let item = bgmID{
                    getBGMDetail(id: item)
                }
            }
#if os(iOS) || os(tvOS)
            .fullScreenCover(isPresented:$detailVM.presentVideoView,
                             onDismiss: { },
                             content: {
                if let url = URL(string: detailVM.videoURL){
                    VideoPlayerView(url: url, seekTime: detailVM.seek,ep: detailVM.ep!)
                }else{
                    Text("Error: Video URL is empty")
                }
            })
#endif
#if os(macOS)
            .sheet(isPresented:$detailVM.presentVideoView ) {
                if let url = URL(string: detailVM.videoURL){
                    ZStack(alignment: .topLeading){
                        VideoPlayerView(url: url,seekTime: detailVM.seek,ep: detailVM.ep!)
                            .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
                        //TODO: better close button for macOS
                        Button(action: {
                            detailVM.closePlayer()
                        }, label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .renderingMode(.template)
                                .frame(width: 15, height: 15)
                                .foregroundColor(.white)
                        }).buttonStyle(.plain)
                    }
                    
                }else{
                    Text("Error: Video URL is empty")
                }
            }
#endif
            .alert("Please select a source:",isPresented: $detailVM.presentSourceSelectAlert) {
                if let ep = detailVM.ep{
                    ForEach(ep.video_files
                            ?? [], id: \.self){ item in
                        Button(item.file_name ?? "unknow source"){
                            detailVM.setVideoURL(url: fixPathNotCompete(path: item.url ?? "").addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!)
                        }
                    }
                }
            }
            .alert("Continue from last position?",isPresented: $detailVM.presentContinuePlayAlert) {
                Button("Yes") {
                    detailVM.setSeekTime(time: detailVM.ep!.watch_progress!.last_watch_position!)
                    detailVM.showVideoView()
                }
                Button("No, start from beginning"){
                    detailVM.setSeekTime(time: 0)
                    detailVM.showVideoView()
                }
            }
        }
            
    }
    
    func getBGMDetail(id:String){
        print("getBGMDetail:\(id)")
        getBangumiDetail(id: id) { result, data in
            if !result{
                return
            }
            if let bgmItem = data as? BangumiDetailModel{
                self.bgmDetailItem = bgmItem
            }
        }
    }
    func checkVideoSource(){
        if let ep = detailVM.ep{
            if (ep.video_files ?? []).count > 1{
                print("more than one source")
                detailVM.showSourceSelectAlert()
            }else{
                detailVM.setVideoURL(url: fixPathNotCompete(path: ep.video_files![0].url ?? "").addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!)
                
            }
            checkLastWatchPosition()
        }
    }
    
    func checkLastWatchPosition(){
        if let ep = detailVM.ep{
            if let watchProgress = ep.watch_progress{
                if watchProgress.percentage != 0 ||
                    watchProgress.percentage != 1{
                    print("can seek")
                    detailVM.showContinuePlayAlert()
                }else{
                    print("percentage 0 or 1")
                    detailVM.setSeekTime(time: 0)
                    detailVM.showVideoView()
                }
            }else{
                print("no watchProgress")
                detailVM.setSeekTime(time: 0)
                detailVM.showVideoView()
            }
            
        }
    }
    
}

//struct BangumiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailView(bgmID: .constant(""))
//    }
//}
