//
//  BangumiDetailCellView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/13.
//

import SwiftUI
import CachedAsyncImage



struct EPCellView: View {
    @State var isEmptyEP:Bool = false
	@State var newEPItem:NewEPItem
//    @State var epItem:BGMEpisode
	//@State var bgmEPItem:BGMTVUserEpisodeCollectionModel?
    @State var showVideoFileExisitAlert = false
    @State var showNotDownloadableAlert = false
    @ObservedObject var detailVM : BangumiDetailViewModel
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var offlinePBM:OfflinePlaybackManager
    
    var body: some View {
        HStack{
			//play button
            Button(
action: {
				getAlbireoEPDetail(ep_id: newEPItem.ep.id) { result, data in
                    if result{
                        if let epDetail = data as? EpisodeDetailModel{
                            detailVM.setSelectedEP(ep: epDetail)
                        }
                    }else{
                        print(data as Any)
                    }
                }
            },
 label: {
//                    GeometryReader { geo in
                ZStack{
					if let thumbnail = newEPItem.ep.thumbnail{
                        CachedAsyncImage(
                            url: fixPathNotCompete(path: thumbnail),
                            placeholder: { progress in
                                // Create any view for placeholder (optional).
                                ZStack {
                                    
                                    ProgressView() {
                                        VStack {
                                            Text("Loading...")
                                            
                                            Text("\(progress) %")
                                        }
                                    }
                                }
                            },
                            image: {
                                // Customize image.
                                Image(uiImage: $0)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                    .frame(maxWidth: 300)
                                
                                
                            },error: { error, retry in
                                HStack{
                                    ExecuteCode {
                                        DispatchQueue.main.async {
                                            self.isEmptyEP = true
                                        }
                                    }
                                    
                                    // Create any view for error (optional).
                                    Text("No Picture")
                                }
                                
                            }
                        )
                        //                                .frame(width: geo.size.width,height: geo.size.height,alignment: .center)
                        if !self.isEmptyEP{
                            Image(systemName: "play.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            //                                    .frame(width: geo.size.width,height: geo.size.height,alignment: .center)
                        }
                    }
                    //                        }
                    
                }
                    
                Spacer()
                
                VStack{
                    HStack{
						Text("\(newEPItem.ep.episode_no ?? 0). ")
                        if !((newEPItem.ep.name ?? "").isEmpty){
                            Text("\(newEPItem.ep.name ?? "")")
                                .lineLimit(1)
                                .background(Color.clear)
                        }
                    }
                    if !((newEPItem.ep.name_cn ?? "").isEmpty){
                        Text("\(newEPItem.ep.name_cn ?? "")")
                            .lineLimit(1)
                            .background(Color.clear)
                    }
                }
                
                
                
                Spacer()

	 EPCellProgressView(
		bgmWatchStatus: .constant(
			newEPItem.bgmEP?.type ?? 0
		),
								   progress: .constant(CGFloat(newEPItem.ep.watch_progress?.percentage ?? 0)),
                                   color:.constant(newEPItem.ep.watch_progress?.watch_status == 2 ? Color.green : Color.orange)
)
                    .frame(maxWidth: 100,maxHeight: 100)
                    .padding(10)
                    
                
            })
            .buttonStyle(.plain)
            
            
//            .padding(10)
            
            
            
            
#if !os(tvOS)
            Menu {
                //TODO:  download status
                //TODO:  download unwatch
                Button("Download", action: startDwonload).disabled(self.isEmptyEP)
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
        .alert("No video file.",isPresented: self.$showNotDownloadableAlert) {
                
            }
        
        //TODO: show downloading list
        .sheet(isPresented: $downloadManager.isDownloading){
            ProgressAlertView(progress: $downloadManager.downloadProgress)
            
        }
    }
    func startDwonload(){
		getAlbireoEPDetail(ep_id: newEPItem.ep.id) { result, data in
            if result{
                if let epDetail = data as? EpisodeDetailModel{
                    if let vFiles = epDetail.video_files {
                        if let url = vFiles[0].url{ //TODO: support multiple video source
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
                    }else{
                        print("epDetail.video_files is Empty!")
                        self.showNotDownloadableAlert.toggle()
                    }
                }
            }else{
                print(data as Any)
            }
        }
    }
#if !os(tvOS)
    func openBangumi(){
		if let bgm_eps_id = newEPItem.ep.bgm_eps_id{
            let urlString = "https://bgm.tv/ep/\(String(bgm_eps_id))"
            openURLInApp(urlString: urlString)
        }
    }
#endif
}

//struct EPCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        EPCellView(epItem: BGMEpisode(id: "test", bangumi_id: "test", bgm_eps_id: 1, name: "test VERY LONG NAMEEEEEEEEE", thumbnail: testURL.appending("/pic/e0d1939d-298d-491a-9ddd-2c61de104f02/thumbnails/1.png?size=170x0"), status: 2, episode_no: 1, duration: "6",watch_progress: watchProgress(id: "12341234",watch_status: 3, percentage: 0.5)), detailVM: BangumiDetailViewModel())
//            .environmentObject(DownloadManager())
//    }
//}
