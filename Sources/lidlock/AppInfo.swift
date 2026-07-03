import Foundation

/// Static information about the app bundle.
enum AppInfo {
  /// App version from the bundle's Info.plist, or "dev" when unbundled.
  static let version =
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
}
