# Finder Open With 1.0.2 — 別Macへのインストール

macOS 13以降、Apple Silicon・Intel両対応のUniversal版。アプリはad-hoc署名、PKGは未署名・未公証の個人利用向け配布物です。初回の警告は個別に許可します。

## 1. ダウンロードと検証

[Release v1.0.2-personal.1](https://github.com/MZ-Gen-Labs/FinderOpenWith/releases/tag/v1.0.2-personal.1) のAssetsから、`FinderOpenWith-1.0.2-universal.pkg`、`SHA256SUMS.txt`、`INSTALL.md`、`build-info.json` を同じフォルダへ保存します。Source codeのZIPは選びません。

```sh
cd ~/Downloads
shasum -a 256 -c SHA256SUMS.txt
```

すべてOKなら進みます。FAILEDの場合は指定Releaseから取り直します。

## 2. インストール

1. VS Code、Obsidian、Folio Editorのうち使うアプリを別途導入します。すべてを入れる必要はありません。
2. 既存のFinder Open Withがあれば終了し、appをバックアップします。`~/Applications`と`/Applications`の両方に旧コピーが残らないようにします。
3. PKGを開き、案内に従います。管理者認証が必要です。`/Applications/Finder Open With.app`に配置します。
4. Finderの「アプリケーション」から一度起動します。Dockアイコンやウィンドウが出ないのは正常です。

開発元確認でブロックされたら、配布元とチェックサムを確認して、開こうとした後に「システム設定 → プライバシーとセキュリティ → このまま開く」で個別許可します。PKGとアプリでそれぞれ必要になる場合があります。OS全体のGatekeeper無効化は不要です。

## 3. サービスを設定する

この版はmacOSサービス方式です。Finder機能拡張を有効にする旧版の操作は不要です。

1. 「システム設定 → キーボード → キーボードショートカット → サービス」を開きます。
2. 「VS Codeで開く」「Obsidianで開く」「Folio Editorで開く」のうち使う項目を有効にします。必要ならキーを割り当てます。
3. Finderで通常のフォルダを選び、右クリックまたは「サービス」から目的の項目を選びます。サブメニューへまとまる場合があります。

項目が出ない場合はログアウト・再ログイン後に再確認します。

Obsidianの対象は`.obsidian`のある登録済みVaultです。事前にObsidianへ登録してください。Folio Editorはフォルダを開くURL連携を使います。開くアプリ側の確認画面が出たら対象パスを確認します。ファイルや.appパッケージは対象外です。

## 4. 完了確認

テスト用フォルダで目的のアプリがそのフォルダを開くことを確認します。別Macの右クリックメニュー・アプリ連携は導入先で最終確認してください。

開発元ではUniversalビルド、署名検証、PKGから取り出したappの署名・CPU検証を行います。マシン全体へのインストール・Finder再起動・利用中のサービス変更は検証に含めません。
