//
//  BangumiDetailView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/10.
//

import SwiftUI
#if os(iOS) || os(tvOS)
import UIKit
#endif

struct BangumiDetailView: View {
	@Binding var selectedItem:BangumiItemModel?
	@StateObject private var detailVC = BangumiDetailViewController()

	private let settingsHandler = SettingsHandler()
	@EnvironmentObject var downloadManager: DownloadManager

	private var shouldShowPresentedPlayerCloseButton: Bool {
		return false
	}

	private var isDetailToolbarReady: Bool {
		detailVC.detailItem != nil && detailVC.isFinished && detailVC.favStatusLoaded
	}

	var body: some View {
		ScrollViewReader { proxy in
			ScrollView{
				BangumiDetailCoverTextView(
					item: $detailVC.detailItem,
					albireo_favorite_status: $detailVC.albireo_favorite_status,
                    bgmtv_favorite_status: $detailVC.bgmtv_favorite_status, favStatusFinished: $detailVC.favStatusLoaded,
					detailVC: detailVC
				)
				.frame(minHeight: 300,maxHeight: 600)

				Divider()
				if !detailVC.newEPList.isEmpty{
					ForEach(detailVC.newEPList, id: \.ep.id){ item in
						let e = item.ep
						if settingsHandler.getHideUnreleaseEPs(){
								//only show released EPs
							if let n = e.name{
								if !n.isEmpty{
									EPCellView(newEPItem:item,detailVC:detailVC)
										.environmentObject(OfflinePlaybackManager())
										.padding(10)
										.id(e.id)
								}
							}

						}else{
								//show all EPs
							EPCellView(newEPItem:item,detailVC:detailVC)
								.environmentObject(OfflinePlaybackManager())
								.padding(10)
								.id(e.id)
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
			.onChange(of: selectedItem, initial: true) { newValue in
				if let item = newValue{
					print("BangumiDetailView onchange by selectedItem")
					detailVC.getBGMDetail(id: item.id){	_ in
					}

				}
			}
			.onChange(of: detailVC.isFinished, initial: true) { newValue in
				if newValue {
					print("BangumiDetailView onchange by isFinished")
					if let id = detailVC.selectedID {
						print("should scroll to \(id)")
						DispatchQueue.main.async {
							withAnimation {
								proxy.scrollTo(id, anchor: .top)
							}
						}
					}
				}
			}
			.onChange(of: detailVC.presentVideoView) { isPresented in
				guard !isPresented, let id = detailVC.selectedID else { return }
				DispatchQueue.main.async {
					withAnimation {
						proxy.scrollTo(id, anchor: .top)
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

			.toolbar {
				ToolbarItem(placement: .principal) {
					if isDetailToolbarReady {
						BangumiDetailNavTitleView(item: $detailVC.detailItem)
					}
				}
				ToolbarItem(placement: .primaryAction) {
					if isDetailToolbarReady {
						BangumiDetailNavItemView(bgmItem: $detailVC.detailItem)
					}
				}
			}
			.padding(0)
#if os(iOS) || os(tvOS)
			.fullScreenCover(isPresented:$detailVC.presentVideoView,
							 onDismiss: { },
							 content: {
				if let url = detailVC.playbackURL{
					ZStack(alignment: .topLeading) {
						Color.black.ignoresSafeArea()
						VideoPlayerView(url: url,
										seekTime: detailVC.seek,
										bgmItem: $selectedItem,
										ep: detailVC.ep,
										isOffline: detailVC.videoIsOffline,
										filename: detailVC.videoFileName,
										detailVC: detailVC,
										isBGMTVWatched: detailVC.isBGMEPWatched(),
										isFinalEpisode: detailVC.isSelectedFinalEpisode)
						if shouldShowPresentedPlayerCloseButton {
							Button(action: {
								detailVC.closePlayer()
							}, label: {
								Image(systemName: "xmark.circle.fill")
									.font(.largeTitle)
									.foregroundColor(.white)
									.shadow(radius: 4)
							})
							.buttonStyle(.plain)
							.padding(20)
						}
					}
				}else{
					VStack {
						Spacer()
						ProgressView()
						Text("Preparing video...")
						Button(action: {
							detailVC.closePlayer()
						}, label: {
							Text("Close")
						})
						Spacer()
					}

				}
			})
#endif
#if os(macOS)
			.sheet(isPresented:$detailVC.presentVideoView ) {
				if let url = detailVC.playbackURL{
					ZStack(alignment: .topLeading){
						VideoPlayerView(url: url,
										seekTime: detailVC.seek,
										bgmItem: $selectedItem,
										ep: detailVC.ep,
										isOffline: detailVC.videoIsOffline,
										filename: detailVC.videoFileName,
										detailVC: detailVC,
										isBGMTVWatched: detailVC.isBGMEPWatched(),
										isFinalEpisode: detailVC.isSelectedFinalEpisode)
						.frame(width: NSApp.keyWindow?.contentView?.bounds.width ?? 500, height: NSApp.keyWindow?.contentView?.bounds.height ?? 500)
							//TODO: better close button for macOS
//						Button(action: {
//							detailVC.closePlayer()
//						}, label: {
//							Image(systemName: "xmark")
//								.resizable()
//								.renderingMode(.template)
//								.frame(width: 15, height: 15)
//								.foregroundColor(.white)
//						}).buttonStyle(.plain)
					}

				}else{
					ProgressView()
					Text("Preparing video...")
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
						Button(item.file_name ?? "\(item.url ?? "unknown source")"){
							if let urlstr = item.url{
								detailVC.prepareAndShowVideoView(url: urlstr, seekTime: detailVC.seek)
							}else{
								print("item.url is empty!")
							}
						}
					}
				}
			}
			.alert("Continue from last position?",
                   isPresented: $detailVC.presentContinuePlayAlert) {
				Button("Continue") {
					detailVC.checkVideoSource(ep: detailVC.ep!, seekTime: (detailVC.ep!.watch_progress!.last_watch_position! - 5))
				}
				Button("Start from beginning", role: .destructive) {
					detailVC.checkVideoSource(ep: detailVC.ep!, seekTime: 0)
				}

			}
			.alert("Playback notice", isPresented: $detailVC.presentPlaybackNoticeAlert) {
				Button("OK", role: .cancel) {
					detailVC.continuePendingPlaybackAfterNotice()
				}
			} message: {
				Text(detailVC.playbackNoticeMessage)
			}
            

		}
	}
}

//struct BangumiDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailView(bgmID: .constant(""))
//    }
//}
