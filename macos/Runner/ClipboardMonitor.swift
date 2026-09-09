import Cocoa
import FlutterMacOS
import Foundation
import AVFoundation

class ClipboardMonitor {
    private var changeCount: Int
    private var timer: Timer?
    private var channel: FlutterMethodChannel?
    private let pasteboard = NSPasteboard.general
    public var skipNextPasteboardChange = false
    


    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.changeCount = pasteboard.changeCount

        // 设置 HotkeyRecorder 的 channel

        self.setupMethodCall()


    }
    
    func setupMethodCall(){
        self.channel?.setMethodCallHandler { [weak self] call, result in
            
            guard let `self` = self else { return }
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
                
                self.skipNextPasteboardChange = true
            } else if call.method == "copyFilesToPasteboard" {
                guard let args = call.arguments as? [String: Any],
                      let filePaths = args["filePaths"] as? [String] else {
                    result(false)
                    return
                }
                let urls = filePaths
                    .map { URL(fileURLWithPath: $0) }
                    .filter { FileManager.default.fileExists(atPath: $0.path) }
                guard !urls.isEmpty else {
                    result(false)
                    return
                }
                pasteboard.clearContents()
                let succeeded = pasteboard.writeObjects(urls as [NSURL])
                self.skipNextPasteboardChange = succeeded
                result(succeeded)
            } else if call.method == "convertVideoForPlayback" {
                guard let args = call.arguments as? [String: Any],
                      let path = args["path"] as? String else {
                    result(FlutterError(code: "invalid_video", message: "缺少视频路径", details: nil))
                    return
                }
                self.convertVideo(path: path, result: result)
            }
              
        }
    }

    private func convertVideo(path: String, result: @escaping FlutterResult) {
        let asset = AVURLAsset(url: URL(fileURLWithPath: path))
        guard let exporter = AVAssetExportSession(asset: asset,
                                                   presetName: AVAssetExportPreset1280x720) else {
            result(FlutterError(code: "video_convert", message: "当前视频编码无法转换", details: nil))
            return
        }
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        exporter.outputURL = output
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                if exporter.status == .completed {
                    result(output.path)
                } else {
                    result(FlutterError(code: "video_convert",
                                        message: exporter.error?.localizedDescription ?? "视频转换失败",
                                        details: nil))
                }
            }
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
            if skipNextPasteboardChange {
                  skipNextPasteboardChange = false
                  return
              }
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

    /// 文件：保留 Finder 提供的原始路径，用于展示和再次写入剪贴板。
    private func notifyFileChange(_ urls: [URL]) {
        let filePaths = urls.filter(\.isFileURL).map(\.path)
        guard !filePaths.isEmpty else { return }
        let args: [String: Any] = [
            "type": "file",
            "payload": ["filePaths": filePaths]
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
