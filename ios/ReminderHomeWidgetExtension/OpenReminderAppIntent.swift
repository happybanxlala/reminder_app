import AppIntents

struct OpenReminderAppIntent: AppIntent {
  static var title: LocalizedStringResource = "打開 Reminder App"
  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult {
    return .result()
  }
}
