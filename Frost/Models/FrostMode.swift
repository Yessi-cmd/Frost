import Foundation

enum FrostMode: String, CaseIterable, Codable {
    case game
    case coding

    var displayName: String {
        switch self {
        case .game: return "游戏模式"
        case .coding: return "专注模式"
        }
    }

    var icon: String {
        switch self {
        case .game: return "gamecontroller.fill"
        case .coding: return "moon.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .game: return "冻结一切非必要应用"
        case .coding: return "保留开发工具和浏览器"
        }
    }

    // MARK: - Exclusion lists

    /// Apps that must NEVER be frozen in ANY mode.
    /// Freezing these would break network connectivity or system stability.
    static let coreExcluded: Set<String> = [
        "com.frost.app",
        "com.jordanbaird.Ice",

        // VPN / Proxy / Network infrastructure — SIGSTOP kills the tunnel
        "com.nebula.karing",
        "app.hiddify.com",
        "io.tailscale.ipn.macsys",
        "com.nssurge.surge-mac",
        "com.west2online.ClashX",
        "com.west2online.ClashX.pro",
        "io.github.niceurly.ClashXPro",
        "com.clashxpro.mac",
        "net.yanue.V2rayU",
        "cz.poynting.V2RayX",
        "com.proxyman.NSProxy",
        "com.wireguard.macos",
        "com.charlesproxy.Charles",
        "com.luckymarmot.Paw",              // RapidAPI / Paw
        "com.electron.mihomo-party",        // mihomo
        "org.v2fly.v2ray-core",
        "com.v2ray.V2RayXS",
    ]

    /// Apps excluded from coding/focus mode (dev tools, browsers, terminals).
    /// In game mode these CAN be frozen.
    static let codingExcluded: Set<String> = [
        // IDEs & Editors
        "com.todesktop.230313mzl4w4u92",   // Cursor
        "com.google.antigravity",           // Antigravity (Google)
        "com.google.antigravity.helper",
        "com.microsoft.VSCode",
        "com.microsoft.VSCodeInsiders",
        "dev.zed.Zed",
        "com.sublimetext.4",
        "com.sublimetext.3",
        "com.panic.Nova",
        "com.jetbrains.intellij",
        "com.jetbrains.intellij.ce",
        "com.jetbrains.WebStorm",
        "com.jetbrains.pycharm",
        "com.jetbrains.pycharm.ce",
        "com.jetbrains.goland",
        "com.jetbrains.CLion",
        "com.jetbrains.rider",
        "com.jetbrains.rustrover",
        "com.apple.dt.Xcode",

        // Terminals
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "io.alacritty",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "co.zeit.hyper",
        "org.tabby",
        "dev.warp.Warp-Stable",

        // Browsers
        "company.thebrowser.Browser",       // Arc
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "org.mozilla.firefox",
        "com.brave.Browser",
        "com.microsoft.edgemac",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",

        // Dev tools
        "com.postmanlabs.mac",
        "com.tinyapp.TablePlus",
        "com.insomnia.app",
        "com.kapeli.dashdoc",               // Dash
        "com.docker.docker",

        // Reference & docs
        "notion.id",
        "com.linear",
    ]

    /// Excluded bundle IDs for this specific mode.
    var excludedBundles: Set<String> {
        switch self {
        case .game:
            return Self.coreExcluded
        case .coding:
            return Self.coreExcluded.union(Self.codingExcluded)
        }
    }
}
