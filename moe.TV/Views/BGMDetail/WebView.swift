import SwiftUI
#if !os(tvOS)
import WebKit
#endif
#if os(iOS)
import SafariServices
#endif

// MARK: - Public API (choose how to show web content)

/// Pick how to show a URL.
/// - `.inlineWK`: Embeddable WKWebView (best for split view layouts).
/// - `.safari`: iOS in-app Safari view controller. On macOS this falls back to inline WKWebView.
enum WebViewMode {
    case inlineWK
    case safari
}
#if !os(tvOS)
/// A SwiftUI web container where the caller chooses the mode.
struct WebView: View {
    let url: URL
    var mode: WebViewMode = .inlineWK

    var body: some View {
        switch mode {
        case .inlineWK:
            WKInlineWebView(url: url)
        case .safari:
            #if os(iOS)
            SafariView(url: url)
                .id(url.absoluteString)
            #else
            WKInlineWebView(url: url)
            #endif
        }
    }
}
#endif
#if os(iOS)
// MARK: - Sheet presenter for Safari

/// Wrapper so we can present Safari via `.sheet(item:)`.
struct SafariURL: Identifiable, Equatable {
    let url: URL
    var id: String { url.absoluteString }
}

extension View {
    /// Present an in-app Safari sheet (uses the system Safari cookie jar).
    func safariSheet(url: Binding<SafariURL?>) -> some View {
        self.sheet(item: url) { item in
            SafariView(url: item.url)
        }
    }
}
#endif

// MARK: - Inline WKWebView (embeddable)

#if os(iOS)
private struct WKInlineWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
}

// MARK: - In-app Safari (cookie-sharing)

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
#elseif os(macOS)
private struct WKInlineWebView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.url != url {
            nsView.load(URLRequest(url: url))
        }
    }
}
#endif
