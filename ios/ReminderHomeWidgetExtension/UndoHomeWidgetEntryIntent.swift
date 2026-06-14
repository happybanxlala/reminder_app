import AppIntents
import Foundation

struct UndoHomeWidgetEntryIntent: AppIntent {
  static var title: LocalizedStringResource = "復原完成"
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Entry ID")
  var entryId: String

  init() {
    entryId = ""
  }

  init(entryId: String) {
    self.entryId = entryId
  }

  func perform() async throws -> some IntentResult {
    let trimmedEntryId = entryId.trimmingCharacters(in: .whitespacesAndNewlines)
    if !trimmedEntryId.isEmpty {
      _ = ReminderHomeWidgetShared.writePendingAction(
        "undo",
        entryId: trimmedEntryId
      )
      ReminderHomeWidgetShared.reloadWidget()
    } else {
      #if DEBUG
      print("ReminderHomeWidget undo intent ignored blank entry id")
      #endif
    }
    return .result()
  }
}
