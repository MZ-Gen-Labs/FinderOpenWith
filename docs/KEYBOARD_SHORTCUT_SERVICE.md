# キーボードショートカット（サービス）機能の記録

この機能は撤去済みです。将来、再度検討するための記録として残します。

## 撤去した理由

Finderの右クリック直下の「VS Codeで開く」を実行するたびに、終了していた`Finder Open With.app`が起動していました。

2026-10-11にログで確認した結果、起動を要求したのはFinderでした。Finderが、アプリの`NSServices`で宣言したサービス`jp.miyazawahayato.FolderLauncher.ServiceProvider`を探し、見つからなかったため`CoreServicesUIAgent`経由でアプリ本体を起動していました。Finder機能拡張のコードはアプリを起動していません。

macOSのサービスは、提供元アプリが終了していれば、利用時にそのアプリを起動する仕組みです。サービスを提供する限り、この起動は避けられません。そこでサービスを削除しました。

## 再導入するときの注意

- サービスを再導入すると、同じ起動が再発する可能性があります。
- 起動を目立たなくするなら、`Info.plist`の`LSUIElement`を`true`にし、起動時にウインドウを出さない方法があります。
- 右クリックメニュー（Finder機能拡張）は、サービスと独立して動作します。
- 共通の起動処理は`Shared/FolderOpening.swift`にあり、撤去していません。

## 撤去前の実装

撤去前の最終コミット：`df40ba2`。`git show <コミット>:App/FolderService.swift`でも参照できます。

### App/Info.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Finder Open WithでVS Codeを開く</string>
			</dict>
			<key>NSMessage</key>
			<string>openInVSCode</string>
			<key>NSPortName</key>
			<string>Finder Open With</string>
			<key>NSSendTypes</key>
			<array>
				<string>public.file-url</string>
				<string>NSFilenamesPboardType</string>
			</array>
			<key>NSSendFileTypes</key>
			<array>
				<string>public.folder</string>
			</array>
			<key>NSRequiredContext</key>
			<dict>
				<key>NSApplicationIdentifier</key>
				<string>com.apple.finder</string>
			</dict>
		</dict>
	</array>
</dict>
</plist>
```

### App/FolderService.swift（`AppDelegate`を含む）

```swift
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
```

### App/AppMain.swift

`@NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate`を`FinderOpenWithApp`に置いていました。`AppDelegate`は`FolderService.swift`内で、`applicationDidFinishLaunching`でサービス提供元を登録していました。

### 利用手順（当時）

1. アプリを`/Applications`に置いて一度起動します。
2. システム設定 → キーボード → キーボードショートカット → サービスで「Finder Open WithでVS Codeを開く」を有効にし、キーを割り当てます。
3. Finderでフォルダーを選んでキーを押します。複数フォルダーに対応し、ファイルやパッケージを含む選択はエラーにしていました。

実装参考：[Appleのサービス実装ガイド](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/providing.html)。
