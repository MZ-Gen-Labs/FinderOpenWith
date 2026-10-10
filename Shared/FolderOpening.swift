import Cocoa
import OSLog

// Both the Finder extension and the app service use the same folder-opening path.
enum FolderOpening {
    private static let logger = Logger(subsystem: "jp.miyazawahayato.FolderLauncher", category: "FolderOpening")

    static func isFolder(_ url: URL) -> Bool {
        guard url.isFileURL else { return false }
        if let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]) {
            return values.isDirectory == true && values.isPackage != true
        }
        // Finder supplies directory URLs even when the sandbox cannot inspect them.
        return url.hasDirectoryPath && url.pathExtension != "app"
    }

    static func links(for folders: [URL]) throws -> [URL] {
        guard !folders.isEmpty, folders.allSatisfy(isFolder) else {
            throw OpeningError.invalidSelection
        }
        return try folders.map { folder in
            var components = URLComponents()
            components.scheme = "vscode"
            components.host = "file"
            components.path = folder.path
            guard let link = components.url else { throw OpeningError.invalidSelection }
            return link
        }
    }

    static func openInVSCode(_ folders: [URL]) throws {
        let urls = try links(for: folders)
        guard let application = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.microsoft.VSCode") else {
            throw OpeningError.applicationMissing
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(urls, withApplicationAt: application, configuration: configuration) { _, error in
            if let error {
                logger.error("Opening folders failed: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async { NSSound.beep() }
            } else {
                logger.notice("Opened \(folders.count) folder(s) in VS Code")
            }
        }
    }

    enum OpeningError: LocalizedError {
        case invalidSelection, applicationMissing

        var errorDescription: String? {
            switch self {
            case .invalidSelection: return "Finderで通常のフォルダーを選択してください。"
            case .applicationMissing: return "VS Codeが見つかりません。VS Codeをインストールしてください。"
            }
        }
    }
}
