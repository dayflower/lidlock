import Foundation
import os

/// Unified logging categories for the app.
///
/// Logs are grouped under the bundle identifier subsystem so they can be
/// filtered with, e.g., `log stream --predicate 'subsystem == "com.dayflower.lidlock"'`.
enum Log {
  private static let subsystem =
    Bundle.main.bundleIdentifier ?? "com.dayflower.lidlock"

  static let clamshell = Logger(subsystem: subsystem, category: "clamshell")
  static let scheduler = Logger(subsystem: subsystem, category: "scheduler")
  static let executor = Logger(subsystem: subsystem, category: "executor")
  static let loginItem = Logger(subsystem: subsystem, category: "loginItem")
  static let app = Logger(subsystem: subsystem, category: "app")
}
