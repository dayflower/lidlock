import AppKit
import ServiceManagement

/// Wraps `SMAppService.mainApp` to manage launch-at-login registration.
final class LoginItem: ObservableObject {
  static let shared = LoginItem()

  @Published private(set) var isEnabled = false

  private var trackingObserver: NSObjectProtocol?

  private init() {
    refresh()
    // The menu-bar item is our only menu, so refresh whenever it starts
    // tracking to catch changes made in System Settings > Login Items.
    trackingObserver = NotificationCenter.default.addObserver(
      forName: NSMenu.didBeginTrackingNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.refresh()
    }
  }

  deinit {
    if let trackingObserver {
      NotificationCenter.default.removeObserver(trackingObserver)
    }
  }

  func refresh() {
    let newValue = SMAppService.mainApp.status == .enabled
    if isEnabled != newValue {
      isEnabled = newValue
    }
  }

  func toggle() {
    do {
      if SMAppService.mainApp.status == .enabled {
        try SMAppService.mainApp.unregister()
      } else {
        try SMAppService.mainApp.register()
      }
    } catch {
      Log.loginItem.error(
        "login item toggle failed: \(error.localizedDescription, privacy: .public)")
    }
    refresh()
  }
}
