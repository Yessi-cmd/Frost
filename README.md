# Frost ❄️

**Freeze background apps, focus on what matters.**

A lightweight macOS menu bar app that suspends background applications with `SIGSTOP` to free up CPU resources — perfect for gaming or deep coding sessions.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Two modes**
  - 🎮 **Game Mode** — Freezes all non-essential apps (including IDEs and browsers)
  - 🌙 **Focus Mode** — Freezes distractions while keeping dev tools, browsers, and terminals alive
- **One-click or hotkey** — Click the menu bar icon or press `⌘⇧F` to toggle
- **Smart exclusions** — VPN/proxy apps (Clash, Surge, Tailscale, etc.) are never frozen to preserve network connectivity
- **Auto-detect** — Scans running apps in real-time, no manual configuration needed
- **Crash recovery** — Frozen PIDs are persisted to disk; if Frost crashes, processes are automatically resumed on next launch
- **Lightweight** — Pure Swift + SwiftUI, < 5MB binary, ~15MB RAM

## How It Works

Frost sends `SIGSTOP` to pause target processes (and all their child processes). The apps remain in memory with their state fully preserved — no data loss, no restart needed. When you exit focus mode, `SIGCONT` resumes them instantly.

## Install

### Build from source

```bash
git clone https://github.com/nicekid1/Frost.git
cd Frost
make run        # Build and launch
make install    # Copy to /Applications
```

Requires Xcode Command Line Tools (`xcode-select --install`).

## Usage

1. Click the **❄️ snowflake** icon in the menu bar
2. Choose **Game Mode** or **Focus Mode**
3. Toggle apps on/off as needed
4. Click **Enter** to freeze — the popover closes automatically
5. Press `⌘⇧F` or click the icon again to unfreeze

## Architecture

```
Frost/
├── FrostApp.swift              # @main entry point
├── AppDelegate.swift           # Menu bar + global hotkey (⌘⇧F)
├── Models/
│   ├── TargetApp.swift         # App data model
│   └── FrostMode.swift         # Game / Coding mode with exclusion lists
├── Services/
│   ├── ProcessManager.swift    # SIGSTOP / SIGCONT + child process discovery
│   └── SafetyGuard.swift       # Crash recovery (PID + process name validation)
├── ViewModels/
│   └── FrostViewModel.swift    # State management
└── Views/
    ├── PopoverView.swift       # Main popover UI
    ├── AppRowView.swift        # Per-app row with toggle
    └── SettingsView.swift      # Preferences
```

## License

MIT
