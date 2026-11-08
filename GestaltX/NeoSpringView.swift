// SPDX-License-Identifier: GPL-3.0-only
// Adapted from Nouvborne/Ketamine's GPL-3.0 respring implementation.
// Original WebKit technique: neonmodder123; Swift implementation: skadz108.
// NeoSpring project: https://github.com/rooootdev/neospring
// GestaltX changes (2026): corrected raw-string HTML escaping and random-data
// request size; added cancellation, timeout and Simulator exclusion.
import SwiftUI
import WebKit

struct NeoSpringView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var running = false
    @State private var timedOut = false
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            #if !targetEnvironment(simulator)
            if running { NeoSpringWebView().brightness(-1).allowsHitTesting(false).accessibilityHidden(true) }
            #endif
            VStack(spacing: 18) {
                if !timedOut { ProgressView().tint(.white).controlSize(.large) }
                Text(L(timedOut ? "Respring did not finish." : "Refreshing SpringBoard…")).font(.headline)
                Text(L(timedOut ? "This OS build may not support the technique. You can close this screen and try a manual restart later." : "Your device may briefly return to the Lock Screen."))
                    .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.65))
                Button(L(timedOut ? "Close" : "Cancel")) { running = false; dismiss() }
                    .buttonStyle(.bordered).tint(.white).padding(.top, 8)
            }.foregroundStyle(.white).padding(32).frame(maxWidth: 440)
        }
        .task {
            #if targetEnvironment(simulator)
            timedOut = true
            #else
            do {
                try await Task.sleep(for: .milliseconds(250))
                running = true
                try await Task.sleep(for: .seconds(20))
                running = false; timedOut = true
            } catch { running = false }
            #endif
        }
        .onDisappear { running = false }
    }
}
private struct NeoSpringWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.loadHTMLString(Self.document, baseURL: nil)
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
    static func dismantleUIView(_ view: WKWebView, coordinator: ()) {
        view.stopLoading()
        view.loadHTMLString("", baseURL: nil)
    }
    private static let document = #"""
    <!DOCTYPE html>
    <html>
      <body>
        <iframe id="frame" srcdoc="" sandbox="allow-forms allow-modals allow-orientation-lock allow-pointer-lock allow-popups allow-presentation allow-scripts"></iframe>
        <script>
          const frame = document.getElementById('frame');
          const payload = `
            <html>
              <body>
                <script>
                  const container = document.createElement('div');
                  container.style.cssText = 'perspective: 1px; perspective-origin: 9999999% 9999999%;';
                  document.body.appendChild(container);

                  for (let i = 0; i < 500; i++) {
                    const layer = document.createElement('div');
                    layer.style.cssText = 'position: absolute; width: 100vw; height: 100vh; backdrop-filter: blur(100px); -webkit-backdrop-filter: blur(100px); transform: translate3d(100000px, 100000px, ' + i + 'px) rotateY(90deg);';
                    container.appendChild(layer);
                  }

                  setInterval(() => {
                    navigator.share({ title: 'R', text: 'R'.repeat(100000) }).catch(() => {});
                    const bytes = new Uint8Array(1024 * 1024 * 10);
                    crypto.getRandomValues(bytes.subarray(0, 65536));
                  }, 0);
                <\/script>
              </body>
            </html>
          `;
          frame.srcdoc = payload;
        </script>
      </body>
    </html>
    """#
}
