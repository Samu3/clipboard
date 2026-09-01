import Cocoa
import FlutterMacOS

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var mainWindow: MainFlutterWindow?
    // 独立窗口代理，不和AppDelegate混在一起，解决selector报错
    private let windowDelegate = WindowCloseDelegate()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first as? MainFlutterWindow {
            self.mainWindow = window
            window.isReleasedWhenClosed = false
            window.delegate = windowDelegate
        }

        setupStatusBarItem()
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            // 优先使用自定义图标
            if let customIcon = NSImage(named: "MenuIcon") {
                button.image = customIcon
            } else if #available(macOS 11.0, *),
                      let systemIcon = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard") {
                // 使用系统图标
                button.image = systemIcon
            } else {
                // 降级使用文字/emoji
                button.title = "📋"
            }
        }

        let menu = NSMenu()
        let openItem = NSMenuItem(title: "打开主窗口", action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出App", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }
    
    @objc func openMainWindow() {
        guard let win = mainWindow else { return }
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// ✅ 单独抽离窗口关闭代理，不要写在AppDelegate扩展
class WindowCloseDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
