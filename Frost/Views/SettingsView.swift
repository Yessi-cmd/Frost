import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vm: FrostViewModel

    var body: some View {
        Form {
            Section("偏好设置") {
                Toggle("冻结前自动隐藏应用窗口", isOn: $vm.autoHide)
            }

            Section("快捷键") {
                HStack {
                    Text("切换专注模式")
                    Spacer()
                    Text("⌘⇧F")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                }
            }

            Section("关于") {
                Text("Frost 自动检测所有正在运行的非系统应用。\n冻结使用 SIGSTOP 暂停进程，解冻使用 SIGCONT 恢复。\n应用状态完全保留，不会丢失任何数据。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 260)
    }
}
