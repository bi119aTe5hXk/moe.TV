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
    @State var showVideoFileExisitAlert = false
    @ObservedObject var detailVM : BangumiDetailViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var offlinePBM:OfflinePlaybackManager
    
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
                    ZStack{
                        if let thumbnail = epItem.thumbnail{
                            CachedAsyncImage(url: URL(string: fixPathNotCompete(path: thumbnail))){ image in
                                image.resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                Image(systemName: "play.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                
                            } placeholder:{
                                ProgressView()
                            }
                        }
                    }
                        
                    
                })
                .buttonStyle(.plain)
                .frame(width: geo.size.width,height: geo.size.height,alignment: .center)
            }
            .frame(maxWidth: 400)
            .padding(10)
            
            Text("\(epItem.episode_no ?? 0).")
            if !((epItem.name ?? "").isEmpty){
                Text("\(epItem.name ?? "")")
                    .lineLimit(1)
                    .background(Color.clear)
                
            }
            
            
            Spacer()

            EPCellProgressView(progress: .constant(CGFloat(epItem.watch_progress?.percentage ?? 0)),
                               color:.constant(epItem.watch_progress?.watch_status == 2 ? Color.green : Color.orange))
                .frame(maxWidth: 100,maxHeight: 100)
                .padding(10)
#if !os(tvOS)
            Menu {
                //TODO:  download status
                Button("Download", action: startDwonload)
                Button("Show in bgm.tv", action: openBangumi)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                    .padding(10)
            }
#else
            Button("Download", action: startDwonload)
#endif
        }
        .background(Color.clear)
        .padding(10)
        
        .alert("Already downloaded, if you want to replace the file, please delete it in download manager.",isPresented: self.$showVideoFileExisitAlert) {
                
            }
        //TODO: show downloading list
        .sheet(isPresented: $downloadManager.isDownloading){
            ProgressAlertView(progress: $downloadManager.downloadProgress)
            
        }
    }
    func startDwonload(){
        getEpisodeDetail(ep_id: epItem.id) { result, data in
            if result{
                if let epDetail = data as? EpisodeDetailModel{
                    if let url = epDetail.video_files![0].url{ //TODO: support multiple video source
                        let fileURL = fixPathNotCompete(path: url).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!
                        if let filename = epDetail.video_files![0].file_path{
                            if !downloadManager.checkFileExists(fileName: filename){
                                downloadManager.downloadFile(urlString: fileURL,savedAs: filename)
                                offlinePBM.setPlayBackStatus(item: OfflineVideoItem(epID: epDetail.id, bgm_eps_id: epDetail.bgm_eps_id,  filename: filename, position: epDetail.watch_progress?.last_watch_position ?? 0, isFinished: false))
                            }else{
                                print("Video file exists")
                                self.showVideoFileExisitAlert.toggle()
                            }
                        }else{
                            print("filename is missing")
                        }
                    }else{
                        print("url is missing")
                    }
                }
            }else{
                print(data as Any)
            }
        }
    }
#if !os(tvOS)
    func openBangumi(){
        if let bgm_eps_id = epItem.bgm_eps_id{
            let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"
            openURLInApp(urlString: urlString)
        }
    }
#endif
}

//struct EPCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        EPCellView(epItem: BGMEpisode(id: "test", bangumi_id: "test", bgm_eps_id: 1, name: "test VERY LONG NAMEEEEEEEEE", thumbnail: testURL.appending("/pic/e0d1939d-298d-491a-9ddd-2c61de104f02/thumbnails/1.png?size=170x0"), status: 2, episode_no: 1, duration: "6",watch_progress: watchProgress(id: "12341234",watch_status: 3, percentage: 0.5)), detailVM: BangumiDetailViewModel())
//    }
//}
