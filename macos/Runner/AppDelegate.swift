import Cocoa
import FlutterMacOS

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    var mainWindow: MainFlutterWindow?
    private let windowDelegate = WindowCloseDelegate()
    
    private var clipboardMonitor: ClipboardMonitor?
    private var clipboardMenuManager: ClipboardMenuManager?
    private var hotkeyRecorder: HotkeyRecorder = HotkeyRecorder.shared

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let window = NSApplication.shared.windows.first as? MainFlutterWindow {
            self.mainWindow = window
            window.isReleasedWhenClosed = false
            window.delegate = windowDelegate
            
            setupHotKey()

            // 设置 ClipboardMenuManager
            if let flutterVC = window.contentViewController as? FlutterViewController {
                
                let channel = FlutterMethodChannel(
                  name: "com.clipboard/channel",
                  binaryMessenger: flutterVC.engine.binaryMessenger
                )
                
                let settingChannel = FlutterMethodChannel(
                  name: "com.clipboard.setting/channel",
                  binaryMessenger: flutterVC.engine.binaryMessenger
                )
                
                let langChanel = FlutterMethodChannel(
                  name: "com.clipboard.language/channel",
                  binaryMessenger: flutterVC.engine.binaryMessenger
                )
                
                clipboardMonitor = ClipboardMonitor(channel: channel)
                clipboardMonitor?.startMonitoring()

                clipboardMenuManager = ClipboardMenuManager(channel: channel,appDelegate: self)
                
                hotkeyRecorder.channel = settingChannel
                
                LanguageManager.shared.setupMethodCall(c: langChanel)

                // ========= 改动：语言切换回调，只更新菜单文字，不重建statusItem =========
                LanguageManager.shared.updateLangCallBack = ({ [weak self] in
                    guard let `self` = self else { return }
                    self.updateStatusBarMenuTitles()
                })

                // 设置开机自启动的 Method Channel 处理
                setupLaunchAtLoginHandler(channel: settingChannel)
            }
        }
        // ✅ 仅在启动时创建一次 statusItem
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

    /// 【只执行一次】创建statusItem + 初始化菜单结构
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
//            // 优先使用自定义图标
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
//            button.image = NSImage(named: "preview_light")   // 已自动按 scale 选择
//              button.image?.isTemplate = true                // 关键！告诉系统这是 template 图
//              button.toolTip = "PasteLink"
        }
        // 初始化菜单
        rebuildStatusMenu()
    }

    /// 重建菜单结构（只新建menu，statusItem保留）
    private func rebuildStatusMenu() {
        let menu = NSMenu()
        let openItem = NSMenuItem(title: "OPEN_MAIN".lang(), action: #selector(openMainWindow), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "EXIT_APP".lang(), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
    }

    /// ✅【语言切换调用】只更新已有menuItem的文字，不再新建statusItem
    private func updateStatusBarMenuTitles() {
        guard let menu = statusItem.menu else { return }
        // 遍历菜单项更新标题
        for item in menu.items {
            guard let action = item.action else { continue }
            if action == #selector(openMainWindow) {
                item.title = "OPEN_MAIN".lang()
            } else if action == #selector(quitApp) {
                item.title = "EXIT_APP".lang()
            }
        }
    }
    
    @objc func openMainWindow() {
        guard let win = mainWindow else { return }
        // 1. 临时切换为 regular，允许显示窗口
        NSApp.setActivationPolicy(.regular)
        // 2. 显示窗口
        NSApp.activate(ignoringOtherApps: true)
        win.makeKeyAndOrderFront(nil)
        win.orderFrontRegardless()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // 设置开机自启动的 Method Channel 处理
    private func setupLaunchAtLoginHandler(channel: FlutterMethodChannel) {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate is unavailable", details: nil))
                return
            }
  
            switch call.method {
                
            case "startHotKey":
                hotkeyRecorder.startRecord()
                break
                
            case "stopHotKey":
                hotkeyRecorder.stopRecord()
                break
                
            case "updateHotKey":
                guard let args = call.arguments as? [String:Any],
                      let modifierKeyCode = args["modifierKeyCode"] as? UInt32, let mainKeyCode = args["mainKeyCode"] as? UInt32 else {
                    result(false)
                    return
                }
                
                HotKeyManager.shared.updateHotKey(keyCode: mainKeyCode, modifiers: modifierKeyCode)
                result(true)
                break
                
         
            case "setLaunchAtLogin":
                guard let args = call.arguments as? [String: Any],
                      let enabled = args["enabled"] as? Bool else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
                    return
                }

                do {
                    if enabled {
                        try LaunchAtLoginManager.shared.enableLaunchAtLogin()
                    } else {
                        try LaunchAtLoginManager.shared.disableLaunchAtLogin()
                    }
                    result(true)
                } catch {
                    result(FlutterError(code: "ERROR", message: "Failed to set launch at login: \(error)", details: nil))
                }

            case "getLaunchAtLoginStatus":
                let isEnabled = LaunchAtLoginManager.shared.isLaunchAtLoginEnabled
                result(isEnabled)

            default:
                result(FlutterMethodNotImplemented)
            }
        }
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
