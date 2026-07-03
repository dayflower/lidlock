import CoreGraphics

/// Detects whether an external display is currently connected.
enum DisplayMonitor {
  /// Returns `true` if any online display is not the built-in panel.
  ///
  /// `NSScreen.screens` cannot be used here: when the lid is closed the
  /// built-in panel is disabled and only external displays remain listed,
  /// so a simple count would be misleading. Instead we enumerate the online
  /// displays and look for one that is not built-in.
  static func hasExternalDisplay() -> Bool {
    var count: UInt32 = 0
    guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else {
      return false
    }

    var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
    guard CGGetOnlineDisplayList(count, &displays, &count) == .success else {
      return false
    }

    return displays.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) == 0 }
  }
}
