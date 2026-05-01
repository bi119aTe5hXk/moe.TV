//
//  FuncListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/07/14.
//

import SwiftUI

struct SidebarView: View {
	var destinations = FuncViewModel.allCases
//#if !os(tvOS)
    @Binding var selectedDestination:FuncViewModel?
    var body: some View {
        List(destinations, selection: $selectedDestination) { dest in
            NavigationLink(dest.localizedName, value: dest)
               
        }
		
    }
//#else
//	@Binding var navigationPath: [FuncViewModel]
//	var body: some View {
//		List(destinations, id: \.self) { dest in
//			Button(action: {
//				print("navigating to \(dest.localizedName)")
//				navigationPath.append(dest)
//			}) {
//				Text(dest.localizedName)
//			}
//		}
//	}
//#endif

}

//#Preview {
//    FuncListView()
//}
