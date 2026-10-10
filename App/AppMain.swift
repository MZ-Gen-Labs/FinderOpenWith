import SwiftUI

@main
struct FinderOpenWithApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Finder Open With") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Finderの右クリックメニューに「アプリで開く」を追加")
                    .font(.title2.weight(.semibold))
                Text("Finderでフォルダーを右クリックすると、メニュー直下に「VS Codeで開く」が表示されます。")
                Text("初回起動後、システム設定 → 一般 → ログイン項目と機能拡張 → Finder で「Finder Open With」を有効にしてください。")
                Text("キーボードショートカット：システム設定 → キーボード → キーボードショートカット → サービスで「Finder Open WithでVS Codeを開く」に好きなキーを割り当ててください。")
                Text("Finderでフォルダーを選択して、割り当てたキーを押すとVS Codeで開きます。")
                Text("VS Code以外のアプリを選ぶ機能は、次の段階で追加できます。")
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(width: 560)
        }
        .windowResizability(.contentSize)
    }
}
