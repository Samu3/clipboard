import Cocoa
import FlutterMacOS

class ClipboardMenuManager {
    weak var channel: FlutterMethodChannel?
    // 持有AppDelegate引用，用来直接调用打开窗口
    weak var appDelegate: AppDelegate?
    
    init(channel: FlutterMethodChannel, appDelegate: AppDelegate) {
        self.channel = channel
        self.appDelegate = appDelegate
    }

    func showClipboardMenu() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.channel?.invokeMethod("getClipboardHistory", arguments: ["limit": 30]) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let items = result as? [[String: Any]] {
                        self.buildRootMenu(items: items)
                    } else {
                        // 空数据根菜单
                        let menu = NSMenu()
                        let emptyItem = NSMenuItem(title: "暂无粘贴板历史", action: nil, keyEquivalent: "")
                        emptyItem.isEnabled = false
                        menu.addItem(emptyItem)
                        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
                    }
                }
            }
        }
    }

    // 构建【一级根菜单】：只有3个分组 + 功能选项
    private func buildRootMenu(items: [[String: Any]]) {
        let rootMenu = NSMenu()
        rootMenu.autoenablesItems = false
        
        if(items.count > 0){
            // 分组1：1~10
            let page1Item = NSMenuItem(title: "1-10", action: nil, keyEquivalent: "")
            page1Item.submenu = buildSubMenu(items: items, range: 0..<10)
            rootMenu.addItem(page1Item)
            
            if(items.count > 10){
                
                // 分组2：11~20
                let page2Item = NSMenuItem(title: "11-20", action: nil, keyEquivalent: "")
                page2Item.submenu = buildSubMenu(items: items, range: 10..<min(20, items.count))
                rootMenu.addItem(page2Item)
            }
            
            // 分组3：21~30
            if items.count > 20 {
                let page3Item = NSMenuItem(title: "21-30", action: nil, keyEquivalent: "")
                page3Item.submenu = buildSubMenu(items: items, range: 20..<min(30, items.count))
                rootMenu.addItem(page3Item)
            }

        }
      
     
        
     
        rootMenu.addItem(NSMenuItem.separator())

        // 显示主界面：直接调用 AppDelegate.showMainWindow
        let showMainItem = NSMenuItem(title: "显示主界面", action: #selector(showMainWindow), keyEquivalent: "")
        showMainItem.target = self
        rootMenu.addItem(showMainItem)

        // 清除历史
        let clearItem = NSMenuItem(title: "清除历史", action: #selector(clearHistory), keyEquivalent: "")
        clearItem.target = self
        rootMenu.addItem(clearItem)

        // 偏好设置
        let settingsItem = NSMenuItem(title: "偏好设置", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        rootMenu.addItem(settingsItem)

        let mouseLocation = NSEvent.mouseLocation
        rootMenu.popUp(positioning: nil, at: mouseLocation, in: nil)
    }

    // 构建【二级子菜单】：该分页下的剪贴条目，预览缩短到30字符
    private func buildSubMenu(items: [[String: Any]], range: Range<Int>) -> NSMenu {
        let subMenu = NSMenu()
        subMenu.autoenablesItems = false
        
        if range.lowerBound >= items.count {
            let emptyItem = NSMenuItem(title: "无记录", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            subMenu.addItem(emptyItem)
            return subMenu
        }
        
        for index in range {
            guard index < items.count else { break }
            let item = items[index]
            
            let preview = item["preview"] as? String ?? ""
            let id = item["id"] as? String ?? ""
            let type = item["type"] as? String ?? "text"
            let imagePath = item["filePath"] as? String
            let title = item["title"] as? String

            // 缩短预览：30字符
            let displayText = preview.count > 30 ? String(preview.prefix(30)) + "..." : preview

            let menuItem = NSMenuItem(
                title: "\(index + 1). \(displayText)",
                action: #selector(pasteClipboardItem(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.representedObject = [
                "id": id,
                "type": type,
                "imagePath": imagePath,
                "title":title
            ]
            
            // 如果是图片类型，加载缩略图作为菜单icon
            if type == "image", let imgPath = imagePath {
                let img = NSImage(contentsOfFile: imgPath)
                // 缩小缩略图 16x16，菜单图标标准尺寸
                img?.size = NSSize(width:16, height:16)
                menuItem.image = img
            }
            subMenu.addItem(menuItem)
        }
        return subMenu
    }

    @objc private func pasteClipboardItem(_ sender: NSMenuItem) {
        guard let obj = sender.representedObject as? [String:Any],
              let id = obj["id"] as? String else{
            return
        }

        self.channel?.invokeMethod("pasteClipboardItem", arguments: ["id":id])
                

        // 延迟模拟粘贴
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.simulatePaste()
        }
    }
    
    // 模拟 Cmd+V
    private func simulatePaste() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let cmdKey: CGKeyCode = 0x37
        let vKey: CGKeyCode = 0x09

        guard let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: cmdKey, keyDown: true),
              let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true),
              let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false),
              let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: cmdKey, keyDown: false) else {
            print("❌ 无法创建键盘事件")
            return
        }

        // ✅ 全部事件统一带上 maskCommand
        cmdDown.flags = .maskCommand
        vDown.flags = .maskCommand
        vUp.flags = .maskCommand
        // cmdUp 抬起command，清除修饰标记
        cmdUp.flags = []

        // 分步异步发送，不阻塞主线程，不要usleep
        cmdDown.post(tap: .cghidEventTap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            vDown.post(tap: .cghidEventTap)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                vUp.post(tap: .cghidEventTap)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
                    cmdUp.post(tap: .cghidEventTap)
                    print("✅ 已模拟 Cmd+V 按键")
                }
            }
        }
    }

    // ✅ 直接调用 AppDelegate 的方法，不再走channel
    @objc private func showMainWindow() {
        appDelegate?.openMainWindow()
    }

    @objc private func clearHistory() {
        channel?.invokeMethod("clearHistory", arguments: nil)
    }

    @objc private func openSettings() {
        channel?.invokeMethod("openSettings", arguments: nil)
    }
}
