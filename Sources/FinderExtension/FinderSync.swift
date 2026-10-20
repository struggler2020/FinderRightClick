import Cocoa
import FinderSync

@objc(FinderSync)
class FinderSync: FIFinderSync {

    override init() {
        super.init()
        let controller = FIFinderSyncController.default()
        var urls: Set<URL> = [URL(fileURLWithPath: "/")]
        if let volumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
            for v in volumes {
                urls.insert(v)
            }
        }
        controller.directoryURLs = urls

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let volURL = notification.userInfo?[NSWorkspace.volumeURLUserInfoKey] as? URL {
                FIFinderSyncController.default().directoryURLs.insert(volURL)
            }
        }
    }

    override var toolbarItemName: String {
        return "FinderRightClick"
    }

    override var toolbarItemToolTip: String {
        return "在此新建文件、打开终端或复制路径"
    }

    override var toolbarItemImage: NSImage {
        if let img = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil) {
            img.isTemplate = true
            return img
        }
        return NSImage(named: NSImage.actionTemplateName)!
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")

        switch menuKind {
        case .contextualMenuForContainer, .contextualMenuForItems, .toolbarItemMenu:
            // 1. Open in Default Terminal (prefers iTerm2/Warp/Ghostty if installed, else Terminal.app)
            let defaultTerm = TerminalApp.preferredDefault
            let openTermItem = NSMenuItem(
                title: "在 \(defaultTerm.displayName) 中打开",
                action: #selector(openDefaultTerminalAction(_:)),
                keyEquivalent: ""
            )
            openTermItem.target = self
            if let termIcon = NSImage(systemSymbolName: "apple.terminal", accessibilityDescription: nil)
                ?? NSImage(systemSymbolName: "terminal", accessibilityDescription: nil) {
                termIcon.isTemplate = true
                openTermItem.image = termIcon
            }
            menu.addItem(openTermItem)

            // If macOS built-in Terminal is not the default (e.g. iTerm2 is installed), also offer built-in Terminal in a lightweight way or vice versa
            if defaultTerm != .terminal {
                let sysTermItem = NSMenuItem(
                    title: "在系统终端 (Terminal) 中打开",
                    action: #selector(openSystemTerminalAction(_:)),
                    keyEquivalent: ""
                )
                sysTermItem.target = self
                if let sysIcon = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil) {
                    sysIcon.isTemplate = true
                    sysTermItem.image = sysIcon
                }
                menu.addItem(sysTermItem)
            }

            // 2. Copy File Path
            let copyItem = NSMenuItem(
                title: "复制文件路径",
                action: #selector(copyPathAction(_:)),
                keyEquivalent: ""
            )
            copyItem.target = self
            if let copyIcon = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: nil) {
                copyIcon.isTemplate = true
                copyItem.image = copyIcon
            }
            menu.addItem(copyItem)

            // 3. Create Custom File (with Dialog)
            let newCustomItem = NSMenuItem(
                title: "在此新建文件...",
                action: #selector(newCustomFileAction(_:)),
                keyEquivalent: ""
            )
            newCustomItem.target = self
            if let addIcon = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil) {
                addIcon.isTemplate = true
                newCustomItem.image = addIcon
            }
            menu.addItem(newCustomItem)

            // 4. Quick Create Submenu (.txt / .md / .py)
            let subMenu = NSMenu(title: "快速新建空白文件")

            let txtItem = NSMenuItem(title: "新建 Text (.txt)", action: #selector(quickCreateTxt(_:)), keyEquivalent: "")
            txtItem.target = self
            if let icon = NSImage(systemSymbolName: "doc.text", accessibilityDescription: nil) {
                icon.isTemplate = true
                txtItem.image = icon
            }
            subMenu.addItem(txtItem)

            let mdItem = NSMenuItem(title: "新建 Markdown (.md)", action: #selector(quickCreateMd(_:)), keyEquivalent: "")
            mdItem.target = self
            if let icon = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: nil) {
                icon.isTemplate = true
                mdItem.image = icon
            }
            subMenu.addItem(mdItem)

            let pyItem = NSMenuItem(title: "新建 Python (.py)", action: #selector(quickCreatePy(_:)), keyEquivalent: "")
            pyItem.target = self
            if let icon = NSImage(systemSymbolName: "chevron.left.forwardslash.chevron.right", accessibilityDescription: nil) {
                icon.isTemplate = true
                pyItem.image = icon
            }
            subMenu.addItem(pyItem)

            let quickSubmenuContainer = NSMenuItem(title: "快速新建 (.txt / .md / .py)", action: nil, keyEquivalent: "")
            if let quickIcon = NSImage(systemSymbolName: "plus.square.on.square", accessibilityDescription: nil) {
                quickIcon.isTemplate = true
                quickSubmenuContainer.image = quickIcon
            }
            quickSubmenuContainer.submenu = subMenu
            menu.addItem(quickSubmenuContainer)

        default:
            break
        }

        return menu
    }

    // MARK: - Path Resolution

    private func selectedOrTargetedURLs() -> [URL] {
        let controller = FIFinderSyncController.default()
        if let items = controller.selectedItemURLs(), !items.isEmpty {
            return items
        }
        if let target = controller.targetedURL() {
            return [target]
        }
        return []
    }

    private func targetDirectoryPath() -> String? {
        let controller = FIFinderSyncController.default()
        if let items = controller.selectedItemURLs(), let first = items.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: first.path, isDirectory: &isDir), isDir.boolValue {
                return first.path
            }
            return first.deletingLastPathComponent().path
        }
        if let target = controller.targetedURL() {
            return target.path
        }
        return nil
    }

    // MARK: - Menu Actions

    @objc func openDefaultTerminalAction(_ sender: AnyObject?) {
        guard let dir = targetDirectoryPath() else { return }
        sendIPC(action: "OPEN_TERMINAL", targetPath: dir, arg: TerminalApp.preferredDefault.rawValue)
    }

    @objc func openSystemTerminalAction(_ sender: AnyObject?) {
        guard let dir = targetDirectoryPath() else { return }
        sendIPC(action: "OPEN_TERMINAL", targetPath: dir, arg: TerminalApp.terminal.rawValue)
    }

    @objc func copyPathAction(_ sender: AnyObject?) {
        let urls = selectedOrTargetedURLs()
        guard !urls.isEmpty else { return }
        let pathString = urls.map { $0.path }.joined(separator: "\n")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(pathString, forType: .string)
    }

    @objc func newCustomFileAction(_ sender: AnyObject?) {
        guard let dir = targetDirectoryPath() else { return }
        sendIPC(action: "CREATE_FILE", targetPath: dir, arg: "PROMPT")
    }

    @objc func quickCreateTxt(_ sender: AnyObject?) {
        guard let dir = targetDirectoryPath() else { return }
        sendIPC(action: "CREATE_FILE", targetPath: dir, arg: ".txt")
    }

    @objc func quickCreateMd(_ sender: AnyObject?) {
        guard let dir = targetDirectoryPath() else { return }
        sendIPC(action: "CREATE_FILE", targetPath: dir, arg: ".md")
    }

    @objc func quickCreatePy(_ sender: AnyObject?) {
        guard let dir = targetDirectoryPath() else { return }
        sendIPC(action: "CREATE_FILE", targetPath: dir, arg: ".py")
    }

    private func sendIPC(action: String, targetPath: String, arg: String) {
        let sep = FRCConstants.payloadSeparator
        let payload = "\(action)\(sep)\(targetPath)\(sep)\(arg)"
        DistributedNotificationCenter.default().postNotificationName(
            FRCConstants.ipcNotificationName,
            object: payload,
            userInfo: nil,
            deliverImmediately: true
        )
    }
}
