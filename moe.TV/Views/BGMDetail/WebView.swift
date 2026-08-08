import SwiftUI
#if !os(tvOS)
import Combine
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
#if !os(tvOS) && !os(visionOS)
/// A SwiftUI web container where the caller chooses the mode.
struct WebView: View {
    let url: URL
    var mode: WebViewMode = .inlineWK

    var body: some View {
        switch mode {
        case .inlineWK:
            InlineBrowserView(url: url)
        case .safari:
            #if os(iOS)
            SafariView(url: url)
                .id(url.absoluteString)
            #else
            InlineBrowserView(url: url)
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

#if !os(tvOS) && !os(visionOS)
private final class InlineBrowserModel: ObservableObject {
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var isLoading = false
    @Published private(set) var currentURL: URL?

    private weak var webView: WKWebView?
    private var sourceURL: URL?

    func attach(_ webView: WKWebView, sourceURL: URL) {
        self.webView = webView
        loadSourceIfNeeded(sourceURL)
    }

    func loadSourceIfNeeded(_ url: URL) {
        guard sourceURL != url || webView?.url == nil else { return }
        sourceURL = url
        webView?.load(URLRequest(url: url))
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        if webView?.url == nil, let sourceURL {
            webView?.load(URLRequest(url: sourceURL))
        } else {
            webView?.reload()
        }
    }

    func stopLoading() {
        webView?.stopLoading()
        updateState()
    }

    func updateState() {
        guard let webView else { return }
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        isLoading = webView.isLoading
        currentURL = webView.url
    }
}

private struct InlineBrowserView: View {
    let url: URL
    @StateObject private var model = InlineBrowserModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button(action: model.goBack) {
                    Image(systemName: "chevron.left")
                        .frame(width: 32, height: 32)
                }
                .disabled(!model.canGoBack)
                .help("Back")

                Button(action: model.goForward) {
                    Image(systemName: "chevron.right")
                        .frame(width: 32, height: 32)
                }
                .disabled(!model.canGoForward)
                .help("Forward")

                Button(action: model.isLoading ? model.stopLoading : model.reload) {
                    Image(systemName: model.isLoading ? "xmark" : "arrow.clockwise")
                        .frame(width: 32, height: 32)
                }
                .help(model.isLoading ? "Stop" : "Reload")

                Spacer(minLength: 8)

                ShareLink(item: model.currentURL ?? url) {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 32, height: 32)
                }
                .help("Share")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .frame(minHeight: 42)
            .background(.bar)

            Divider()

            WKInlineWebView(url: url, model: model)
        }
    }
}

private func makeInlineWebView() -> WKWebView {
    let controller = WKUserContentController()
    controller.addUserScript(
        WKUserScript(
            source: """
                (() => {
                    const playbackKeys = new Set([
                        'Space',
                        'ArrowLeft',
                        'ArrowRight',
                        'ArrowUp',
                        'ArrowDown'
                    ]);
                    const blockPlaybackKey = event => {
                        if (!playbackKeys.has(event.code)) return;
                        event.preventDefault();
                        event.stopImmediatePropagation();
                    };
                    window.addEventListener('keydown', blockPlaybackKey, true);
                    window.addEventListener('keyup', blockPlaybackKey, true);
                })();
                """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
    )

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = controller
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.allowsBackForwardNavigationGestures = true
    return webView
}
#endif

#if os(iOS)
private struct WKInlineWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var model: InlineBrowserModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = makeInlineWebView()
        webView.navigationDelegate = context.coordinator
        model.attach(webView, sourceURL: url)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        model.attach(uiView, sourceURL: url)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let model: InlineBrowserModel

        init(model: InlineBrowserModel) {
            self.model = model
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.updateState()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            model.updateState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            model.updateState()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            model.updateState()
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
    @ObservedObject var model: InlineBrowserModel

    func makeNSView(context: Context) -> WKWebView {
        let webView = makeInlineWebView()
        webView.navigationDelegate = context.coordinator
        model.attach(webView, sourceURL: url)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        model.attach(nsView, sourceURL: url)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let model: InlineBrowserModel

        init(model: InlineBrowserModel) {
            self.model = model
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.updateState()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            model.updateState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            model.updateState()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            model.updateState()
        }
    }
}
#endif
