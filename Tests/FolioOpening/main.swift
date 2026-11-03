import Cocoa
let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: root) }
for name in ["日本語 space # %.md", "UPPER.MARKDOWN", "other.txt"] {
    try Data("# Test".utf8).write(to: root.appendingPathComponent(name))
}
let folderURL = try FolderService.folioEditorURL(for: [root])
assert(folderURL.scheme == "folio-editor" && folderURL.host == "folder")
assert(URLComponents(url: folderURL, resolvingAgainstBaseURL: false)?.queryItems?.first?.value == root.path)
for name in ["日本語 space # %.md", "UPPER.MARKDOWN"] {
    let file = root.appendingPathComponent(name)
    let target = try FolderService.folioEditorURL(for: [file])
    assert(target == file)
}
let package = root.appendingPathComponent("Example.app", isDirectory: true)
try FileManager.default.createDirectory(at: package, withIntermediateDirectories: true)
for invalid in [[], [root, root], [root.appendingPathComponent("other.txt")], [package], [URL(string: "https://example.com/test.md")!]] {
    do { _ = try FolderService.folioEditorURL(for: invalid); fatalError("Invalid selection accepted") }
    catch { }
}
print("PASS: folder, Markdown, uppercase, Japanese/spaces/symbols, empty/multiple/unsupported/package/non-file selections")
