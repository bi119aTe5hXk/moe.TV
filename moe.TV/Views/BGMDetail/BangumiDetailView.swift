//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI

struct BangumiDetailView: View {
	@Binding var selectedItem:BangumiItemModel?
	@ObservedObject var detailVC = BangumiDetailViewController()

	var body: some View {
			//Text("favorite_status:\(selectedItem?.favorite_status)")
		ScrollViewReader { proxy in
			ScrollView{
				BangumiDetailCoverTextView(
					item: $detailVC.detailItem,
					albireo_favorite_status: $detailVC.albireo_favorite_status,
					bgmtv_favorite_status: $detailVC.bgmtv_favorite_status,
					detailVC: detailVC
				)
				.frame(minHeight: 300,maxHeight: 600)

				Divider()
				if !detailVC.newEPList.isEmpty{
					ForEach(detailVC.newEPList, id: \.ep.id){ item in
						if let n = item.ep.name{
							if !n.isEmpty{
								EPCellView(newEPItem:item,detailVC:detailVC)
									.environmentObject(DownloadManager())
									.environmentObject(OfflinePlaybackManager())
									.padding(10)
							}else{
									//							Text("\(item.ep.episode_no ?? 0). Pending")
									//								.padding(5)
							}
						}
					}
				}else{
					if let item = selectedItem{
						if let name = item.name{
							if !name.isEmpty{
								ProgressView()
							}
						}
					}
				}


			}
			.onAppear(){
				if let item = selectedItem{
					print("BangumiDetailView onAppear")
					detailVC.getBGMDetail(id: item.id){	result in

					}
				}
			}
			.onChange(of: selectedItem, initial: true) { newValue in
				if let item = newValue{
					print("BangumiDetailView onchange")
					detailVC.getBGMDetail(id: item.id){	result in
						if result {
//							if let last = detailVC.newEPList.last?.ep.episode_no{
//								proxy.scrollTo(last.ep.episode_no ?? 0, anchor: .bottom)
//							}
						}
					}

				}
			}
			.refreshable {
				if let item = selectedItem{
					print("BangumiDetailView refreshable")
					detailVC.getBGMDetail(id: item.id){	result in

					}
				}
			}

			.toolbar(content:{
				ToolbarItem(placement: .principal) {
					HStack{
						Spacer()
						BangumiDetailNavTitleView(item: $detailVC.detailItem)
						Spacer()
						BangumiDetailNavItemView(downloadManager: DownloadManager(), bgmItem: $detailVC.detailItem)
					}
				}
			})
			.padding(0)
#if os(iOS) || os(tvOS)
			.fullScreenCover(isPresented:$detailVC.presentVideoView,
							 onDismiss: { },
							 content: {
				if let url = URL(string: detailVC.videoURL){

					VideoPlayerView(url: url,
									seekTime: detailVC.seek,
									bgmItem: $selectedItem,
									ep: detailVC.ep!,
									isOffline: false,
									detailVC: detailVC,
									isBGMTVWatched: detailVC.isBGMEPWatched())
				}else{
					Spacer()
					Text("Error: Video URL is empty")
					Spacer()
					Button(action: {
						detailVC.closePlayer()
					}, label: {
						Text("Close")
					})
					Spacer()

				}
			})
#endif
#if os(macOS)
			.sheet(isPresented:$detailVC.presentVideoView ) {
				if let url = URL(string: detailVC.videoURL){
					ZStack(alignment: .topLeading){
						VideoPlayerView(url: url,
										seekTime: detailVC.seek,
										bgmItem: $selectedItem,
										ep: detailVC.ep!,
										isOffline: false,
										detailVC: detailVC,
										isBGMTVWatched: detailVC.isBGMEPWatched())
						.frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
							//TODO: better close button for macOS
						Button(action: {
							detailVC.closePlayer()
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
						detailVC.closePlayer()
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
			.alert("Please select a source:",isPresented: $detailVC.presentSourceSelectAlert) {
				if let ep = detailVC.ep{
					ForEach(ep.video_files
							?? [], id: \.self){ item in
						Button(item.file_name ?? "unknow source"){
							if let urlstr = item.url{
								detailVC.showVideoView(url: fixPathNotCompete(path: urlstr).addingPercentEncoding(withAllowedCharacters:.urlQueryAllowed)!, seekTime: detailVC.seek)
							}else{
								print("item.url is empty!")
							}
						}
					}
				}
			}
			.alert("Continue from last position?",isPresented: $detailVC.presentContinuePlayAlert) {
				Button("Yes") {
					detailVC.checkVideoSource(ep: detailVC.ep!, seekTime: (detailVC.ep!.watch_progress!.last_watch_position! - 5))
				}
				Button("No, start from beginning"){
					detailVC.checkVideoSource(ep: detailVC.ep!, seekTime: 0)
				}

			}

		}
	}
}

//struct BangumiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailView(bgmID: .constant(""))
//    }
//}
