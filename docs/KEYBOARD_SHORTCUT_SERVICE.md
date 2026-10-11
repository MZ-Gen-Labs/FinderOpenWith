# キーボードショートカット（サービス）機能と、アプリ起動の関係

2026-10-11にいったん撤去し、同日に復活しました。経緯を記録します。

## 経緯

- Finderの右クリック直下の「VS Codeで開く」を実行するたびに、終了していた`Finder Open With.app`が起動していました。
- ログで確認した結果、起動を要求したのはFinderでした。Finderがアプリの`NSServices`のサービス`jp.miyazawahayato.FolderLauncher.ServiceProvider`を探し、見つからないため、`CoreServicesUIAgent`経由でアプリを起動していました。Finder機能拡張のコードはアプリを起動していません。
- サービスを撤去するとアプリは起動しなくなりましたが、GoogleドライブやiCloud Driveなど、File Provider管理のフォルダーでは、Finder機能拡張のメニューが出ません。そこでは、サービス経由の項目だけが使えていました。
- そのため、サービスを復活し、`LSUIElement`でDockアイコンとウインドウを出さないようにしました。起動は避けられませんが、見えません。

## 注意

- 同じバンドル識別子の古いビルドが残っていると、Finderがそちらを起動することがあります。`lsregister -u`で登録を解除しても、Spotlightが再発見します。古いビルドは削除し、`pbs -flush`と`pbs -update`でサービスのキャッシュを更新してください。
- サービスを再び撤去する場合は、本ファイルの「撤去前の実装」を参照してください。

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
