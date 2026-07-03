import Foundation

/// Executes the configured action: locking the screen or sleeping the system.
enum ActionExecutor {
  static func perform(_ action: LidAction) {
    switch action {
    case .lock: lockScreen()
    case .sleep: sleepSystem()
    }
  }

  private typealias LockScreenFunc = @convention(c) () -> Int32

  /// Locks the screen immediately using the private `SACLockScreenImmediate`
  /// from `login.framework`. If the symbol cannot be resolved (e.g. removed
  /// in a future macOS), this is a safe no-op.
  private static let lockScreenFunc: LockScreenFunc? = {
    let path = "/System/Library/PrivateFrameworks/login.framework/Versions/Current/login"
    guard let handle = dlopen(path, RTLD_NOW) else {
      Log.executor.error("dlopen login.framework failed")
      return nil
    }
    guard let symbol = dlsym(handle, "SACLockScreenImmediate") else {
      Log.executor.error("SACLockScreenImmediate not found")
      return nil
    }
    return unsafeBitCast(symbol, to: LockScreenFunc.self)
  }()

  private static func lockScreen() {
    guard let lock = lockScreenFunc else {
      Log.executor.error("lock unavailable; skipping")
      return
    }
    _ = lock()
  }

  private static func sleepSystem() {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
    process.arguments = ["sleepnow"]
    do {
      try process.run()
    } catch {
      Log.executor.error("pmset sleepnow failed: \(error.localizedDescription, privacy: .public)")
    }
  }
}
