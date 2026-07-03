import Foundation

/// The action to take when the lid is closed while in clamshell mode.
enum LidAction: String, CaseIterable, Identifiable {
  case lock
  case sleep

  var id: String { rawValue }

  var title: String {
    switch self {
    case .lock: return "Lock"
    case .sleep: return "Sleep"
    }
  }
}

/// User-configurable settings, persisted in `UserDefaults`.
final class Preferences: ObservableObject {
  static let shared = Preferences()

  /// Selectable delays, in seconds, before the action fires.
  static let delayOptions = [0, 1, 2, 5, 10]

  private let defaults = UserDefaults.standard

  private enum Key {
    static let action = "action"
    static let delaySeconds = "delaySeconds"
    static let enabled = "enabled"
  }

  @Published var action: LidAction {
    didSet { defaults.set(action.rawValue, forKey: Key.action) }
  }

  @Published var delaySeconds: Int {
    didSet { defaults.set(delaySeconds, forKey: Key.delaySeconds) }
  }

  /// When disabled, closing the lid does nothing.
  @Published var enabled: Bool {
    didSet { defaults.set(enabled, forKey: Key.enabled) }
  }

  private init() {
    defaults.register(defaults: [Key.delaySeconds: 0, Key.enabled: true])
    action = LidAction(rawValue: defaults.string(forKey: Key.action) ?? "") ?? .lock
    delaySeconds = defaults.integer(forKey: Key.delaySeconds)
    enabled = defaults.bool(forKey: Key.enabled)
  }
}
