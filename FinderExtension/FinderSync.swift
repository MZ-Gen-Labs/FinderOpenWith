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

    // Folder actions are provided by macOS Services in both local and cloud folders.
    // Keep the extension identity for existing installations, without duplicate items.
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        nil
    }
}
