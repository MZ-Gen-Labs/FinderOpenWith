import Cocoa

final class FolderService: NSObject {
    static func selectedURLs(from pasteboard: NSPasteboard) -> [URL] {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        if !urls.isEmpty { return urls }
        // Older Finder service senders use the filename-list pasteboard type.
        let paths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] ?? []
        return paths.map { URL(fileURLWithPath: $0) }
    }

    @objc(openInVSCode:userData:error:)
    func openInVSCode(_ pasteboard: NSPasteboard, userData: String?, error errorPointer: AutoreleasingUnsafeMutablePointer<NSString?>) {
        do {
            try FolderOpening.openInVSCode(Self.selectedURLs(from: pasteboard))
        } catch {
            errorPointer.pointee = error.localizedDescription as NSString
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let folderService = FolderService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = folderService
        NSUpdateDynamicServices()
    }
}
