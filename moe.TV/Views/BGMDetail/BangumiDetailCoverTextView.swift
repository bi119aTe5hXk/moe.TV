//
//  BangumiDetailCoverTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/20.
//

import SDWebImageSwiftUI
import SwiftUI
struct BangumiDetailCoverTextView: View {
    @Binding var item: BangumiDetailModel?
    @Binding var albireo_favorite_status: Int?
    @Binding var bgmtv_favorite_status: Int?
    @Binding var favStatusFinished: Bool
    @StateObject private var dctVC = BangumiDetailCoverTextViewController()

    var detailVC: BangumiDetailViewController

    var body: some View {
        HStack {
            Spacer()
            if let i = item {
                BangumiDetailCoverMainContent(
                    item: i,
                    albireo_favorite_status: $albireo_favorite_status,
                    bgmtv_favorite_status: $bgmtv_favorite_status,
                    dctVC: dctVC,
                    detailVC: detailVC
                )

                // Attach alerts in a dedicated lightweight view to avoid compiler blowups.
                BangumiDetailCoverAlerts(
                    item: i,
                    albireo_favorite_status: $albireo_favorite_status,
                    bgmtv_favorite_status: $bgmtv_favorite_status,
                    dctVC: dctVC
                )
            }
        }
        .padding(10)
		.onAppear {
			dctVC.setDetailVC(dVC: detailVC)
		}
        .onChange(of: favStatusFinished, initial: false) { finished in
            guard finished else { return }
            dctVC.checkFavConflict(a: albireo_favorite_status, b: bgmtv_favorite_status)
        }
    }
}

// struct BangumiDetailCoverTextView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailCoverTextView(
//            item:
//                    .constant(
//                        BangumiDetailModel(
//                            id: "3032ab99-06a1-4ea9-9df1-c98ab8bfb972",
//                            summary: "这是“闪光”与“黑衣剑士”在被如此称呼之前的故事——某一天，偶然戴上NERvGear的结城明日奈，原本是与网络游戏无缘的初中三年级少女。游戏管理员告知。",
//                            image: "https://lain.bgm.tv/r/400/pic/cover/l/63/24/315375_1ivNC.jpg",
//                            type: 2,
//                            status: 2,
//                            eps: 1
//                        )
//                    ),
//            favorite_status: .constant(3),
//            detailVC: BangumiDetailViewModel()
//        )
//    }
// }

// MARK: - Extracted subviews to keep SwiftUI type-checking fast

private struct BangumiDetailCoverMainContent: View {
    let item: BangumiDetailModel
    @Binding var albireo_favorite_status: Int?
    @Binding var bgmtv_favorite_status: Int?
    @ObservedObject var dctVC: BangumiDetailCoverTextViewController
    let detailVC: BangumiDetailViewController

    var body: some View {
        Group {
            if let coverURL = item.resolvedCoverImageURL {
                WebImage(
                    url: resizedImageURL(
                        fixPathNotCompete(path: coverURL),
                        pixelWidth: 600,
                        pixelHeight: 600
                    )
                ) { image in
                    image.resizable()
                } placeholder: {
                    ZStack {
                        ProgressView {
                            VStack {
                                Text("Loading...")
                            }
                        }
                    }
                }
                .scaledToFit()
                .cornerRadius(10)
                .frame(
                    minWidth: 100,
                    maxWidth: 600,
                    minHeight: 200,
                    maxHeight: 600)
                .padding(10)
            }

            Divider()

            VStack {
                Button(
                    action: {
                        dctVC.setDetailVC(dVC: detailVC)
                        dctVC.toggleChangeFavStatusAlert()
                    },
                    label: {
                        favoriteStatusLayout
                    }
                )

                Divider()

                Text(item.summary ?? "")
                    .lineLimit(10)
                    .padding(10)
                    .frame(
                        minWidth: 100,
                        maxWidth: 600,
                        minHeight: 100,
                        maxHeight: 600)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var favoriteStatusLayout: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack {
                Spacer()
                FavoriteStatusView(
                    albireo_favorite_status: $albireo_favorite_status,
                    bgmtv_favorite_status: $bgmtv_favorite_status
                )
            }
        } else {
            HStack {
                Spacer()
                FavoriteStatusView(
                    albireo_favorite_status: $albireo_favorite_status,
                    bgmtv_favorite_status: $bgmtv_favorite_status
                )
            }
        }
        #else
        HStack {
            Spacer()
            FavoriteStatusView(
                albireo_favorite_status: $albireo_favorite_status,
                bgmtv_favorite_status: $bgmtv_favorite_status
            )
        }
        #endif
    }
}

private struct BangumiDetailCoverAlerts: View {
    let item: BangumiDetailModel
    @Binding var albireo_favorite_status: Int?
    @Binding var bgmtv_favorite_status: Int?
    @ObservedObject var dctVC: BangumiDetailCoverTextViewController

    var body: some View {
        // A lightweight anchor for alert modifiers.
        Color.clear
            .frame(width: 0, height: 0)
            .alert("Change favorite status", isPresented: $dctVC.presentFavStatusSelecter) {
                Button("Wish") { dctVC.changeFavStatusAll(idstr: item.id, bgmid: item.bgm_id, status: 1) }
                Button("Watched") { dctVC.changeFavStatusAll(idstr: item.id, bgmid: item.bgm_id, status: 2) }
                Button("Watching") { dctVC.changeFavStatusAll(idstr: item.id, bgmid: item.bgm_id, status: 3) }
                Button("Pause") { dctVC.changeFavStatusAll(idstr: item.id, bgmid: item.bgm_id, status: 4) }
                Button("Abandoned") { dctVC.changeFavStatusAll(idstr: item.id, bgmid: item.bgm_id, status: 5) }
                Button("Cancel") { dctVC.presentFavStatusSelecter.toggle() }
            }
            .alert(
                "Albireo favorite status has changed",
                isPresented: $dctVC.presentAlbireoFavChangeResultDone
            ) { }
            .alert(
                "Bgm.tv favorite status has changed",
                isPresented: $dctVC.presentBGMFavChangeResultDone
            ) { }
            .alert(isPresented: $dctVC.presentAlbreoFavStatusNilAlert) {
                Alert(
                    title: Text("Albireo favorite status is nil"),
                    message: Text("Set BGM.TV's favorite status to Albreo?"),
                    primaryButton: .default(Text("Yes")) {
                        if let s = bgmtv_favorite_status {
                            dctVC.setAlbreoFavStatus(idstr: item.id, status: s)
                        } else {
                            print("error: bgmtv_favorite_status is nil")
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(isPresented: $dctVC.presentBGMFavStatusNilAlert) {
                Alert(
                    title: Text("BGM.TV favorite status is nil"),
                    message: Text("Set Albreo's favorite status to BGM.TV?"),
                    primaryButton: .default(Text("Yes")) {
                        if let s = albireo_favorite_status {
                            dctVC.setBGMFavStatus(bgmid: item.bgm_id, status: s)
                        } else {
                            print("error: albreo_favorite_status is nil")
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
            .alert(
                "Favorite status conflict has been detected. Choose which one you want to keep.",
                isPresented: $dctVC.presentFavStatusConflictAlert
            ) {
                Button("Albireo") {
                    if let s = albireo_favorite_status {
                        dctVC.setBGMFavStatus(bgmid: item.bgm_id, status: s)
                    }
                }
                Button("Bgm.tv") {
                    if let s = bgmtv_favorite_status{
                        dctVC.setAlbreoFavStatus(idstr: item.id, status: s)
                    }
                }
                Button("Custom status") {
                    dctVC.presentFavStatusSelecter.toggle()
                }
                Button("Cancel") { dctVC.presentFavStatusConflictAlert.toggle() }
            }
    }
}
