import AppKit

struct TargetApp: Identifiable, Equatable {
    let id: String
    var name: String
    var isEnabled: Bool
    var isRunning: Bool = false
    var isFrozen: Bool = false

    var icon: NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSImage(systemSymbolName: "app.fill", accessibilityDescription: name)
            ?? NSImage()
    }

    static func == (lhs: TargetApp, rhs: TargetApp) -> Bool {
        lhs.id == rhs.id
            && lhs.isEnabled == rhs.isEnabled
            && lhs.isRunning == rhs.isRunning
            && lhs.isFrozen == rhs.isFrozen
    }
}
