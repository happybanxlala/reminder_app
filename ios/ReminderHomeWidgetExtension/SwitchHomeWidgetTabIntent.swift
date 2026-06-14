import AppIntents

struct SwitchHomeWidgetTabIntent: AppIntent {
  static var title: LocalizedStringResource = "切換 widget 分頁"

  @Parameter(title: "Tab")
  var tab: String

  init() {
    tab = ReminderHomeWidgetShared.needsHandling
  }

  init(tab: String) {
    self.tab = tab
  }

  func perform() async throws -> some IntentResult {
    ReminderHomeWidgetShared.persistSelectedTab(tab)
    ReminderHomeWidgetShared.reloadWidget()
    return .result()
  }
}
