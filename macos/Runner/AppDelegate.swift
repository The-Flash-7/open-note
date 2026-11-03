import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var cliChannel: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    // SIGPIPE 免疫（纵深防御）：真机实证 spawn 不存在的二进制路径时
    // dart:io 原生层会在平台线程触发 SIGPIPE 直接杀死应用且无崩溃报告
    //（Flutter 的 Dart VM 不支持 ProcessSignal.sigpipe.watch()，只能在
    // 原生层忽略）。Dart 侧另有存在性前置守卫做根因防护
    signal(SIGPIPE, SIG_IGN)

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
    // 注意：不可调用 super.applicationDidFinishLaunching——本 Flutter 版本的
    // FlutterAppDelegate 未实现该方法，调用即抛 unrecognized selector
    // （真机实证：每次启动都被 AppKit 捕获记录 FAULT）
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
