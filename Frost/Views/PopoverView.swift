import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var vm: FrostViewModel
    var closePopover: () -> Void

    @State private var previewMode: FrostMode = .coding

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if vm.isFocusMode {
                activeAppList
            } else {
                modePicker
                appList
            }

            Divider()
            footer
        }
        .frame(width: 320)
        .onAppear {
            if !vm.isFocusMode {
                vm.refreshApps(for: previewMode)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            if vm.isFocusMode {
                Image(systemName: vm.activeMode.icon)
                    .font(.title2)
                    .foregroundStyle(.cyan)
                Text(vm.activeMode.displayName)
                    .font(.headline)
            } else {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Frost")
                    .font(.headline)
            }

            Spacer()

            if vm.isFocusMode {
                Text(vm.formattedDuration)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }

            SettingsLink {
                Image(systemName: "gear")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 8) {
            modeTab(.game)
            modeTab(.coding)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 4)
    }

    private func modeTab(_ mode: FrostMode) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                previewMode = mode
                vm.refreshApps(for: mode)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.caption)
                Text(mode.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                previewMode == mode
                    ? AnyShapeStyle(Color.accentColor.opacity(0.12))
                    : AnyShapeStyle(Color.clear)
            )
            .foregroundStyle(previewMode == mode ? .primary : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        previewMode == mode ? Color.accentColor.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - App Lists

    private var appList: some View {
        VStack(spacing: 0) {
            if !vm.targetApps.isEmpty {
                HStack {
                    Text("\(vm.enabledRunningCount)/\(vm.targetApps.count) 个应用将被冻结")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button(vm.allEnabled ? "全不选" : "全选") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            vm.setAllEnabled(!vm.allEnabled)
                        }
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 2)
            }

            ScrollView {
                LazyVStack(spacing: 2) {
                    if vm.targetApps.isEmpty {
                        emptyState
                    } else {
                        ForEach(vm.targetApps) { app in
                            AppRowView(app: app, isFocusMode: false) {
                                vm.toggleApp(app)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 240)
        }
    }

    private var activeAppList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(vm.targetApps) { app in
                    AppRowView(app: app, isFocusMode: true) {}
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 280)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.title)
                .foregroundStyle(.green.opacity(0.6))
            Text(previewMode == .coding
                 ? "没有需要冻结的干扰应用"
                 : "没有检测到可冻结的应用")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 10) {
            if vm.isFocusMode {
                exitButton
            } else {
                enterButton
            }

            HStack {
                Text("⌘⇧F 快捷切换")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button("退出 Frost") {
                    if vm.isFocusMode { vm.exitFocusMode() }
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
    }

    private var enterButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                vm.enter(mode: previewMode)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    closePopover()
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: previewMode.icon)
                Text("进入\(previewMode.displayName)")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                previewMode == .game
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading, endPoint: .trailing))
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(vm.enabledRunningCount == 0)
    }

    private var exitButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                vm.exitFocusMode()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                Text("解除冻结")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .leading, endPoint: .trailing)
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
