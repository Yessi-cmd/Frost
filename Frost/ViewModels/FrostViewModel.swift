import AppKit
import Combine
import SwiftUI
import UserNotifications

@MainActor
final class FrostViewModel: ObservableObject {

    static let shared = FrostViewModel()

    // MARK: - Published State

    @Published var targetApps: [TargetApp] = []
    @Published var isFocusMode: Bool = false
    @Published var activeMode: FrostMode = .coding
    @Published var lastSelectedMode: FrostMode = .coding
    @Published var frozenCount: Int = 0
    @Published var focusDuration: TimeInterval = 0
    @Published var autoHide: Bool = true

    // MARK: - Internal

    private var frozenPIDs: [String: [pid_t]] = [:]
    private var timer: Timer?
    private var pendingFreezeWork: DispatchWorkItem?

    private static let systemBundlePrefixes = ["com.apple."]

    // MARK: - Init

    init() {
        requestNotificationPermission()
    }

    // MARK: - App Discovery

    func refreshApps(for mode: FrostMode) {
        let running = NSWorkspace.shared.runningApplications
        let frontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        let excluded = mode.excludedBundles

        let userApps = running.filter { app in
            guard let bid = app.bundleIdentifier else { return false }
            if excluded.contains(bid) { return false }
            if Self.systemBundlePrefixes.contains(where: { bid.hasPrefix($0) }) { return false }
            if bid == frontmost { return false }
            return app.activationPolicy == .regular
        }

        let savedState = loadEnabledDict()
        var newList: [TargetApp] = []

        for app in userApps {
            guard let bid = app.bundleIdentifier else { continue }
            let name = app.localizedName ?? bid
            let wasEnabled = savedState[bid] ?? true
            let wasFrozen = frozenPIDs[bid] != nil

            newList.append(TargetApp(
                id: bid,
                name: name,
                isEnabled: wasEnabled,
                isRunning: true,
                isFrozen: wasFrozen
            ))
        }

        newList.sort {
            if $0.isEnabled != $1.isEnabled { return $0.isEnabled }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }

        targetApps = newList
    }

    func refreshApps() {
        refreshApps(for: isFocusMode ? activeMode : lastSelectedMode)
    }

    // MARK: - Focus Mode

    /// Called by the global hotkey — uses the last selected mode from the popover.
    func toggleFocusMode() {
        if isFocusMode {
            exitFocusMode()
        } else {
            enter(mode: lastSelectedMode)
        }
    }

    func enter(mode: FrostMode) {
        guard !isFocusMode else { return }

        activeMode = mode
        lastSelectedMode = mode
        refreshApps(for: mode)

        let targets = targetApps.filter { $0.isEnabled && $0.isRunning }
        guard !targets.isEmpty else { return }

        if autoHide {
            for app in targets {
                if let running = NSRunningApplication.runningApplications(
                    withBundleIdentifier: app.id
                ).first {
                    running.hide()
                }
            }
        }

        isFocusMode = true
        focusDuration = 0
        startTimer()

        // Delayed freeze with cancellation support for race-condition safety
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isFocusMode else { return }

            var allPids: [pid_t] = []
            var pidsByApp: [String: [pid_t]] = [:]

            for app in targets {
                let pids = ProcessManager.pidsForApp(bundleIdentifier: app.id)
                pidsByApp[app.id] = pids
                allPids.append(contentsOf: pids)
            }

            for pid in allPids {
                _ = ProcessManager.freeze(pid: pid)
            }

            self.frozenPIDs = pidsByApp
            for app in targets {
                if let idx = self.targetApps.firstIndex(where: { $0.id == app.id }) {
                    self.targetApps[idx].isFrozen = true
                }
            }
            self.frozenCount = targets.count

            SafetyGuard.shared.save(pids: allPids)
            self.sendNotification(
                title: "Frost · \(mode.displayName)已开启",
                body: "已冻结 \(targets.count) 个应用，按 ⌘⇧F 解除"
            )
        }
        pendingFreezeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    func exitFocusMode() {
        guard isFocusMode else { return }

        // Cancel pending freeze if user exits before it runs
        pendingFreezeWork?.cancel()
        pendingFreezeWork = nil

        let allPids = frozenPIDs.values.flatMap { $0 }
        for pid in allPids {
            _ = ProcessManager.unfreeze(pid: pid)
        }

        for bundleId in frozenPIDs.keys {
            if let idx = targetApps.firstIndex(where: { $0.id == bundleId }) {
                targetApps[idx].isFrozen = false
            }
        }

        let count = frozenPIDs.count
        let mode = activeMode
        frozenPIDs.removeAll()
        frozenCount = 0
        SafetyGuard.shared.clear()
        isFocusMode = false
        stopTimer()

        sendNotification(
            title: "Frost · \(mode.displayName)已结束",
            body: "已恢复 \(count) 个应用，专注了 \(formattedDuration)"
        )
    }

    // MARK: - App Toggle

    func toggleApp(_ app: TargetApp) {
        guard let idx = targetApps.firstIndex(where: { $0.id == app.id }) else { return }
        targetApps[idx].isEnabled.toggle()
        saveEnabledState()
    }

    func setAllEnabled(_ enabled: Bool) {
        for i in targetApps.indices {
            targetApps[i].isEnabled = enabled
        }
        saveEnabledState()
    }

    // MARK: - Computed Helpers

    var formattedDuration: String {
        let h = Int(focusDuration) / 3600
        let m = Int(focusDuration) % 3600 / 60
        let s = Int(focusDuration) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    var enabledRunningCount: Int {
        targetApps.filter { $0.isEnabled && $0.isRunning }.count
    }

    var allEnabled: Bool {
        !targetApps.isEmpty && targetApps.allSatisfy(\.isEnabled)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.focusDuration += 1 }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Persistence

    private func loadEnabledDict() -> [String: Bool] {
        guard let data = UserDefaults.standard.data(forKey: "frost_enabledState"),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data)
        else { return [:] }
        return dict
    }

    private func saveEnabledState() {
        var dict = loadEnabledDict()
        for app in targetApps { dict[app.id] = app.isEnabled }
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: "frost_enabledState")
        }
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
