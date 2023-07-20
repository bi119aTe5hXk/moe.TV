//
//  BangumiDetailCoverTextView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2023/07/20.
//

import SwiftUI
import CachedAsyncImage
struct BangumiDetailCoverTextView: View {
    @State var item:BangumiDetailModel
    var body: some View {
        HStack{
            Spacer()
            
            if let coverURL = item.image{
                CachedAsyncImage(url: URL(string: coverURL)){ image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100,height: 150,alignment: .center)
                .padding(10)
            }
            
            Spacer()
            
            Text((item.summary ?? "").prefix(250))
                .frame(maxWidth: 500)
            
            Spacer()
            
        }.padding(10)
    }
}

//struct BangumiDetailCoverTextView_Previews: PreviewProvider {
//    static var previews: some View {
//        BangumiDetailCoverTextView()
//    }
//}
