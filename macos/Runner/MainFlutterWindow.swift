import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var clipboardMonitor: ClipboardMonitor?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "com.clipboard/channel",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    clipboardMonitor = ClipboardMonitor(channel: channel)
    clipboardMonitor?.startMonitoring()
    
    
    

    super.awakeFromNib()
  }

  deinit {
    clipboardMonitor?.stopMonitoring()
  }
}
