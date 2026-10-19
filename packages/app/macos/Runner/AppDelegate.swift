import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  /// The app menu's items, sent to Dart (HomeScreen listens).
  private var appMenu: FlutterMethodChannel?

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    registerAppMenuChannel()
  }

  private func registerAppMenuChannel() {
    guard let window = mainFlutterWindow,
          let controller = window.contentViewController as? FlutterViewController
    else { return }
    appMenu = FlutterMethodChannel(
      name: "mollygram/app_menu",
      binaryMessenger: controller.engine.binaryMessenger)
  }

  /// "Settings…" (⌘,) in the app menu (MainMenu.xib). Dart answers only
  /// while signed in; before that the item does nothing.
  @IBAction func openSettings(_ sender: Any?) {
    mainFlutterWindow?.makeKeyAndOrderFront(nil)
    appMenu?.invokeMethod("openSettings", arguments: nil)
  }
}
