import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleIPCCommand(_:)),
            name: FRCConstants.ipcNotificationName,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
    }

    @objc func handleIPCCommand(_ notification: Notification) {
        guard let payload = notification.object as? String else { return }
        let parts = payload.components(separatedBy: FRCConstants.payloadSeparator)
        guard parts.count >= 2 else { return }

        let action = parts[0]
        let targetPath = parts[1]
        let arg = parts.count >= 3 ? parts[2] : ""

        DispatchQueue.main.async {
            switch action {
            case "CREATE_FILE":
                self.promptAndCreateFile(in: targetPath, ext: arg)
            case "OPEN_TERMINAL":
                self.openInTerminal(dirPath: targetPath, bundleID: arg)
            default:
                break
            }
        }
    }

    // MARK: - Open in Terminal

    func openInTerminal(dirPath: String, bundleID: String) {
        let dir = resolveDirectory(from: dirPath)
        let terminal: TerminalApp = TerminalApp(rawValue: bundleID) ?? TerminalApp.preferredDefault

        guard let appPath = terminal.installedPath else {
            // Fallback to macOS built-in Terminal.app
            openWithProcess(appPath: "/System/Applications/Utilities/Terminal.app", targetDir: dir)
            return
        }

        openWithProcess(appPath: appPath, targetDir: dir)
    }

    private func openWithProcess(appPath: String, targetDir: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appPath, targetDir]
        try? process.run()
    }

    // MARK: - Create File

    func promptAndCreateFile(in rawPath: String, ext: String) {
        let dir = resolveDirectory(from: rawPath)

        let finalName: String
        if ext == "PROMPT" {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "在此新建文件"
            alert.informativeText = "请输入文件名（若不填后缀，则自动使用所选按钮的格式）："
            alert.alertStyle = .informational
            alert.addButton(withTitle: ".txt")
            alert.addButton(withTitle: ".md")
            alert.addButton(withTitle: ".py")
            alert.addButton(withTitle: "取消")

            let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
            inputField.stringValue = "untitled"
            alert.accessoryView = inputField
            alert.window.initialFirstResponder = inputField

            let response = alert.runModal()
            let chosenExt: String
            switch response {
            case .alertFirstButtonReturn:
                chosenExt = ".txt"
            case .alertSecondButtonReturn:
                chosenExt = ".md"
            case .alertThirdButtonReturn:
                chosenExt = ".py"
            default:
                return
            }

            var rawName = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if rawName.isEmpty {
                rawName = "untitled"
            }
            if (rawName as NSString).pathExtension.isEmpty {
                finalName = rawName + chosenExt
            } else {
                finalName = rawName
            }
        } else {
            finalName = "untitled" + ext
        }

        let baseName = (finalName as NSString).deletingPathExtension
        let fileExt = (finalName as NSString).pathExtension
        var fullPath = (dir as NSString).appendingPathComponent(finalName)

        var counter = 1
        while FileManager.default.fileExists(atPath: fullPath) {
            let numbered = fileExt.isEmpty ? "\(baseName)_\(counter)" : "\(baseName)_\(counter).\(fileExt)"
            fullPath = (dir as NSString).appendingPathComponent(numbered)
            counter += 1
        }

        FileManager.default.createFile(atPath: fullPath, contents: Data(), attributes: nil)
        NSWorkspace.shared.selectFile(fullPath, inFileViewerRootedAtPath: dir)
    }

    private func resolveDirectory(from path: String) -> String {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
            return (path as NSString).deletingLastPathComponent
        }
        return path
    }
}
