//
//  BangumiDetailCoverTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/20.
//

import SwiftUI
import CachedAsyncImage
struct BangumiDetailCoverTextView: View {
    @Binding var item:BangumiDetailModel?
    @Binding var albireo_favorite_status:Int?
	@Binding var bgmtv_favorite_status:Int?
    @ObservedObject var dctVM = BangumiDetailCoverTextViewModel()

	var detailVM:BangumiDetailViewModel

    var body: some View {
        HStack{
            Spacer()
            if let i = item{
                if let coverURL = i.image{
                    GeometryReader { geo in
                        //                        CachedAsyncImage(url: URL(string: coverURL)){ image in
                        //                            image.resizable()
                        //                                .scaledToFit()
                        //                                .cornerRadius(10)
                        //                        } placeholder: {
                        //                            ProgressView()
                        //                        }
                        CachedAsyncImage(
                            url: coverURL,
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
                                    .frame(
                                        minWidth: 100,
                                        maxWidth:600,
                                        minHeight: 200,
                                        maxHeight: 600)
                            }
                        )
                        .frame(width: geo.size.width,
                               height: geo.size.height,
                               alignment: .center)
                    }
                    .padding(10)
                }
                
				Divider()
                //Spacer()
				VStack{

					Button(
action: {
						dctVM.setDetailVM(dVM: detailVM)
						dctVM.toggleChangeFavStatusAlert()
					},
 label: {
						HStack{
							Spacer()
							VStack{
								Text("Albireo Status")
								BGMStatusTextView(status: $albireo_favorite_status)
									.padding(10)
							}
							Spacer()
							Divider()
							Spacer()
							VStack{
								Text("Bgm.tv Status")
								BGMStatusTextView(
									status:$bgmtv_favorite_status
								)
									.padding(10)
							}
							Spacer()
						}


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


				.alert("Change favorite status",isPresented: $dctVM.presentFavStatusSelecter) {
					Button("Wish"){
						dctVM.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 1)
					}
					Button("Watched"){
						dctVM.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 2)
					}
					Button("Watching"){
						dctVM.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 3)
					}
					Button("Pause"){
						dctVM.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 4)
					}
					Button("Abandoned"){
						dctVM.changeFavStatus(idstr: i.id, bgmid: i.bgm_id, status: 5)
					}
					Button("Cancel"){
						dctVM.presentFavStatusSelecter.toggle()
					}
				}
				.alert(
					"Albireo favorite status has changed",
					isPresented: $dctVM.presentAlbireoFavChangeResultDone
				){ }
				.alert(
						"Bgm.tv favorite status has changed",
						isPresented: $dctVM.presentBGMFavChangeResultDone
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
//			detailVM: BangumiDetailViewModel()
//		)
//    }
//}
