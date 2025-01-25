//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiDetailView: View {
    @Binding var selectedItem:BangumiItemModel?
    @ObservedObject var detailVM = BangumiDetailViewModel()
    var body: some View {
        //Text("favorite_status:\(selectedItem?.favorite_status)")
        ScrollView{
			BangumiDetailCoverTextView(
				item: $detailVM.bgmDetailItem,
				favorite_status: $detailVM.favorite_status,
				detailVM: detailVM
			)
                .frame(minHeight: 300,maxHeight: 600)
            
            Divider()
            
            ForEach(detailVM.bgmDetailItem?.episodes ?? []){ ep in
                EPCellView(epItem: ep, detailVM: detailVM)
                    .environmentObject(DownloadManager())
                    .environmentObject(OfflinePlaybackManager())
                    .padding(10)
            }
        }
		.onAppear(){
			if let item = selectedItem{
				print(
					"BangumiDetailView onAppear)"
				)
				detailVM.getBGMDetail(id: item.id)
			}
		}
        .onChange(of: selectedItem, initial: true) { newValue in
            if let item = newValue{
				print(
					"BangumiDetailView onchange)"
				)
                detailVM.getBGMDetail(id: item.id)
            }
          }
        .refreshable {
            if let item = selectedItem{
				print(
					"BangumiDetailView refreshable)"
				)
                detailVM.getBGMDetail(id: item.id)
            }
        }
		
        .toolbar(content:{
            if let _ = detailVM.bgmDetailItem{
                ToolbarItem(placement: .principal) {
                    HStack{
                        Spacer()
                        BangumiDetailNavTitleView(item: $detailVM.bgmDetailItem)
                        Spacer()
                        BangumiDetailNavItemView(downloadManager: DownloadManager(), bgmItem: $detailVM.bgmDetailItem)
                    }
                }
            }
        })
        .padding(0)
#if os(iOS) || os(tvOS)
        .fullScreenCover(isPresented:$detailVM.presentVideoView,
                         onDismiss: { },
                         content: {
            if let url = URL(string: detailVM.videoURL){
                VideoPlayerView(url: url,
                                seekTime: detailVM.seek,
								bgmItem: $selectedItem,
                                ep: detailVM.ep!,
                                isOffline: false,
								detailVM: detailVM)
            }else{
                Spacer()
                Text("Error: Video URL is empty")
                Spacer()
                Button(action: {
                    detailVM.closePlayer()
                }, label: {
                    Text("Close")
                })
                Spacer()
            
            }
        })
#endif
#if os(macOS)
        .sheet(isPresented:$detailVM.presentVideoView ) {
            if let url = URL(string: detailVM.videoURL){
                ZStack(alignment: .topLeading){
                    VideoPlayerView(url: url,
                                    seekTime: detailVM.seek,
									bgmItem: $selectedItem,
                                    ep: detailVM.ep!,
									isOffline: false,
									detailVM: detailVM)
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
        }
#endif
        .alert("Please select a source:",isPresented: $detailVM.presentSourceSelectAlert) {
            if let ep = detailVM.ep{
                ForEach(ep.video_files
                        ?? [], id: \.self){ item in
                    Button(item.file_name ?? "unknow source"){
                        if let urlstr = item.url{
                            detailVM.showVideoView(url: fixPathNotCompete(path: urlstr).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!, seekTime: detailVM.seek)
                        }else{
                            print("item.url is empty!")
                        }
                    }
                }
            }
        }
        .alert("Continue from last position?",isPresented: $detailVM.presentContinuePlayAlert) {
            Button("Yes") {
                detailVM.checkVideoSource(ep: detailVM.ep!, seekTime: (detailVM.ep!.watch_progress!.last_watch_position! - 5))
            }
            Button("No, start from beginning"){
                detailVM.checkVideoSource(ep: detailVM.ep!, seekTime: 0)
            }
            
        }
        
    }
}

//struct BangumiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailView(bgmID: .constant(""))
//    }
//}
