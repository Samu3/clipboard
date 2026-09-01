import Cocoa
import FlutterMacOS
import Foundation

class ClipboardMonitor {
    private var changeCount: Int
    private var timer: Timer?
    private var channel: FlutterMethodChannel?
    private let pasteboard = NSPasteboard.general
    // 临时目录（给文件类型使用）
    private let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.changeCount = pasteboard.changeCount
        
        self.setupMethodCall()
        
      
    }
    
    func setupMethodCall(){
        self.channel?.setMethodCallHandler { [weak self] call, result in
                   if call.method == "copyImageToPasteboard" {
                       guard let args = call.arguments as? [String:Any],
                             let filePath = args["filePath"] as? String else {
                           result(false)
                           return
                       }
                       let url = URL(fileURLWithPath: filePath)
                       guard let image = NSImage(contentsOf: url) else {
                           result(false)
                           return
                       }
                       let pasteboard = NSPasteboard.general
                       pasteboard.clearContents()
                       pasteboard.writeObjects([image])
                       result(true)
                   }
                   // 保留你原有 onClipboardChange 逻辑
               }
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        if currentChangeCount != changeCount {
            let oldCount = changeCount
            changeCount = currentChangeCount
            print("📊 粘贴板 changeCount: \(oldCount) -> \(currentChangeCount)")

            // 【重点】优先判断文件！
            if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL], !fileURLs.isEmpty {
               notifyFileChange(fileURLs)
           }else  if let image = getImageFromPasteboard() {
                       notifyImageChange(image)
                   } else if let string = pasteboard.string(forType: .string) {
                       notifyTextChange(string)
                   }
        }
    }

    private func notifyTextChange(_ text: String) {
        let args: [String: Any] = [
            "type": "text",
            "payload": ["text": text]
        ]
        channel?.invokeMethod("onClipboardChange", arguments: args)
    }

    private func notifyImageChange(_ image: NSImage, originFileName: String? = nil) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return
        }
        let uuid = UUID().uuidString
        // 获取沙盒Caches根目录
        let cachesRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        // 追加一层 bundleId，和Flutter getApplicationCacheDirectory对齐
        let bundleId = Bundle.main.bundleIdentifier!
        let targetCacheDir = cachesRoot.appendingPathComponent(bundleId)

        // 创建文件夹（不存在自动新建）
        do {
            try FileManager.default.createDirectory(at: targetCacheDir, withIntermediateDirectories: true)
        } catch {
            print("缓存目录创建失败：\(error)")
            return
        }
        
        let fileURL = targetCacheDir.appendingPathComponent("\(uuid).png")
        do {
            try pngData.write(to: fileURL)
            let filePath = fileURL.path
            let args: [String: Any] = [
                "type": "image",
                "payload": [
                    "filePath": filePath,
                    "fileName": originFileName ?? "图片.png"
                ]
            ]
            channel?.invokeMethod("onClipboardChange", arguments: args)
        } catch {
            print("图片写入缓存目录失败：\(error)")
        }
    }

    /// 文件：复制到临时目录，返回临时文件路径数组
    private func notifyFileChange(_ urls: [URL]) {
        var tempFilePaths: [String] = []
        for srcUrl in urls {
            let fileName = srcUrl.lastPathComponent
            let uuidName = "\(UUID().uuidString)-\(fileName)"
            let destUrl = tempDir.appendingPathComponent(uuidName)
            
            notifyTextChange(srcUrl.absoluteString)
//            // Mac沙盒关键：访问粘贴板文件安全书签
//            let accessGranted = srcUrl.startAccessingSecurityScopedResource()
//            defer {
//                if accessGranted {
//                    srcUrl.stopAccessingSecurityScopedResource()
//                }
//            }
//            
//            if !accessGranted {
//                print("⚠️ 文件无法获取安全访问权限: \(srcUrl.path)")
//                continue
//            }
//            
//            do {
//                try FileManager.default.copyItem(at: srcUrl, to: destUrl)
//                tempFilePaths.append(destUrl.path)
//                print("✅ 文件复制成功: \(destUrl.path)")
//            } catch {
//                print("❌ 文件复制失败 \(srcUrl.path): \(error)")
//            }
        }
        
        if tempFilePaths.isEmpty {
            return
        }
        
        let args: [String: Any] = [
            "type": "file",
            "payload": ["filePaths": tempFilePaths]
        ]
        channel?.invokeMethod("onClipboardChange", arguments: args)
    }

    private func getImageFromPasteboard() -> NSImage? {
        if let image = NSImage(pasteboard: pasteboard) {
            return image
        }
        if let data = pasteboard.data(forType: .tiff),
           let image = NSImage(data: data) {
            return image
        }
        if let data = pasteboard.data(forType: .png),
           let image = NSImage(data: data) {
            return image
        }
        return nil
    }
}
