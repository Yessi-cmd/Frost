import AppKit
import Darwin

enum ProcessManager {

    static func freeze(pid: pid_t) -> Bool {
        kill(pid, SIGSTOP) == 0
    }

    static func unfreeze(pid: pid_t) -> Bool {
        kill(pid, SIGCONT) == 0
    }

    /// Recursively collect all descendant PIDs of a given parent.
    static func allDescendants(of parentPID: pid_t) -> [pid_t] {
        let children = directChildren(of: parentPID)
        var result = children
        for child in children {
            result.append(contentsOf: allDescendants(of: child))
        }
        return result
    }

    /// All PIDs (main + children) for an app identified by bundle ID.
    static func pidsForApp(bundleIdentifier: String) -> [pid_t] {
        let apps = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier)
        var all: [pid_t] = []
        for app in apps {
            let main = app.processIdentifier
            all.append(main)
            all.append(contentsOf: allDescendants(of: main))
        }
        return all
    }

    /// Read the process name for a PID via procfs, used for safety checks.
    static func processName(for pid: pid_t) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-p", String(pid), "-o", "comm="]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return nil
        }
    }

    // MARK: - Private

    private static func directChildren(of parentPID: pid_t) -> [pid_t] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-P", String(parentPID)]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output
                .split(separator: "\n")
                .compactMap { pid_t($0.trimmingCharacters(in: .whitespaces)) }
        } catch {
            return []
        }
    }
}
