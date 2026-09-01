import Cocoa
import Carbon

class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var callback: (() -> Void)?

    // 默认快捷键：Command + Shift + V
    private var keyCode: UInt32 = 9  // V
    private var modifiers: UInt32 = UInt32(cmdKey | shiftKey)

    func registerHotKey(callback: @escaping () -> Void) {
        self.callback = callback
        unregisterHotKey()

        let hotKeyID = EventHotKeyID(signature: UTGetOSTypeFromString("htk1" as CFString), id: 1)
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // 安装事件处理器
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            HotKeyManager.shared.callback?()
            return noErr
        }, 1, &eventType, nil, &eventHandler)

        // 注册热键
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    func updateHotKey(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers

        // 重新注册
        if let callback = self.callback {
            registerHotKey(callback: callback)
        }
    }
}
