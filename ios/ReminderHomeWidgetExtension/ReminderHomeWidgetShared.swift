import Foundation
import WidgetKit

enum ReminderHomeWidgetShared {
  static let widgetKind = "ReminderHomeWidget"
  static let appGroupId = "group.com.example.reminderApp.homeWidget"
  static let openAppURL = URL(string: "reminderapp://home-widget-action")!
  static let snapshotFileName = "home_widget_snapshot.json"
  static let selectedTabKey = "selected_tab"
  static let pendingActionKey = "pending_action"
  static let pendingEntryIdKey = "pending_entry_id"
  static let pendingActionCreatedAtKey = "pending_action_created_at"
  static let pendingActionNonceKey = "pending_action_nonce"

  static let needsHandling = "needsHandling"
  static let attention = "attention"
  static let todayCompleted = "todayCompleted"

  static func actionURL(action: String, entryId: String) -> URL {
    var components = URLComponents(url: openAppURL, resolvingAgainstBaseURL: false)!
    components.queryItems = [
      URLQueryItem(name: "homeWidgetAction", value: action),
      URLQueryItem(name: "homeWidgetEntryId", value: entryId),
    ]
    return components.url ?? openAppURL
  }

  static var appGroupDefaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  static var snapshotURL: URL? {
    FileManager.default
      .containerURL(forSecurityApplicationGroupIdentifier: appGroupId)?
      .appendingPathComponent(snapshotFileName)
  }

  static func selectedTab(fallback: String) -> String {
    let stored = appGroupDefaults?.string(forKey: selectedTabKey)
    return isKnownTab(stored) ? stored! : (isKnownTab(fallback) ? fallback : needsHandling)
  }

  static func persistSelectedTab(_ tab: String) {
    guard isKnownTab(tab) else { return }
    appGroupDefaults?.set(tab, forKey: selectedTabKey)
  }

  @discardableResult
  static func writePendingAction(_ action: String, entryId: String) -> Bool {
    guard let defaults = appGroupDefaults else {
      return false
    }
    let nonce = UUID().uuidString
    defaults.set(action, forKey: pendingActionKey)
    defaults.set(entryId, forKey: pendingEntryIdKey)
    defaults.set(Date().timeIntervalSince1970, forKey: pendingActionCreatedAtKey)
    defaults.set(nonce, forKey: pendingActionNonceKey)
    let persisted = defaults.synchronize()
    #if DEBUG
    print("ReminderHomeWidget pending action write action=\(action) entryId=\(entryId) nonce=\(nonce) persisted=\(persisted)")
    #endif
    return persisted
  }

  static func reloadWidget() {
    WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
  }

  static func isKnownTab(_ value: String?) -> Bool {
    value == needsHandling || value == attention || value == todayCompleted
  }

  static func label(for tab: String) -> String {
    switch tab {
    case needsHandling: return "需要處理"
    case attention: return "要留意"
    case todayCompleted: return "今天已完成"
    default: return "需要處理"
    }
  }

  static func emptyText(for tab: String) -> String {
    switch tab {
    case needsHandling: return "沒有需要處理"
    case attention: return "沒有要留意"
    case todayCompleted: return "今天還未完成事項"
    default: return "沒有需要處理"
    }
  }
}
