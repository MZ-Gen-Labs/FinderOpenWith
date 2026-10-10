import Cocoa
import FinderSync
import Darwin
import OSLog

final class FinderSync: FIFinderSync {
    private let logger = Logger(subsystem: "jp.miyazawahayato.FolderLauncher", category: "FinderExtension")

    override init() {
        super.init()
        let volumes = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        // Foundation home APIs resolve to the extension's container in App Sandbox.
        // The account record supplies the actual home path, without granting file access.
        guard let account = getpwuid(getuid()), let homePath = account.pointee.pw_dir else {
            FIFinderSyncController.default().directoryURLs = [volumes]
            logger.error("Could not resolve the user home directory")
            return
        }
        let home = URL(fileURLWithPath: String(cString: homePath), isDirectory: true)
        FIFinderSyncController.default().directoryURLs = [home, volumes]
        logger.notice("Registered home scope: \(home.path, privacy: .public)")
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForItems else { return nil }
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        guard !urls.isEmpty, urls.allSatisfy(FolderOpening.isFolder) else { return nil }
        let menu = NSMenu(title: "")
        let item = NSMenuItem(title: "VS Codeで開く", action: #selector(openInVSCode(_:)), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        return menu
    }

    @objc private func openInVSCode(_ sender: NSMenuItem) {
        let urls = FIFinderSyncController.default().selectedItemURLs() ?? []
        do {
            try FolderOpening.openInVSCode(urls)
        } catch {
            logger.error("Opening folders failed: \(error.localizedDescription, privacy: .public)")
            NSSound.beep()
        }
    }
}
