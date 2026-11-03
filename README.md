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

### リリースの自動ビルド

`v`で始まるタグをpushすると、GitHub Actions（`.github/workflows/release.yml`）が同じスクリプトでインストーラーを作成し、そのタグのReleaseに添付します。Releaseがなければ自動で作成します。

```sh
git tag v1.1.0
git push origin v1.1.0
```

リリース前に`MARKETING_VERSION`（`FinderOpenWith.xcodeproj`）を更新してください。ファイル名は`FinderOpenWith-<MARKETING_VERSION>-universal.pkg`になります。ActionsタブからWorkflowを手動実行すると、Releaseを作らずにビルドだけを行い、成果物をartifactとして保存します。署名と公証は行いません。

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

本アプリ自身がmacOSのサービスを提供します。Automatorのクイックアクションは使いません。

1. `Finder Open With.app`をApplicationsフォルダーに配置して一度起動します。
2. システム設定 → キーボード → キーボードショートカット → サービスを開きます。
3. 「Finder Open WithでVS Codeを開く」を有効にし、好きなキーを割り当てます。
4. Finderで通常のフォルダーを選択してキーを押します。複数フォルダーも受け付けます。

キーは自動設定しません。

### アプリの起動について

サービスを提供するため、Finderはフォルダーの右クリックメニューを使うたびに、終了している本アプリを自動で起動します。サービスの仕組み上避けられないため、アプリは`LSUIElement`でDockアイコンを出さず、ウインドウも開きません。起動しても画面には何も表示されず、一度起動するとバックグラウンドで動き続けます。そのため、初回の「一度起動」は、画面に何も出なくても問題ありません。

古いビルドが別の場所に残っていると、Finderがそれを起動することがあります。同じバンドル識別子のアプリは、`~/Applications`など一か所だけにしてください。

右クリックメニューとサービスは`Shared/FolderOpening.swift`の同じ起動処理を使用します。ファイルやアプリのパッケージを含む選択は処理せず、サービスにエラーを返します。

実装参考：[Appleのサービス実装ガイド](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/providing.html)。

### サービス追加後の検証（2026-10-08、ビルド6）

- Releaseビルドとアプリ全体の署名検証：成功。
- システム設定のサービス → ファイルとフォルダに「Finder Open WithでVS Codeを開く」が表示され、有効になっていることを確認。キー割り当ては未設定。
- Finderの選択フォルダーに対して本アプリのサービスを実行し、アプリ本体の成功ログとVS Codeの対象フォルダーウインドウを確認。
- 右クリックメニュー直下の従来の「VS Codeで開く」も表示されることを確認。
- 複数フォルダー、日本語・空白・記号を含むパス、URL形式と従来のファイル名リスト形式、空選択・ファイル混在・アプリパッケージの拒否を検証。
- キーボードからの呼び出しはキー割り当て後に別途確認。

## Obsidianで開く

フォルダーの右クリックメニューに「Obsidianで開く」を追加しています。
対象フォルダー直下に`.obsidian`ディレクトリがあり、Obsidianの登録情報に同じフォルダーがある場合だけ、Vault IDを指定して開きます。
シンボリックリンクは実体のパスで照合し、同名の別Vaultと区別します。

Vaultでないフォルダー、未登録のVault、登録情報を確認できない場合はアラートを表示します。
複数選択時はすべてを検証してから開くため、対象外が一つでもあれば何も開きません。
`.obsidian`以外の設定フォルダー名を使うVaultは今回の対象外です。

Finder拡張から専用URLでアプリ本体へ依頼し、本体が`~/Library/Application Support/obsidian/obsidian.json`を読み取ります。
Obsidianの登録情報の変更、Vaultの作成、自動登録、再起動は行いません。
登録情報はObsidianの内部形式のため、将来の形式変更時には対応が必要になる可能性があります。

### Obsidian追加後の実機確認（2026-10-21、ビルド8）

- Releaseビルドとアプリ全体の署名検証：成功。
- `~/Applications/Finder Open With.app`を更新し、Finder拡張の再登録とFinderの再起動を実施。
- Finderの右クリック直下に「VS Codeで開く」と「Obsidianで開く」が表示されることを確認。
- 通常フォルダーでは「Vaultではありません」のアラートを確認。
- `.obsidian`のある未登録の検証用フォルダーでは「Obsidianに登録されていません」のアラートを確認。
- 登録済みの`dev`フォルダーから実行し、Obsidian 1.14.4の`dev` Vaultウインドウが前面に表示されることを確認。
- 今回は既に開いているVaultへの切り替えを確認。Obsidian終了状態からの起動と複数選択の実操作は未検証（判定処理のテストは実施済み）。

## Google Driveなどのクラウドフォルダー

Finder Sync拡張の項目が表示されない場所でも使えるよう、macOSサービスとして
「Finder Open WithでObsidianを開く」を提供します。既存の「Finder Open WithでVS Codeを開く」と同じ経路です。
Finderでフォルダーを右クリックし、下部の該当項目（macOSの表示条件によっては「サービス」内）を選択してください。
キーボードショートカットもシステム設定の「サービス」から割り当てられます。
Vaultの条件とアラートはFinder拡張と共通です。クラウドの未取得ファイルを一括ダウンロードする処理は行いません。

通常フォルダーには、Finder拡張の「VS Codeで開く」「Obsidianで開く」に加えてサービスの項目も表示される場合があります。
クイックアクション内の「VS Codeで開く」は本アプリのサービスとは別です。

### Google Driveでの実機確認（2026-10-21、ビルド9）

- Releaseビルド・署名検証成功。既存アプリを更新し、Finderを再起動。
- Google Driveの`obsidian/knowledge`を右クリックすると、Finder Syncの短い項目は表示されず、macOSの「サービス」内に「Finder Open WithでObsidianを開く」「Finder Open WithでVS Codeを開く」が表示されることを確認。
- Obsidian用サービスを実行し、Obsidian 1.14.4の`knowledge` Vaultが前面に表示されることを確認。
- 今回のGoogle Driveの表示経路に対応するためサービスを追加。Finder Sync側の項目が表示されないOS内部の原因までは特定していない。
- Google DriveでのVS Code起動、オンライン専用フォルダー、他のクラウドサービスは今回の実操作検証対象外。

### サービスを右クリック直下に表示する設定

このMacではFinderだけに次の設定を適用し、Google Driveの`knowledge`でObsidian・VS Code両サービスが直下に表示されることを実機確認しました（2026-10-21）。

```sh
defaults write com.apple.finder NSServicesMinimumItemCountForContextSubmenu -int 99
killall Finder
```

Finderがサービスをサブメニューにまとめる件数を増やす設定です。本アプリ以外のサービスにも適用されます。アプリのインストール処理では自動変更しません。macOSの非公開設定なので将来も同じ挙動を保証するものではありません。
元の設定が存在しない状態から変更した場合、次で標準動作に戻せます。

```sh
defaults delete com.apple.finder NSServicesMinimumItemCountForContextSubmenu
killall Finder
```

## 現在のメニュー構成（ビルド10以降）

通常フォルダー・Google DriveともにmacOSサービスへ統一しました。
サービスの表示名は「VS Codeで開く」「Obsidianで開く」です。
Finder Sync拡張からの重複項目は表示しません。上記のビルド9以前の確認記録は当時の仕様です。
ショートカットの設定先もこの短い名前になります。既存キー割り当ては更新後に確認してください。
本アプリ以外のクイックアクションは変更しません。
直下表示は上記Finder設定を使用します。別のMacではサービスが畳まれる場合があります。

### サービス統一後の実機確認（2026-10-21、ビルド10）

- Releaseビルド・署名検証成功。既存アプリを更新。
- サービスキャッシュを更新し、旧名が短い表示名へ変わったことを確認。
- 通常フォルダー`dev`、Google Driveの`knowledge`とも右クリック直下に「Obsidianで開く」「VS Codeで開く」が各1項目。Finder拡張による重複項目なし。
- Google Driveで「Obsidianで開く」を実行し、`knowledge` Vaultのウインドウを確認。
- 既存のクイックアクション内のVS Code項目は変更していない。

詳細な設定の位置付け・影響範囲・復旧手順は[Finderサービスの直下表示設定](docs/FINDER_SERVICE_MENU.md)を参照してください。


## Folio Editorで開く

Finderの「Folio Editorで開く」は、通常のフォルダーまたはMarkdownファイル（`.md` / `.markdown`）を1つ選択して実行します。フォルダーはエクスプローラーに表示し、MarkdownはFolio Editorの文書として開きます。ファイル名の日本語・空白・記号はURLのまま受け渡します。

従来の実装はフォルダー専用で、Markdownを渡すと拒否していました。ファイルはmacOSの通常の文書起動経路、フォルダーは`folio-editor://folder`で開きます。サービスの対象型にもMarkdownを追加しています。

受け渡し先の回帰テストは次で実行できます。

```sh
xcrun swiftc App/FolderService.swift Shared/FolderOpening.swift Tests/FolioOpening/main.swift -o /tmp/folio-opening-test
/tmp/folio-opening-test
```
