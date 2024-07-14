//
//  FuncListView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/07/14.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selectedDestination:FuncViewModel?
    var destinations = FuncViewModel.allCases
    var body: some View {
        List(destinations, selection: $selectedDestination) { dest in
            NavigationLink(dest.localizedName, value: dest)
        }
    }
}

//#Preview {
//    FuncListView()
//}
