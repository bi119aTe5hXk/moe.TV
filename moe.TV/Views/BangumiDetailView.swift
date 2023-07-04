//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by billgateshxk on 2023/06/10.
//

import SwiftUI
import CachedAsyncImage

struct BangumiDetailView: View {
    @Binding var bgmID:String?
    @State var bgmDetailItem:BangumiDetailModel?
    @ObservedObject var viewModel : BangumiDetailViewModel = BangumiDetailViewModel()
    
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
                    Text(item.name).font(.title)
                    Text(item.name_cn ?? "").font(.title3)
                    Divider()
                    HStack{
                        Spacer()
                        Text(item.summary ?? "")
                        //Spacer()
#if !os(tvOS)
                        Button(action: {
                            let urlString = "https://bgm.tv/subject/\(item.bgm_id)"
                            openURL(urlString: urlString)
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
                ForEach(item.episodes){ ep in
                    
                    Button(action: {
                        getEpisodeDetail(ep_id: ep.id) { result, data in
                            if result{
                                if let epDetail = data as? EpisodeDetailModel{
                                    checkLastWatchPosition(epDetail: epDetail)
                                }
                            }else{
                                print(data)
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
                        //TODO: better close button for macOS
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
    
    func checkLastWatchPosition(epDetail:EpisodeDetailModel){
        if let watchProgress = epDetail.watch_progress{
            if watchProgress.percentage != 0 ||
                watchProgress.percentage != 1{
                print("can seek")
                //TODO: add continue playback alert
                
                checkVideoSource(videoFiles: epDetail.video_files, seekTime: watchProgress.last_watch_position,selectEP: epDetail)
                
            }else{
                print("percentage 0 or 1")
                checkVideoSource(videoFiles: epDetail.video_files, seekTime: 0,selectEP: epDetail)
            }
        }else{
            print("no watchProgress:\(epDetail)")
            checkVideoSource(videoFiles: epDetail.video_files, seekTime: 0,selectEP: epDetail)
        }
    }
    
    func checkVideoSource(videoFiles:[videoFilesListModel],
                          seekTime:Double,
                          selectEP:EpisodeDetailModel){
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
    
    func showPlayer(video_files:videoFilesListModel,
                    seekTime:Double,
                    selectEP:EpisodeDetailModel) {
        viewModel.presentVideoView(url: fixPathNotCompete(path: video_files.url).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)! , seekTime: seekTime,selectEP: selectEP)
    }
    
}

//struct BangumiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailView(bgmID: .constant(""))
//    }
//}
