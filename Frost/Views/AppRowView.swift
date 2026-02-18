import SwiftUI

struct AppRowView: View {
    let app: TargetApp
    let isFocusMode: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .saturation(app.isFrozen ? 0.2 : 1.0)

            VStack(alignment: .leading, spacing: 1) {
                Text(app.name)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                    Text(statusText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isFocusMode {
                if app.isFrozen {
                    Image(systemName: "snowflake")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                        .symbolEffect(.pulse, isActive: true)
                }
            } else {
                Toggle("", isOn: Binding(
                    get: { app.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(app.isFrozen ? Color.cyan.opacity(0.07) : Color.clear)
        )
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.25), value: app.isFrozen)
    }

    private var statusColor: Color {
        if app.isFrozen { return .cyan }
        return .green
    }

    private var statusText: String {
        app.isFrozen ? "已冻结" : "运行中"
    }
}
