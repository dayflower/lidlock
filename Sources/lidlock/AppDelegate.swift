import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private let monitor = ClamshellMonitor()
  private let scheduler = ActionScheduler()

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)

    monitor.onChange = { [weak self] closed in
      Log.app.info("lid \(closed ? "closed" : "opened", privacy: .public)")
      if closed {
        self?.scheduler.lidClosed()
      } else {
        self?.scheduler.lidOpened()
      }
    }
    monitor.start()
  }

  func applicationWillTerminate(_ notification: Notification) {
    monitor.stop()
  }
}
