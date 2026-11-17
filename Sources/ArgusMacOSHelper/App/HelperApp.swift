import AppKit
import ArgusCore

@main
@available(macOS 26.0, *)
struct HelperApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}