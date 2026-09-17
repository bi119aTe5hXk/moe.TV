//
//  BangumiDetailCoverTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/20.
//

import SDWebImageSwiftUI
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct BangumiDetailCoverTextView: View {
    @Binding var item: BangumiDetailModel?
    @Binding var albireo_favorite_status: Int?
    @Binding var bgmtv_favorite_status: Int?
    @Binding var favStatusFinished: Bool
    @StateObject private var dctVC = BangumiDetailCoverTextViewController()

    var detailVC: BangumiDetailViewController

    var body: some View {
        Group {
            if let item {
#if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    VStack(spacing: 0) {
                        mainContent(for: item)
                    }
                } else {
                    regularContent(for: item)
                }
#else
                regularContent(for: item)
#endif
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
        .onAppear {
            dctVC.setDetailVC(dVC: detailVC)
        }
        .onChange(of: favStatusFinished, initial: false) { finished in
            guard finished else { return }
            dctVC.checkFavConflict(a: albireo_favorite_status, b: bgmtv_favorite_status)
        }
    }

    @ViewBuilder
    private func regularContent(for item: BangumiDetailModel) -> some View {
        HStack {
            Spacer(minLength: 0)
            mainContent(for: item)
        }
    }

    @ViewBuilder
    private func mainContent(for item: BangumiDetailModel) -> some View {
        BangumiDetailCoverMainContent(
            item: item,
            albireo_favorite_status: $albireo_favorite_status,
            bgmtv_favorite_status: $bgmtv_favorite_status,
            dctVC: dctVC,
            detailVC: detailVC
        )

        // Attach alerts in a dedicated lightweight view to avoid compiler blowups.
        BangumiDetailCoverAlerts(
            item: item,
            albireo_favorite_status: $albireo_favorite_status,
            bgmtv_favorite_status: $bgmtv_favorite_status,
            dctVC: dctVC
        )
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
						pixelHeight: 848,
						preserveAspectRatio: true
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
                        detailVC.showCollectionEditor(defaultStatus: detailVC.preferredCollectionStatus)
                    },
                    label: {
                        favoriteStatusLayout
                    }
                )
                .disabled(!detailVC.favStatusLoaded)

				if let rating = detailVC.collectionRating, rating > 0 {
					HStack {
						Text("Rating")
						Text("\(rating)/10")
						Spacer(minLength: 0)
					}
					.frame(maxWidth: 600)
				}
				if let comment = detailVC.collectionComment, !comment.isEmpty {
					VStack(alignment: .leading, spacing: 4) {
						Text("Comment")
							.font(.caption)
							.foregroundStyle(.secondary)
						Text(comment)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.frame(maxWidth: 600, alignment: .leading)
				}

                Divider()

                Text(item.summary ?? "")
                    .lineLimit(10)
                    .padding(10)
                    .frame(
                        minWidth: 100,
                        maxWidth: 600,
                        minHeight: 100,
                        maxHeight: 600)

                if !isPhone {
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var favoriteStatusLayout: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack {
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

    private var isPhone: Bool {
#if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
#else
        false
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
                    if let detailVC = dctVC.detailVC {
                        detailVC.showCollectionEditor(defaultStatus: detailVC.preferredCollectionStatus)
                    }
                }
                Button("Cancel") { dctVC.presentFavStatusConflictAlert.toggle() }
            }
    }
}

struct BangumiCollectionEditorView: View {
    let item: BangumiDetailModel
    @ObservedObject var detailVC: BangumiDetailViewController
    @Environment(\.dismiss) private var dismiss
    @State private var status: Int
    @State private var rating: Int
    @State private var comment: String
    @State private var commentWasEdited = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(item: BangumiDetailModel, detailVC: BangumiDetailViewController) {
        self.item = item
        self.detailVC = detailVC
        _status = State(initialValue: detailVC.collectionEditorInitialStatus)
		_rating = State(initialValue: detailVC.collectionRating ?? 0)
		_comment = State(initialValue: detailVC.collectionComment ?? "")
    }

    private var supportsReview: Bool {
        SettingsHandler().getAlbireoAuthMode() == .albireoV2OAuth || isBGMTVlogined()
    }

    private var editableComment: Binding<String> {
        Binding(
            get: { comment },
            set: { comment = $0; commentWasEdited = true }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.name ?? item.name_cn ?? "")
                        .font(.headline)
                        .lineLimit(2)
                }
                Section {
                    Picker("Status", selection: $status) {
                        Text("Wish").tag(1)
                        Text("Watched").tag(2)
                        Text("Watching").tag(3)
                        Text("Pause").tag(4)
                        Text("Abandoned").tag(5)
                    }
                }

                if supportsReview {
                    Section("Rating") {
                        Picker("Rating", selection: $rating) {
                            Text("Leave rating unchanged").tag(0)
                            ForEach(1...10, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                    }
                    Section("Comment") {
                        #if os(tvOS)
                        TextField("Comment", text: editableComment)
                        #else
                        TextEditor(text: editableComment)
                            .frame(minHeight: 100)
                        #endif
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Collection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        detailVC.saveCollection(
            status: status,
            rating: supportsReview && rating > 0 ? rating : nil,
            comment: supportsReview && (commentWasEdited || !trimmedComment.isEmpty) ? trimmedComment : nil
        ) { success, message in
            isSaving = false
            if success {
                dismiss()
            } else {
                errorMessage = message
            }
        }
    }
}
