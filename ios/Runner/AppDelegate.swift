import UIKit
import Flutter
import Photos

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.clipboard/ios", binaryMessenger: controller.binaryMessenger)
      var lastReadChangeCount: Int?
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "readClipboard", "readClipboardIfChanged":
          guard application.applicationState == .active else {
            result(nil)
            return
          }
          let board = UIPasteboard.general
          let changeCount = board.changeCount
          if call.method == "readClipboardIfChanged", lastReadChangeCount == changeCount {
            result(nil)
            return
          }
          // Record before reading: a paste permission dialog can suspend/resume
          // the app. Do not repeatedly prompt for the same clipboard contents.
          lastReadChangeCount = changeCount
          if let image = board.image, let bytes = image.pngData() {
            result(["type": "image", "bytes": FlutterStandardTypedData(bytes: bytes)])
          } else if let text = board.string, !text.isEmpty {
            result(["type": "text", "text": text])
          } else {
            result(nil)
          }
        case "syncKeyboardTexts":
          guard let entries = call.arguments as? [[String: Any]],
                let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.lefu.xinxx.test") else {
            result(FlutterError(code: "shared_container", message: "键盘共享容器不可用，请检查 App Groups 配置", details: nil))
            return
          }
          do {
            let data = try JSONSerialization.data(withJSONObject: entries)
            try data.write(to: root.appendingPathComponent("keyboard-texts.json"), options: .atomic)
            result(true)
          } catch {
            result(FlutterError(code: "keyboard_sync", message: error.localizedDescription, details: nil))
          }
        case "saveImageToPhotos":
          guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String,
                FileManager.default.fileExists(atPath: path),
                UIImage(contentsOfFile: path) != nil else {
            result(FlutterError(code: "invalid_image", message: "图片不存在或已损坏", details: nil))
            return
          }
          PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
              DispatchQueue.main.async {
                result(FlutterError(code: "photos_permission", message: "请在系统设置中允许 ClipSync 添加照片", details: nil))
              }
              return
            }
            PHPhotoLibrary.shared().performChanges({
              let request = PHAssetCreationRequest.forAsset()
              request.addResource(with: .photo, fileURL: URL(fileURLWithPath: path), options: nil)
            }) { success, error in
              DispatchQueue.main.async {
                if success {
                  result(true)
                } else {
                  result(FlutterError(code: "photos_save_failed", message: error?.localizedDescription ?? "保存失败，请重试", details: nil))
                }
              }
            }
          }
        case "copyFile":
          guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String else {
            result(FlutterError(code: "invalid_arguments", message: "缺少文件路径", details: nil))
            return
          }
          let url = URL(fileURLWithPath: path)
          guard FileManager.default.fileExists(atPath: path) else {
            result(FlutterError(code: "missing_file", message: "文件不存在", details: nil))
            return
          }
          if args["type"] as? String == "image" {
            guard let image = UIImage(contentsOfFile: path) else {
              result(false)
              return
            }
            UIPasteboard.general.image = image
          } else {
            guard let provider = NSItemProvider(contentsOf: url) else {
              result(false)
              return
            }
            provider.suggestedName = url.lastPathComponent
            UIPasteboard.general.setItemProviders([provider], localOnly: false, expirationDate: nil)
          }
          result(true)
        case "shareFile":
          guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String,
                FileManager.default.fileExists(atPath: path) else {
            result(FlutterError(code: "missing_file", message: "文件不存在", details: nil))
            return
          }
          self.presentShareSheet(items: [URL(fileURLWithPath: path)], from: controller)
          result(true)
        case "shareText":
          guard let args = call.arguments as? [String: Any],
                let text = args["text"] as? String else {
            result(false)
            return
          }
          self.presentShareSheet(items: [text], from: controller)
          result(true)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func presentShareSheet(items: [Any], from controller: UIViewController) {
    let share = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let popover = share.popoverPresentationController {
      popover.sourceView = controller.view
      popover.sourceRect = CGRect(x: controller.view.bounds.midX,
                                  y: controller.view.bounds.maxY,
                                  width: 1, height: 1)
    }
    controller.present(share, animated: true)
  }
}
