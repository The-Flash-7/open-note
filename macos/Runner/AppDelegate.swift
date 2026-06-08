import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var cliChannel: FlutterMethodChannel?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    guard let window = mainFlutterWindow,
          let controller = window.contentViewController as? FlutterViewController else { return }
    
    cliChannel = FlutterMethodChannel(
      name: "cli_installer",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    // 添加 "安装 CLI 工具" 菜单项到应用菜单
    if let mainMenu = NSApplication.shared.mainMenu,
       let appMenuItem = mainMenu.items.first {
      let separator = NSMenuItem.separator()
      appMenuItem.submenu?.addItem(separator)
      
      let installCLIItem = NSMenuItem(
        title: "安装 CLI 工具",
        action: #selector(installCLIClicked),
        keyEquivalent: ""
      )
      appMenuItem.submenu?.addItem(installCLIItem)
    }
    
    super.applicationDidFinishLaunching(notification)
  }
  
  @objc private func installCLIClicked() {
    cliChannel?.invokeMethod("triggerInstallCLI", arguments: nil)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
