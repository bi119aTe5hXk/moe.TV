//
//  WebView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2025/06/22.
//

import SwiftUI


#if os(iOS)
import WebKit
struct WebView: UIViewRepresentable {
	let url: URL

	func makeUIView(context: Context) -> WKWebView {
		return WKWebView()
	}

	func updateUIView(_ uiView: WKWebView, context: Context) {
		uiView.load(URLRequest(url: url))
	}
}
#elseif os(macOS)
import WebKit
struct WebView: NSViewRepresentable {
	let url: URL

	func makeNSView(context: Context) -> WKWebView {
		return WKWebView()
	}

	func updateNSView(_ nsView: WKWebView, context: Context) {
		nsView.load(URLRequest(url: url))
	}
}
#endif
