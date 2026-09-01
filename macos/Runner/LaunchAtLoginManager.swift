import Cocoa
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private init() {}

    // 检查是否已经设置了开机自启动
    var isLaunchAtLoginEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                return getLaunchAtLoginStatusLegacy()
            }
        }
    }

    // 启用开机自启动
    func enableLaunchAtLogin() throws {
        if #available(macOS 13.0, *) {
            // macOS 13+ 使用 SMAppService
            try SMAppService.mainApp.register()
            print("✅ 开机自启动已启用 (SMAppService)")
        } else {
            // macOS 12 及以下使用 AppleScript
            setLaunchAtLoginLegacy(enabled: true)
            print("✅ 开机自启动已启用 (Legacy)")
        }
    }

    // 禁用开机自启动
    func disableLaunchAtLogin() throws {
        if #available(macOS 13.0, *) {
            // macOS 13+ 使用 SMAppService
            try SMAppService.mainApp.unregister()
            print("❌ 开机自启动已禁用 (SMAppService)")
        } else {
            // macOS 12 及以下使用 AppleScript
            setLaunchAtLoginLegacy(enabled: false)
            print("❌ 开机自启动已禁用 (Legacy)")
        }
    }

    // 设置开机自启动（兼容旧版本方式，使用 AppleScript）
    private func setLaunchAtLoginLegacy(enabled: Bool) {
         let bundleURL = Bundle.main.bundleURL

        let bundlePath = bundleURL.path

        if enabled {
            // 添加到登录项
            let script = """
            tell application "System Events"
                make login item at end with properties {path:"\(bundlePath)", hidden:false}
            end tell
            """
            runAppleScript(script)
        } else {
            // 从登录项移除
            let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "clipboard"
            let script = """
            tell application "System Events"
                delete login item "\(appName)"
            end tell
            """
            runAppleScript(script)
        }
    }

    // 获取当前状态（兼容旧版本）
    private func getLaunchAtLoginStatusLegacy() -> Bool {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "clipboard"

        let script = """
        tell application "System Events"
            get the name of every login item
        end tell
        """

        if let result = runAppleScript(script),
           let loginItems = result as? [String] {
            return loginItems.contains(appName)
        }

        return false
    }

    // 运行 AppleScript
    @discardableResult
    private func runAppleScript(_ source: String) -> Any? {
        let script = NSAppleScript(source: source)
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)

        if let error = error {
            print("❌ AppleScript 错误: \(error)")
            return nil
        }

        // 尝试转换为字符串数组
        if let listDescriptor = result {
            var items: [String] = []
            for i in 1...listDescriptor.numberOfItems {
                if let item = listDescriptor.atIndex(i)?.stringValue {
                    items.append(item)
                }
            }
            return items.isEmpty ? nil : items
        }

        return result
    }
}
