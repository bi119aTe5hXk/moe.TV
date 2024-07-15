//
//  ViewUtils.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2024/06/09.
//

import Foundation
import SwiftUI

extension View {
  @ViewBuilder func onChange<V: Equatable>(of value: V, initial: Bool, perform action: @escaping (_ newValue: V) -> Void) -> some View {
#if os(iOS)
    if #available(iOS 17.0, *) {
      onChange(of: value, initial: initial) {
        action($1)
      }
    } else if initial {
      onAppear { action(value) }
        .onChange(of: value, perform: action)
    } else {
      onChange(of: value, perform: action)
    }
#endif
#if os(macOS)
    if #available(macOS 14.0, *) {
      onChange(of: value, initial: initial) {
        action($1)
      }
    } else if initial {
      onAppear { action(value) }
        .onChange(of: value, perform: action)
    } else {
      onChange(of: value, perform: action)
    }
#endif
#if os(tvOS)
      if #available(tvOS 17.0, *) {
        onChange(of: value, initial: initial) {
          action($1)
        }
      } else if initial {
        onAppear { action(value) }
          .onChange(of: value, perform: action)
      } else {
        onChange(of: value, perform: action)
      }
#endif
  }
}

struct ExecuteCode : View {
    init( _ codeToExec: () -> () ) {
        codeToExec()
    }
    
    var body: some View {
        EmptyView()
    }
}

#if os(macOS)

typealias UIImage = NSImage

extension Image {
  init(uiImage: UIImage) {
        self.init(nsImage: uiImage)
    }
}

#endif
