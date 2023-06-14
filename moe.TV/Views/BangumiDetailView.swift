//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI
import CachedAsyncImage


class BangumiDetailViewModel : ObservableObject {
    @Published var isPresentVideoView:Bool = false
    @Published var videoURL:String = ""
    @Published var seek:Double = 0.0
    @Published var ep:BGMEpisode?
    
    func presentVideoView(url:String, seekTime:Double, selectEP:BGMEpisode) {
        videoURL = url
        seek = seekTime
        ep = selectEP
        isPresentVideoView.toggle()
    }
    func closePlayer(){
        isPresentVideoView.toggle()
    }
}



struct BangumiDetailView: View {
    var bangumiItem:MyBangumiItemModel?
    @State var bgmDetailItem:BangumiDetailModel?

    
    @ObservedObject var viewModel : BangumiDetailViewModel = BangumiDetailViewModel()
    
    var body: some View {
        let _ = {
            if let item = bangumiItem{
                getBGMDetail(id: item.id)
            }
            
        }()
        if let item = bgmDetailItem{
            HStack{
                if let coverURL = item.cover_image_url{
                    CachedAsyncImage(url: URL(string: coverURL)){ image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }.frame(width: 150,height: 200,alignment: .leading)
                        .padding(10)
                }
                VStack{
                    Spacer()
                    Text(item.name).font(.title)
                    Text(item.name_cn ?? "").font(.title3)
                    Divider()
                    Text(item.summary ?? "")
                    Spacer()
                }
            }.padding(10)
            
            Divider()
            
            List{
                ForEach(item.episodes){ ep in
                    EPCellView(epItem: ep)
                        .onTapGesture {
                            getEpisodeDetail(ep_id: ep.id) { result, data in
                                if result{
                                    if let epDetail = data as? EpisodeDetailModel{
                                        checkLastWatchPosition(epDetail: epDetail, epItem: ep)
                                    }
                                }
                            }
                        }
                }
            }
            .refreshable {
                if let item = bangumiItem{
                    getBGMDetail(id: item.id)
                }
            }
#if os(iOS) || os(tvOS)
            .fullScreenCover(isPresented:$viewModel.isPresentVideoView,
                             onDismiss: { },
                             content: {
                if let url = URL(string: viewModel.videoURL){
                    VideoPlayerView(url: url, seekTime: viewModel.seek,ep: viewModel.ep!)
                }else{
                    Text("Error: Video URL is empty")
                }
            })
#endif
#if os(macOS)
            .sheet(isPresented:$viewModel.isPresentVideoView ) {
                if let url = URL(string: viewModel.videoURL){
                    ZStack(alignment: .topLeading){
                        VideoPlayerView(url: url,seekTime: viewModel.seek,ep: viewModel.ep!)
                            .frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
                        //TODO: close button for macOS
                        Button(action: {
                            viewModel.closePlayer()
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
            
        }
            
    }
    
    func getBGMDetail(id:String){
        getBangumiDetail(id: id) { result, data in
            if !result{
                return
            }
            if let bgmItem = data as? BangumiDetailModel{
                self.bgmDetailItem = bgmItem
            }
        }
    }
    
    func checkLastWatchPosition(epDetail:EpisodeDetailModel, epItem:BGMEpisode){
        if let watchProgress = epItem.watch_progress{
            if watchProgress.percentage != 0 ||
                watchProgress.percentage != 1{
                print("can seek")
                
                //TODO: add continue playback alert
                checkVideoSource(videoFiles: epDetail.video_files, seekTime: watchProgress.last_watch_position,selectEP: epItem)
                
            }else{
                print("percentage 0 or 1")
                checkVideoSource(videoFiles: epDetail.video_files, seekTime: 0,selectEP: epItem)
            }
        }else{
            print("no watchProgress:\(epItem)")
            checkVideoSource(videoFiles: epDetail.video_files, seekTime: 0,selectEP: epItem)
        }
    }
    
    func checkVideoSource(videoFiles:[videoFilesListModel],seekTime:Double,selectEP:BGMEpisode){
        if videoFiles.count > 1{
            print("more than one source")
//            Menu{
//                List{
//                    ForEach(videoFiles){ playitem in
//                        Button(action: {
//                            showPlayer(video_files: playitem,seekTime: seekTime,selectEP: selectEP)
//                        }, label: {
//                            Text(playitem.file_name ?? playitem.file_path)
//                        })
//                    }
//                }
//            }  label: {
//                Text("Select a source")
//            }
            //TODO: add muiltable source support
            showPlayer(video_files: videoFiles[0],seekTime: seekTime,selectEP: selectEP)
        }else{
            showPlayer(video_files: videoFiles[0],seekTime: seekTime,selectEP: selectEP)
        }
    }
    
    func showPlayer(video_files:videoFilesListModel,seekTime:Double,selectEP:BGMEpisode) {
        viewModel.presentVideoView(url: video_files.url, seekTime: seekTime,selectEP: selectEP)
    }
    
}

struct BangumiDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BangumiDetailView(bangumiItem: testBangumiItem1)
    }
}
