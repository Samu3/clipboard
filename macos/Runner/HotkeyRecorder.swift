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
    var channel: FlutterMethodChannel?
    
    private var globalMonitor: Any?
       private var localMonitor: Any?
    
    /// 开始录制全局按键
    func startRecord() {
        stopRecord()
        // 本地监听：当前App窗口内按键（弹窗前台录制，核心！）
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeyDown(event: event)
            return event
        }
        
        // 全局监听：焦点在其他App时按键
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.onKeyDown(event: event)
        }

    }
    
    private func onKeyDown(event: NSEvent) {
          let keyCode = event.keyCode
          var modifiers: UInt32 = 0
          
          if event.modifierFlags.contains(.command) {
              modifiers |= cmdKey
          }
          if event.modifierFlags.contains(.shift) {
              modifiers |= shiftKey
          }
          if event.modifierFlags.contains(.option) {
              modifiers |= optionKey
          }
          if event.modifierFlags.contains(.control) {
              modifiers |= controlKey
          }
        
          
          // 必须带修饰键，过滤单独字母
          guard modifiers > 0 else { return }
          
          let displayName = buildHotkeyName(event: event)
        print(displayName)

          let result: [String: Any] = [
              "keyCode": keyCode,
              "modifiers": modifiers,
              "displayName": displayName
          ]
          channel?.invokeMethod("onHotkeyCaptured", arguments: result)
      }
      
    
    /// 停止录制
    func stopRecord() {
        if let g = globalMonitor {
                   NSEvent.removeMonitor(g)
                   globalMonitor = nil
               }
               if let l = localMonitor {
                   NSEvent.removeMonitor(l)
                   localMonitor = nil
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
