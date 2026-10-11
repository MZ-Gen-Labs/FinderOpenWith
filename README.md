# Finder Open With

Finderの右クリックメニューに「アプリで開く」を追加する macOS 用の機能拡張です。現在は、選択したフォルダーのコンテキストメニュー直下に「VS Codeで開く」を追加します。

## インストーラー（別のMacへ）

[GitHub Releases](https://github.com/MZ-Gen-Labs/FinderOpenWith/releases/latest)からUniversal版の`.pkg`をダウンロードできます。macOS 13以降のApple Silicon・Intel Macに対応し、アプリを`/Applications`へインストールします。VS Codeは別途必要です。

インストール後にアプリを一度起動し、Finder機能拡張を有効にしてください。詳しくは[インストール手順](docs/INSTALL.md)を参照してください。現時点の配布はアドホック署名のアプリと未署名のインストーラーで、Apple公証は行っていません。

開発環境でインストーラーを再作成するには、Xcodeを用意して次を実行します。

```sh
./scripts/build-installer.sh
```

`dist/`にインストーラー、説明書、SHA-256チェックサムを生成します。ビルド済みアプリやインストーラーはGit管理対象から除外しています。

## ビルド

Xcode で `FinderOpenWith.xcodeproj` を開き、`FinderOpenWith` スキームをビルドします。コマンドラインでは次を実行します。

```sh
xcodebuild -project FinderOpenWith.xcodeproj -scheme FinderOpenWith -configuration Release build
```

## 有効化

1. 生成された `Finder Open With.app` を起動します。
2. 「システム設定」→「一般」→「ログイン項目と機能拡張」→「Finder」で Finder Open With を有効にします。
3. Finderでフォルダーを右クリックすると、メニュー直下に「VS Codeで開く」が表示されます。

対象は実際のユーザーホームフォルダー配下と `/Volumes` 配下です。サンドボックス内の `NSHomeDirectory()` は拡張専用コンテナーを返すため、アカウント情報からホームのパスを取得します。ファイル内容の走査や同期は行いません。

VS Code はアプリの識別子 `com.microsoft.VSCode` から検索するため、インストール先を固定しません。選択された通常のフォルダーに限ってメニューを表示し、VS Code公式の `vscode://file/...` URLで開きます。URLの文字列化には `URLComponents` を使用し、空白や日本語をエンコードします。

VS Codeが外部アプリからのフォルダー起動を確認するダイアログを出した場合は、表示されたパスを確認して「はい」を選択してください。本アプリはその確認設定を変更しません。

## 再確認結果（2026-10-08）

- ビルド・アプリ全体の署名検証：成功。
- 更新版を既存のFinder Open Withにインストールし、Finderを再起動。
- 通常のローカルフォルダーの右クリック直下に「VS Codeで開く」が表示されることを実機で確認。
- そのメニューを選び、VS Codeの確認画面で対象パスを確認後、対象フォルダーと配下のファイルがエクスプローラーに表示されることを確認。
- 全ファイルシステムを対象にする変更は不要。外部ボリューム・クラウド管理フォルダー・複数フォルダー同時起動は今回の実機検証対象外。

公式資料：

- [Apple Finder Sync](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)
- [Appleのホームディレクトリとサンドボックスの説明](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/AccessingFilesandDirectories/AccessingFilesandDirectories.html)
- [VS CodeのURL起動仕様](https://code.visualstudio.com/docs/configure/command-line)

このビルドはローカル検証用のアドホック署名です。配布用の Developer ID 署名・公証は行っていません。メニューから起動するアプリの選択機能はまだ含みません。

## 名称変更（2026-10-08）

- 開発フォルダー・プロジェクト・スキーム名：`FinderOpenWith`。
- アプリとFinder機能拡張の表示名：`Finder Open With`。
- アプリファイル名：`Finder Open With.app`。
- 既存の機能拡張との同一性を保つため、バンドル識別子は従来の値を維持しています。
- 改名後のReleaseビルドとアプリ全体の署名検証を実施。右クリック操作の実機確認結果は上記の改名前の検証記録です。

## キーボードショートカット

キーボードショートカット用のサービスは撤去しました。サービスを提供するアプリは、Finderの右クリック直下の「VS Codeで開く」を実行するたびに、終了していても起動されるためです。経緯と撤去前の実装は[docs/KEYBOARD_SHORTCUT_SERVICE.md](docs/KEYBOARD_SHORTCUT_SERVICE.md)に記録しています。
