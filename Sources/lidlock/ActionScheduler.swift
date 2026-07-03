import Foundation

/// Schedules the configured action after the lid closes, and cancels it if the
/// lid reopens before the delay elapses.
final class ActionScheduler {
  private let prefs: Preferences
  private let hasExternalDisplay: () -> Bool
  private var pendingWork: DispatchWorkItem?

  init(
    preferences: Preferences = .shared,
    hasExternalDisplay: @escaping () -> Bool = DisplayMonitor.hasExternalDisplay
  ) {
    self.prefs = preferences
    self.hasExternalDisplay = hasExternalDisplay
  }

  func lidClosed() {
    guard shouldAct() else { return }

    cancel()

    let action = prefs.action
    let delay = prefs.delaySeconds
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.pendingWork = nil
      // Re-check conditions at fire time.
      guard self.shouldAct() else { return }
      Log.scheduler.info("executing \(action.rawValue, privacy: .public)")
      ActionExecutor.perform(action)
    }
    pendingWork = work

    Log.scheduler.info(
      "scheduling \(action.rawValue, privacy: .public) in \(delay, privacy: .public)s")
    if delay <= 0 {
      DispatchQueue.main.async(execute: work)
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + Double(delay), execute: work)
    }
  }

  func lidOpened() {
    cancel()
  }

  /// Returns true when the configured action should run. Called both at
  /// lid-close time and re-checked when the scheduled work fires.
  private func shouldAct() -> Bool {
    guard prefs.enabled else {
      Log.scheduler.info("disabled; ignoring lid close")
      return false
    }
    guard hasExternalDisplay() else {
      Log.scheduler.info("no external display; ignoring lid close")
      return false
    }
    return true
  }

  private func cancel() {
    pendingWork?.cancel()
    pendingWork = nil
  }
}
