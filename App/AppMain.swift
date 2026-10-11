import SwiftUI

// The app only provides the Finder service. Finder launches it on demand,
// so it has no Dock icon (LSUIElement) and opens no window.
@main
struct FinderOpenWithApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}
