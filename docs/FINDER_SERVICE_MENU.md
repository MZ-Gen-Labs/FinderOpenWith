# Finderのサービスを右クリック直下に表示する設定

記録日: 2026-10-21
対象: Finder Open With（ビルド10以降）と、このMacで実施したFinder設定

## 結論

サービスを提供する部分は、Appleが公開している標準のmacOSサービス機構です。
一方、サービスをサブメニューに畳まず表示するために今回使った設定は、Finderの隠し設定（非公開の設定キー）です。
`defaults`による設定変更自体は一般的なmacOSの操作ですが、この設定キーの動作はAppleの公開APIとして保証されたものではありません。
「標準機構でメニューを提供し、表示の畳み込みだけを非公開設定で調整している」と区別してください。

独自のFinder改造、コード注入、常駐監視でメニューを書き換える処理は行っていません。

## 現在の構成と採用理由

- アプリはmacOSサービスとして「VS Codeで開く」「Obsidianで開く」を登録する。
- Finder Sync拡張のメニューは返さず、通常フォルダーでの二重表示を防ぐ。
- Google DriveではFinder Syncの項目が表示されなかったが、サービスは表示・実行できたため、サービスに統一した。
- Finderがサービスをサブメニューへまとめる件数を増やし、右クリック直下から実行できるようにした。

Google DriveでFinder Sync項目が表示されなかったOS内部の原因は未特定であり、クラウド全般でFinder Syncが使えないと断定するものではありません。

## 適用した設定

```sh
defaults write com.apple.finder NSServicesMinimumItemCountForContextSubmenu -int 99
killall Finder
```

`com.apple.finder`はFinderの設定領域です。全アプリ共通の`-g`には設定していません。
`NSServicesMinimumItemCountForContextSubmenu`は、サービスをサブメニューにまとめる件数のしきい値を指定する設定キーです。
99は無効化専用の特別な値ではなく、通常の項目数ではしきい値に達しにくくするために選んだ値です。
どんな件数でも絶対に畳まれないことを保証する設定ではありません。
`killall Finder`は変更反映のためにFinderを再起動します。開いているFinderウインドウが一時的に閉じたり再表示されたりします。

現在値の確認:

```sh
defaults read com.apple.finder NSServicesMinimumItemCountForContextSubmenu
```

このMacの設定値は99です。変更前はこのキーが存在しないことを確認しました。

## 影響範囲と配布時の扱い

- このMacの現在のユーザーのFinderに適用される。
- Finder Open With以外のサービスも直下表示の対象になり、メニューが縦に長くなる場合がある。
- ファイルの内容、Google Driveの同期設定、Vaultの登録情報には変更を加えない。
- アプリの起動時・インストール時に自動適用するコードは入れていない。今回、設定作業として一度実行した。
- アプリを別のMacへコピーしても、このFinder設定は引き継がれない。
- アプリを削除しても、この設定は残る。必要なら別途元に戻す。
- macOS更新で設定キーが無効になる、または挙動が変わる可能性がある。更新後は表示を再確認する。

## 元に戻す方法

このMacでは変更前にキーが存在しなかったため、次で個別設定を削除して標準動作へ戻せます。

```sh
defaults delete com.apple.finder NSServicesMinimumItemCountForContextSubmenu
killall Finder
```

削除後の`defaults read`が「キーが見つからない」と返すのは正常です。
別のMacで適用する場合は変更前の値を記録し、既存値があった場合は削除ではなくその値に戻してください。
標準のしきい値を推測して数値を書き戻すより、もともとの設定状態へ戻す方法を使います。

## 動作確認済みの範囲

2026-10-21、このMacのFinderで以下を確認しました。

1. 設定前は、サービス追加に伴って「サービス」サブメニュー内へ項目がまとめられた。
2. Finder領域に99を設定して再起動すると、Google Driveの`knowledge`で両サービスが直下に表示された。
3. ビルド10でサービスへ統一した後、通常フォルダー`dev`とGoogle Driveの`knowledge`で、両項目が直下に各1項目ずつ表示された。
4. Google Driveの「Obsidianで開く」から、Obsidian 1.14.4の`knowledge` Vaultウインドウを確認した。

OSの標準しきい値そのものや、他のmacOSバージョンでの動作は今回の検証では確定していません。

## 保守時の確認箇所

- `App/Info.plist`: `NSServices`の表示名・サービス定義。
- `App/FolderService.swift`: サービスから渡された選択フォルダーの処理。
- `FinderExtension/FinderSync.swift`: 重複を避けるため`menu(for:)`が`nil`を返す。
- 本書のFinder設定: アプリ本体の処理とは別の、ユーザー環境の表示設定。

サービス名変更直後に旧名が残る場合は、まずアプリを再登録・起動し、Finderを再起動して確認します。
今回の更新ではサービスキャッシュの再構築も実施しました。これは畳み込みを防ぐ設定とは別の操作です。

## 参考資料

- Apple: サービスの公開仕様（標準機構の説明）
  https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/Articles/properties.html
- St. Clair Software: Default Folder X User Guide（同じ設定キーの利用例。Appleの公式保証を意味しない）
  https://www.stclairsoft.com/DefaultFolderX/DefaultFolderXGuide.pdf
