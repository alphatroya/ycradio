import AppKit

// Top-level code always runs on the main thread; assumeIsolated tells the
// compiler what it cannot prove on its own.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
