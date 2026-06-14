import Foundation

struct ReminderHomeWidgetSnapshot: Decodable {
  let schemaVersion: Int
  let updatedAt: Date?
  let selectedTab: String
  let tabs: [ReminderHomeWidgetTab]

  enum CodingKeys: String, CodingKey {
    case schemaVersion
    case updatedAt
    case selectedTab
    case tabs
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    let updatedAtSource = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    updatedAt = ReminderHomeWidgetDateParser.parse(updatedAtSource)
    selectedTab = try container.decodeIfPresent(String.self, forKey: .selectedTab) ?? ReminderHomeWidgetShared.needsHandling
    tabs = try container.decodeIfPresent([ReminderHomeWidgetTab].self, forKey: .tabs) ?? []
  }

  func tab(_ id: String) -> ReminderHomeWidgetTab? {
    tabs.first { $0.id == id }
  }
}

struct ReminderHomeWidgetTab: Decodable, Identifiable {
  let id: String
  let label: String
  let count: Int
  let entries: [ReminderHomeWidgetEntry]
}

struct ReminderHomeWidgetEntry: Decodable, Identifiable {
  var id: String { entryId }

  let entryId: String
  let type: String
  let targetId: Int?
  let actionRecordId: Int?
  let title: String
  let statusText: String
  let displayIcon: String?
  let buttonText: String?
  let action: String?
  let canAct: Bool
}

enum ReminderHomeWidgetSnapshotState {
  case ready(ReminderHomeWidgetSnapshot)
  case unavailable(ReminderHomeWidgetSnapshotProblem)
}

enum ReminderHomeWidgetSnapshotProblem {
  case missing
  case corrupt
  case unsupportedSchema
  case stale

  var title: String {
    switch self {
    case .missing: return "尚未有 widget 資料"
    case .corrupt: return "widget 資料讀取失敗"
    case .unsupportedSchema: return "widget 資料需要更新"
    case .stale: return "widget 資料已過期"
    }
  }
}

enum ReminderHomeWidgetSnapshotReader {
  static let supportedSchemaVersion = 1
  static let staleInterval: TimeInterval = 24 * 60 * 60

  static func read(now: Date = Date()) -> ReminderHomeWidgetSnapshotState {
    guard let url = ReminderHomeWidgetShared.snapshotURL else {
      return .unavailable(.missing)
    }
    guard FileManager.default.fileExists(atPath: url.path) else {
      return .unavailable(.missing)
    }

    do {
      let data = try Data(contentsOf: url)
      let snapshot = try JSONDecoder().decode(ReminderHomeWidgetSnapshot.self, from: data)
      guard snapshot.schemaVersion == supportedSchemaVersion else {
        return .unavailable(.unsupportedSchema)
      }
      guard let updatedAt = snapshot.updatedAt, now.timeIntervalSince(updatedAt) <= staleInterval else {
        return .unavailable(.stale)
      }
      return .ready(snapshot)
    } catch {
      return .unavailable(.corrupt)
    }
  }
}

enum ReminderHomeWidgetDateParser {
  static func parse(_ source: String?) -> Date? {
    guard let source, !source.isEmpty else { return nil }
    if let date = ISO8601DateFormatter().date(from: source) {
      return date
    }
    for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone.current
      formatter.dateFormat = format
      if let date = formatter.date(from: source) {
        return date
      }
    }
    return nil
  }
}
