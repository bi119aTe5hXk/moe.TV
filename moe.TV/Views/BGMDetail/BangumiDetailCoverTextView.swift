//
//  BangumiDetailCoverTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/20.
//

import SwiftUI
import SDWebImageSwiftUI
struct BangumiDetailCoverTextView: View {
    @Binding var item:BangumiDetailModel?
    @Binding var albireo_favorite_status:Int?
	@Binding var bgmtv_favorite_status:Int?
	@ObservedObject var dctVC = BangumiDetailCoverTextViewController()

	var detailVC:BangumiDetailViewController

    var body: some View {
        HStack{
            Spacer()
            if let i = item{
                if let coverURL = i.image{
					WebImage(url: URL(string: coverURL)){image in
						image.resizable()
					}placeholder: {
						ZStack {

							ProgressView() {
								VStack {
									Text("Loading...")

										//											Text("\(progress) %")
								}
							}
						}
					}
					

						.scaledToFit()
						.cornerRadius(10)
						.frame(
							minWidth: 100,
							maxWidth:600,
							minHeight: 200,
							maxHeight: 600)
					
//                    GeometryReader { geo in
                        //                        CachedAsyncImage(url: URL(string: coverURL)){ image in
                        //                            image.resizable()
                        //                                .scaledToFit()
                        //                                .cornerRadius(10)
                        //                        } placeholder: {
                        //                            ProgressView()
                        //                        }


//                        CachedAsyncImage(
//                            url: coverURL,
//                            placeholder: { progress in
//                                // Create any view for placeholder (optional).
//                                ZStack {
//                                    
//                                    ProgressView() {
//                                        VStack {
//                                            Text("Loading...")
//                                            
//                                            Text("\(progress) %")
//                                        }
//                                    }
//                                }
//                            },
//                            image: {
//                                // Customize image.
//                                Image(uiImage: $0)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .cornerRadius(10)
//                                    .frame(
//                                        minWidth: 100,
//                                        maxWidth:600,
//                                        minHeight: 200,
//                                        maxHeight: 600)
//                            }
//                        )
//                        .frame(width: geo.size.width,
//                               height: geo.size.height,
//                               alignment: .center)
//                    }
                    .padding(10)
                }
                
				Divider()
                //Spacer()
				VStack{

					Button(
						action: {
							dctVC.setDetailVC(dVC: detailVC)
						dctVC.toggleChangeFavStatusAlert()
					},
						label: {
#if os(iOS)
							if UIDevice.current.userInterfaceIdiom == .phone {
								VStack{
									Spacer()
									FavoriteStatusView(
										albireo_favorite_status: $albireo_favorite_status,
										bgmtv_favorite_status: $bgmtv_favorite_status
									)
								}
							}else{
								HStack{
									Spacer()
									FavoriteStatusView(
										albireo_favorite_status: $albireo_favorite_status,
										bgmtv_favorite_status: $bgmtv_favorite_status
									)
								}
							}
#else
							HStack{
								Spacer()
								FavoriteStatusView(
									albireo_favorite_status: $albireo_favorite_status,
									bgmtv_favorite_status: $bgmtv_favorite_status
								)
							}
#endif
							
						})


					Divider()

					Text((i.summary ?? ""))
						.lineLimit(10)
						.padding(10)
						.frame(
							minWidth: 100,
							maxWidth:600,
							minHeight: 100,
							maxHeight: 600)

					Spacer()
				}


				.alert("Change favorite status",isPresented: $dctVC.presentFavStatusSelecter) {
					Button("Wish"){
						dctVC.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 1)
					}
					Button("Watched"){
						dctVC.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 2)
					}
					Button("Watching"){
						dctVC.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 3)
					}
					Button("Pause"){
						dctVC.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 4)
					}
					Button("Abandoned"){
						dctVC.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 5)
					}
					Button("Cancel"){
						dctVC.presentFavStatusSelecter.toggle()
					}
				}
				.alert(
					"Albireo favorite status has changed",
					isPresented: $dctVC.presentAlbireoFavChangeResultDone
				){ }
				.alert(
						"Bgm.tv favorite status has changed",
						isPresented: $dctVC.presentBGMFavChangeResultDone
				){ }


            }
    }.padding(10)
            
            
    }
}

//struct BangumiDetailCoverTextView_Previews: PreviewProvider {
//    static var previews: some View {
//		BangumiDetailCoverTextView(
//			item: 
//					.constant(
//						BangumiDetailModel(
//							id: "3032ab99-06a1-4ea9-9df1-c98ab8bfb972",
//							summary: "这是“闪光”与“黑衣剑士”在被如此称呼之前的故事——某一天，偶然戴上NERvGear的结城明日奈，原本是与网络游戏无缘的初中三年级少女。游戏管理员告知。",
//							image: "https://lain.bgm.tv/r/400/pic/cover/l/63/24/315375_1ivNC.jpg",
//							type: 2,
//							status: 2,
//							eps: 1
//						)
//					),
//			favorite_status: .constant(3),
//			detailVC: BangumiDetailViewModel()
//		)
//    }
//}
