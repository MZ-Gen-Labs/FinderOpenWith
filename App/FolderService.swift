import Cocoa

final class FolderService: NSObject {
    static func selectedURLs(from pasteboard: NSPasteboard) -> [URL] {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        if !urls.isEmpty { return urls }
        // Older Finder service senders use the filename-list pasteboard type.
        let paths = pasteboard.propertyList(forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] ?? []
        return paths.map { URL(fileURLWithPath: $0) }
    }

    // Services remain available in File Provider folders where Finder Sync menus
    // may not be supplied. Use the same validation and alerts as the extension.
    @objc(openInObsidian:userData:error:)
    func openInObsidian(_ pasteboard: NSPasteboard, userData: String?, error errorPointer: AutoreleasingUnsafeMutablePointer<NSString?>) {
        ObsidianOpening.open(Self.selectedURLs(from: pasteboard))
    }

    @objc(openInFolioEditor:userData:error:)
    func openInFolioEditor(_ pasteboard: NSPasteboard, userData: String?, error errorPointer: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let url: URL
        do {
            url = try Self.folioEditorURL(for: Self.selectedURLs(from: pasteboard))
        } catch {
            errorPointer.pointee = error.localizedDescription as NSString
            return
        }
        guard let application = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "local.mdeditor.desktop") else {
            errorPointer.pointee = "Folio Editorが見つかりません。"
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: application, configuration: configuration) { _, error in
            if let error { DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Folio Editorで開けません"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            } }
        }
    }

    // Files use the normal document-open event; folders use the editor's explorer URL.
    static func folioEditorURL(for selection: [URL]) throws -> URL {
        guard selection.count == 1, let selected = selection.first, selected.isFileURL else {
            throw FolioOpeningError.invalidSelection
        }
        if FolderOpening.isFolder(selected) {
            var components = URLComponents()
            components.scheme = "folio-editor"
            components.host = "folder"
            components.queryItems = [URLQueryItem(name: "path", value: selected.path)]
            guard let url = components.url else { throw FolioOpeningError.invalidSelection }
            return url
        }
        let values = try selected.resourceValues(forKeys: [.isRegularFileKey])
        guard values.isRegularFile == true,
              ["md", "markdown"].contains(selected.pathExtension.lowercased()) else {
            throw FolioOpeningError.invalidSelection
        }
        return selected
    }

    enum FolioOpeningError: LocalizedError {
        case invalidSelection
        var errorDescription: String? {
            "通常のフォルダー、またはMarkdownファイル（.md / .markdown）を1つ選択してください。"
        }
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

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            guard url.scheme == "finder-open-with", url.host == "obsidian",
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { continue }
            let folders = (components.queryItems ?? []).filter { $0.name == "folder" }
                .compactMap { $0.value }.map { URL(fileURLWithPath: $0, isDirectory: true) }
            ObsidianOpening.open(folders)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = folderService
        NSUpdateDynamicServices()
    }
}

// Runs only in the containing app. Never modifies Obsidian's registry or vaults.
enum ObsidianOpening {
    struct Registry: Decodable {
        struct Vault: Decodable { let path: String }
        let vaults: [String: Vault]
    }

    static func links(for folders: [URL], registryData: Data) throws -> [URL] {
        guard !folders.isEmpty, folders.allSatisfy({ FolderOpening.isFolder($0.resolvingSymlinksInPath()) }) else {
            throw Failure(message: "FinderでVaultのフォルダーを選択してください。")
        }
        let registry = try JSONDecoder().decode(Registry.self, from: registryData)
        return try folders.map { folder in
            let canonical = folder.resolvingSymlinksInPath().standardizedFileURL
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: folder.appendingPathComponent(".obsidian").path,
                                                isDirectory: &isDirectory), isDirectory.boolValue else {
                throw Failure(message: "「\(folder.lastPathComponent)」はVaultではありません。直下に.obsidianフォルダーが必要です。")
            }
            guard let id = registry.vaults.first(where: {
                URL(fileURLWithPath: $0.value.path, isDirectory: true)
                    .resolvingSymlinksInPath().standardizedFileURL == canonical
            })?.key else {
                throw Failure(message: "「\(folder.lastPathComponent)」はObsidianに登録されていません。先にObsidianの「保管庫としてフォルダを開く」で登録してください。")
            }
            var link = URLComponents()
            link.scheme = "obsidian"
            link.host = "open"
            link.queryItems = [URLQueryItem(name: "vault", value: id)]
            guard let url = link.url else { throw Failure(message: "VaultのURLを作成できませんでした。") }
            return url
        }
    }

    static func open(_ folders: [URL]) {
        do {
            let registry = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/obsidian/obsidian.json")
            let data: Data
            do { data = try Data(contentsOf: registry) }
            catch { throw Failure(message: "ObsidianのVault登録情報を読み取れません。ObsidianでVaultを登録してから再実行してください。") }
            let urls: [URL]
            do { urls = try links(for: folders, registryData: data) }
            catch let error as Failure { throw error }
            catch { throw Failure(message: "ObsidianのVault登録情報を確認できませんでした。") }
            guard let app = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "md.obsidian") else {
                throw Failure(message: "Obsidianが見つかりません。Obsidianをインストールしてください。")
            }
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open(urls, withApplicationAt: app, configuration: configuration) { _, error in
                if let error { DispatchQueue.main.async { alert(error.localizedDescription) } }
            }
        } catch { alert(error.localizedDescription) }
    }

    private static func alert(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Obsidianで開けません"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
}
