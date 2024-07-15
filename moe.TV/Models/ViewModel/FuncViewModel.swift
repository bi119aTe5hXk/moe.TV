//
//  FuncViewModel.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/07/14.
//

import SwiftUI

enum FuncViewModel: Int, Hashable, CaseIterable, Identifiable, Codable{
    var id: Int { rawValue }
    
    case mybangumi
    case onair
    case search
    case allbangumi
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .mybangumi:
            return "MyBangumi"
        case .allbangumi:
             return "AllBangumi"
        case .onair:
            return "OnAir"
        case .search:
             return "Search"
        }
    }
}
