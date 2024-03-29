//
//  BangumiCellView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/06/09.
//

import SwiftUI
import CachedAsyncImage

struct BangumiCellView: View {
    @State var bangumiItem: MyBangumiItemModel
    
    var body: some View {
//        HStack{
//            if let picURLStr = bangumiItem.image{
//                CachedAsyncImage(url: URL(string: picURLStr)){ image in
//                    image.resizable()
//                } placeholder: {
//                    ProgressView()
//                }.frame(width: 45,height: 70,alignment: .leading)
//                    .padding(10)
//            }else{
//                Image(systemName: "exclamationmark.square")
//            }
            
            HStack{
                VStack{
                    HStack{
                        Text(bangumiItem.name ?? "")
                            .font(.subheadline).bold()
                        Spacer()
                    }
                    HStack{
                        Text(bangumiItem.name_cn ?? "")
                        .font(.footnote)
                        Spacer()
                    }
                }
                Spacer()
//                HStack{
                    //BangumiCellStatusTextView(bangumiStatus: bangumiItem.status)
                    
                    //Spacer()
                    BangumiCellUnreadView(unreadCount: bangumiItem.unwatched_count ?? 0)
                    //Text("\( bangumiItem.eps - (bangumiItem.unwatched_count ?? 0)) / \(bangumiItem.eps)").frame(alignment: .leading)
                    //Spacer()
//                }
                
            }.padding(10)
            
//        }.frame(width: 300,height: 80,alignment: .leading)
        
    }
}

//struct BangumiCellView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiCellView(bangumiItem:testBangumiItem2)
//    }
//}
