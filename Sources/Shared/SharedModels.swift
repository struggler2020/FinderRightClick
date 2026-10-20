import Foundation

public enum FRCConstants {
    public static let hostBundleID = "com.opensource.FinderRightClick"
    public static let extensionBundleID = "com.opensource.FinderRightClick.Extension"
    public static let ipcNotificationName = NSNotification.Name("com.opensource.FinderRightClick.IPCCommand")
    public static let payloadSeparator = "|||"
}

public enum TerminalApp: String, CaseIterable {
    case terminal = "com.apple.Terminal"
    case iterm2 = "com.googlecode.iterm2"
    case warp = "dev.warp.Warp-Stable"
    case ghostty = "com.mitchellh.ghostty"
    case kitty = "net.kovidgoyal.kitty"
    case alacritty = "org.alacritty"
    case wezterm = "com.github.wez.wezterm"
    case hyper = "co.zeit.hyper"

    public var displayName: String {
        switch self {
        case .terminal: return "Terminal"
        case .iterm2: return "iTerm2"
        case .warp: return "Warp"
        case .ghostty: return "Ghostty"
        case .kitty: return "kitty"
        case .alacritty: return "Alacritty"
        case .wezterm: return "WezTerm"
        case .hyper: return "Hyper"
        }
    }

    public var appPaths: [String] {
        switch self {
        case .terminal:
            return ["/System/Applications/Utilities/Terminal.app", "/Applications/Utilities/Terminal.app"]
        case .iterm2:
            return ["/Applications/iTerm.app", "\(NSHomeDirectory())/Applications/iTerm.app"]
        case .warp:
            return ["/Applications/Warp.app", "\(NSHomeDirectory())/Applications/Warp.app"]
        case .ghostty:
            return ["/Applications/Ghostty.app", "\(NSHomeDirectory())/Applications/Ghostty.app"]
        case .kitty:
            return ["/Applications/kitty.app", "\(NSHomeDirectory())/Applications/kitty.app"]
        case .alacritty:
            return ["/Applications/Alacritty.app", "\(NSHomeDirectory())/Applications/Alacritty.app"]
        case .wezterm:
            return ["/Applications/WezTerm.app", "\(NSHomeDirectory())/Applications/WezTerm.app"]
        case .hyper:
            return ["/Applications/Hyper.app", "\(NSHomeDirectory())/Applications/Hyper.app"]
        }
    }

    public var installedPath: String? {
        for path in appPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    public var isInstalled: Bool {
        return installedPath != nil
    }

    /// Preferred default terminal: prefers iTerm2 / Warp / Ghostty if installed, falls back to macOS Terminal.app
    public static var preferredDefault: TerminalApp {
        let priority: [TerminalApp] = [.iterm2, .warp, .ghostty, .wezterm, .kitty, .alacritty, .hyper, .terminal]
        for app in priority where app.isInstalled {
            return app
        }
        return .terminal
    }
}
