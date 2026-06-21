import SwiftUI

@main
struct GlyphApp: App {
    @StateObject private var glyphStore = GlyphStore()
    @State private var glyphLinkReady: Bool? = nil
    private let glyphSourceLink = "https://example.com"
    private let glyphCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = glyphLinkReady {
                    if ready {
                        GlyphWebPanel(urlString: glyphSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        GlyphRootView()
                            .environmentObject(glyphStore)
                    }
                } else {
                    GlyphLoadingScreen()
                        .onAppear { performGlyphLaunchCheck() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func performGlyphLaunchCheck() {
        guard let url = URL(string: glyphSourceLink) else {
            glyphLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = GlyphRedirectTracker(checkDomain: glyphCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    glyphLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(glyphCheckDomain) {
                    glyphLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(glyphCheckDomain) {
                    glyphLinkReady = false; return
                }
                if error != nil {
                    glyphLinkReady = false; return
                }
                glyphLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if glyphLinkReady == nil { glyphLinkReady = false }
        }
    }
}

final class GlyphRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
