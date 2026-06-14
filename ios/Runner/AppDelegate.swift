import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let homeWidgetAppGroupId = "group.com.example.reminderApp.homeWidget"
  private let homeWidgetKind = "ReminderHomeWidget"
  private let pendingActionKey = "pending_action"
  private let pendingEntryIdKey = "pending_entry_id"
  private let pendingActionCreatedAtKey = "pending_action_created_at"
  private let pendingActionNonceKey = "pending_action_nonce"
  private var homeWidgetChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerHomeWidgetChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme == "reminderapp" {
      persistPendingHomeWidgetAction(from: url)
      homeWidgetChannel?.invokeMethod(
        "homeWidgetPendingActionAvailable",
        arguments: nil
      )
      #if DEBUG
      print("ReminderHomeWidget opened Runner with url=\(url.absoluteString)")
      #endif
      return true
    }
    return super.application(app, open: url, options: options)
  }

  private func registerHomeWidgetChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "reminder_app/home_widget",
      binaryMessenger: controller.binaryMessenger
    )
    homeWidgetChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: "AppDelegate unavailable", details: nil))
        return
      }
      switch call.method {
      case "appGroupContainerPath":
        guard
          let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: self.homeWidgetAppGroupId
          )
        else {
          result(nil)
          return
        }
        result(url.path)
      case "reloadHomeWidgets":
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadTimelines(ofKind: self.homeWidgetKind)
        }
        result(nil)
      case "readAndClearPendingAction":
        result(self.readAndClearPendingHomeWidgetAction())
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func persistPendingHomeWidgetAction(from url: URL) {
    guard
      url.host == "home-widget-action",
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let action = components.queryItems?.first(where: { $0.name == "homeWidgetAction" })?.value,
      let entryId = components.queryItems?.first(where: { $0.name == "homeWidgetEntryId" })?.value,
      !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      !entryId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      let defaults = UserDefaults(suiteName: homeWidgetAppGroupId)
    else {
      #if DEBUG
      print("ReminderHomeWidget ignored invalid widget URL action=\(url.absoluteString)")
      #endif
      return
    }

    let nonce = UUID().uuidString
    defaults.set(action, forKey: pendingActionKey)
    defaults.set(entryId, forKey: pendingEntryIdKey)
    defaults.set(Date().timeIntervalSince1970, forKey: pendingActionCreatedAtKey)
    defaults.set(nonce, forKey: pendingActionNonceKey)
    defaults.synchronize()
    #if DEBUG
    print("ReminderHomeWidget persisted URL action action=\(action) entryId=\(entryId) nonce=\(nonce)")
    #endif
  }

  private func readAndClearPendingHomeWidgetAction() -> [String: Any]? {
    guard let defaults = UserDefaults(suiteName: homeWidgetAppGroupId) else {
      return nil
    }

    let action = defaults.string(forKey: pendingActionKey)
    let entryId = defaults.string(forKey: pendingEntryIdKey)
    let createdAt = defaults.object(forKey: pendingActionCreatedAtKey) as? Double
    let nonce = defaults.string(forKey: pendingActionNonceKey)

    defaults.removeObject(forKey: pendingActionKey)
    defaults.removeObject(forKey: pendingEntryIdKey)
    defaults.removeObject(forKey: pendingActionCreatedAtKey)
    defaults.removeObject(forKey: pendingActionNonceKey)

    if action == nil && entryId == nil && nonce == nil {
      return nil
    }

    var payload: [String: Any] = [
      "action": action ?? "",
      "entryId": entryId ?? "",
      "sourcePlatform": "ios",
    ]
    if let createdAt {
      payload["createdAt"] = Int(createdAt * 1000)
    }
    if let nonce {
      payload["nonce"] = nonce
    }
    #if DEBUG
    print("ReminderHomeWidget read pending action payload=\(payload)")
    #endif
    return payload
  }
}
