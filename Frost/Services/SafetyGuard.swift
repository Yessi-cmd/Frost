import Foundation

/// Persists frozen-PID state so we can recover if Frost crashes
/// while processes are suspended.
final class SafetyGuard {
    static let shared = SafetyGuard()

    private let pidsKey = "frost_frozenPIDs"

    struct FrozenEntry: Codable {
        let pid: Int
        let name: String
    }

    func save(pids: [pid_t]) {
        let entries = pids.compactMap { pid -> FrozenEntry? in
            guard let name = ProcessManager.processName(for: pid) else { return nil }
            return FrozenEntry(pid: Int(pid), name: name)
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: pidsKey)
        }
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: pidsKey)
    }

    /// On launch, resume any orphaned frozen processes from a previous session.
    /// Only sends SIGCONT if the process name still matches (guards against PID reuse).
    func recoverIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: pidsKey),
              let entries = try? JSONDecoder().decode([FrozenEntry].self, from: data),
              !entries.isEmpty
        else { return }

        for entry in entries {
            let pid = pid_t(entry.pid)
            if kill(pid, 0) == 0,
               let currentName = ProcessManager.processName(for: pid),
               currentName == entry.name
            {
                _ = ProcessManager.unfreeze(pid: pid)
            }
        }
        clear()
    }
}
