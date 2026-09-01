//
//  HotkeyRecorder.swift
//  Runner
//
//  Created by 王文智 on 2026/9/1.
//

import Cocoa
import FlutterMacOS

let cmdKey: UInt32 = 1 << 8
let shiftKey: UInt32 = 1 << 9
let optionKey: UInt32 = 1 << 10
let controlKey: UInt32 = 1 << 11

class HotkeyRecorder {
    static let shared = HotkeyRecorder()
    private var eventMonitor: Any?
    weak var channel: FlutterMethodChannel?
    

    
    /// 开始录制全局按键
    func startRecord() {
        stopRecord()
        // 全局监听按键（NSEvent global monitor）
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            let keyCode = event.keyCode
            var modifiers: UInt32 = 0
            
            if event.modifierFlags.contains(.command) {
                modifiers |= UInt32(cmdKey)
            }
            if event.modifierFlags.contains(.shift) {
                modifiers |= UInt32(shiftKey)
            }
            if event.modifierFlags.contains(.option) {
                modifiers |= UInt32(optionKey)
            }
            if event.modifierFlags.contains(.control) {
                modifiers |= UInt32(controlKey)
            }
            
            // 至少要有一个修饰键
              if modifiers == 0 {
                  return
              }
            
            // 转成可读名称，回传给Flutter
            let displayName = self.buildHotkeyName(event: event)
            let result: [String: Any] = [
                "keyCode": keyCode,
                "modifiers": modifiers,
                "displayName": displayName
            ]
            self.channel?.invokeMethod("onHotkeyCaptured", arguments: result)
        }
    }
    
    /// 停止录制
    func stopRecord() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    /// 拼接快捷键文字 Cmd+Shift+V
    private func buildHotkeyName(event: NSEvent) -> String {
        var parts: [String] = []
        let flags = event.modifierFlags
        if flags.contains(.command) { parts.append("Cmd") }
        if flags.contains(.shift) { parts.append("Shift") }
        if flags.contains(.option) { parts.append("Alt") }
        if flags.contains(.control) { parts.append("Ctrl") }
        
        // 字符转换
        let chars = event.charactersIgnoringModifiers ?? ""
        parts.append(chars.uppercased())
        return parts.joined(separator: "+")
    }
}
