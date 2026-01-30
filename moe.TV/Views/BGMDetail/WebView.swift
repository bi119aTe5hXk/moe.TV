//
//  WebView.swift
//  moe.TV
//
//  Created by bi119aTe5hXk on 2025/06/22.
//

import SwiftUI


#if os(iOS)
import WebKit
import SafariServices

/// Show all URLs using SFSafariViewController so the user benefits from the system Safari cookie jar.
struct WebView: View {
    let url: URL

    var body: some View {
        SafariView(url: url)
            // Force recreation when URL changes; SFSafariViewController doesn't "navigate" via update.
            .id(url.absoluteString)
    }
}

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Navigation is handled by recreating the controller via .id(...) in WebView.
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
