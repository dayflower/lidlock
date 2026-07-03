import SwiftUI

@main
struct LidLockApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  @ObservedObject private var prefs = Preferences.shared
  @ObservedObject private var loginItem = LoginItem.shared

  var body: some Scene {
    MenuBarExtra("LidLock", systemImage: "lock.laptopcomputer") {
      Toggle("Enabled", isOn: $prefs.enabled)

      Divider()

      Menu("Action") {
        Picker("Action", selection: $prefs.action) {
          ForEach(LidAction.allCases) { action in
            Text(action.title).tag(action)
          }
        }
        .pickerStyle(.inline)
        .labelsHidden()
      }

      Menu("Delay") {
        Picker("Delay", selection: $prefs.delaySeconds) {
          ForEach(Preferences.delayOptions, id: \.self) { seconds in
            Text("\(seconds) sec").tag(seconds)
          }
        }
        .pickerStyle(.inline)
        .labelsHidden()
      }

      Menu("Options") {
        Toggle(
          "Launch at Login",
          isOn: Binding(
            get: { loginItem.isEnabled },
            set: { _ in loginItem.toggle() }
          ))
      }

      Divider()

      Text("LidLock v\(AppInfo.version)")

      Button("Quit") {
        NSApplication.shared.terminate(nil)
      }
    }
    .menuBarExtraStyle(.menu)
  }
}
