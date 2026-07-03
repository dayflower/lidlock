import Foundation
import IOKit

/// Observes the laptop lid (clamshell) open/close state via IOKit.
///
/// The `AppleClamshellState` property on `IOPMrootDomain` is `true` when the
/// lid is closed. We register an interest notification and, on each callback,
/// re-read the property to detect open <-> closed transitions.
final class ClamshellMonitor {
  /// Called on the main queue when the lid state changes. `true` = closed.
  var onChange: ((Bool) -> Void)?

  private(set) var isLidClosed = false

  private var rootDomain: io_service_t = 0
  private var notifyPort: IONotificationPortRef?
  private var notification: io_object_t = 0

  deinit {
    stop()
  }

  func start() {
    // Re-entrancy guard: a live `notifyPort` means we are already started.
    // On a failed start we leave `notifyPort` nil so that `start()` can be
    // retried from a clean state.
    guard notifyPort == nil else { return }

    rootDomain = IOServiceGetMatchingService(
      kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
    guard rootDomain != 0 else {
      Log.clamshell.error("IOPMrootDomain not found")
      return
    }

    isLidClosed = readClamshellState() ?? false

    guard let notifyPort = IONotificationPortCreate(kIOMainPortDefault) else {
      Log.clamshell.error("IONotificationPortCreate failed")
      IOObjectRelease(rootDomain)
      rootDomain = 0
      return
    }
    self.notifyPort = notifyPort
    IONotificationPortSetDispatchQueue(notifyPort, DispatchQueue.main)

    let callback: IOServiceInterestCallback = { refcon, _, _, _ in
      guard let refcon else { return }
      let monitor = Unmanaged<ClamshellMonitor>.fromOpaque(refcon).takeUnretainedValue()
      monitor.handleNotification()
    }
    let refcon = Unmanaged.passUnretained(self).toOpaque()
    let result = IOServiceAddInterestNotification(
      notifyPort, rootDomain, kIOGeneralInterest, callback, refcon, &notification
    )
    if result != KERN_SUCCESS {
      Log.clamshell.error("IOServiceAddInterestNotification failed: \(result, privacy: .public)")
    }
  }

  func stop() {
    if notification != 0 {
      IOObjectRelease(notification)
      notification = 0
    }
    if let notifyPort {
      IONotificationPortDestroy(notifyPort)
      self.notifyPort = nil
    }
    if rootDomain != 0 {
      IOObjectRelease(rootDomain)
      rootDomain = 0
    }
  }

  private func handleNotification() {
    guard let state = readClamshellState(), state != isLidClosed else { return }
    isLidClosed = state
    onChange?(state)
  }

  private func readClamshellState() -> Bool? {
    guard rootDomain != 0,
      let value = IORegistryEntryCreateCFProperty(
        rootDomain, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0
      )?.takeRetainedValue()
    else {
      return nil
    }
    return (value as? NSNumber)?.boolValue
  }
}
