import Cocoa
import FlutterMacOS

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var mainWindow: MainFlutterWindow?
    private let windowDelegate = WindowCloseDelegate()
    
    private var clipboardMonitor: ClipboardMonitor?
      private var clipboardMenuManager: ClipboardMenuManager?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first as? MainFlutterWindow {
            self.mainWindow = window
            window.isReleasedWhenClosed = false
            window.delegate = windowDelegate

            // 设置 ClipboardMenuManager
            if let flutterVC = window.contentViewController as? FlutterViewController {
                
                let channel = FlutterMethodChannel(
                  name: "com.clipboard/channel",
                  binaryMessenger: flutterVC.engine.binaryMessenger
                )

                clipboardMonitor = ClipboardMonitor(channel: channel)
                clipboardMonitor?.startMonitoring()
                
                clipboardMenuManager = ClipboardMenuManager(channel: channel,appDelegate: self)
           
            }
        }
        
        setupHotKey()

        setupStatusBarItem()
    }

  
    private func setupHotKey() {
        // 注册全局快捷键 Command + Shift + V
        HotKeyManager.shared.registerHotKey { [weak self] in
            self?.showClipboardMenu()
        }
    }

    @objc private func showClipboardMenu() {
        clipboardMenuManager?.showClipboardMenu()
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
             // 1. 临时切换为 regular，允许显示窗口
             NSApp.setActivationPolicy(.regular)
             // 2. 显示窗口
        
        NSApp.activate(ignoringOtherApps: true)

             win.makeKeyAndOrderFront(nil)
        
        win.orderFrontRegardless() // 强制放到最顶层，无视窗口层级

     
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
        NSApp.setActivationPolicy(.accessory)

        return false
    }
}
