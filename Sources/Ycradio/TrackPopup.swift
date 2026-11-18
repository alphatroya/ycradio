import AppKit
import SwiftUI

/// Borderless, non-activating panel that floats the current track under the
/// status item and disappears on its own.
@MainActor
final class TrackPopup {
    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(_ title: String, near button: NSStatusBarButton?) {
        guard let button, let buttonWindow = button.window else { return }

        let panel = panel ?? makePanel()
        let hosting = NSHostingView(rootView: TrackView(title: title))
        panel.contentView = hosting
        panel.setContentSize(hosting.fittingSize)

        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        var origin = NSPoint(x: buttonRect.midX - panel.frame.width / 2,
                             y: buttonRect.minY - panel.frame.height - 6)
        if let visible = (buttonWindow.screen ?? NSScreen.main)?.visibleFrame {
            origin.x = min(max(origin.x, visible.minX + 4), visible.maxX - panel.frame.width - 4)
            origin.y = max(origin.y, visible.minY + 4)
        }
        panel.setFrameOrigin(origin)
        panel.orderFrontRegardless()

        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.panel?.orderOut(nil) }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true
        panel.isReleasedWhenClosed = false
        return panel
    }
}

struct TrackView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}
