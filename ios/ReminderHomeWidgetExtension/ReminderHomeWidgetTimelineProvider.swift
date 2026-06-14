import WidgetKit

struct ReminderHomeWidgetTimelineEntry: TimelineEntry {
  let date: Date
  let state: ReminderHomeWidgetSnapshotState
}

struct ReminderHomeWidgetTimelineProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReminderHomeWidgetTimelineEntry {
    ReminderHomeWidgetTimelineEntry(date: Date(), state: .unavailable(.missing))
  }

  func getSnapshot(
    in context: Context,
    completion: @escaping (ReminderHomeWidgetTimelineEntry) -> Void
  ) {
    completion(ReminderHomeWidgetTimelineEntry(date: Date(), state: ReminderHomeWidgetSnapshotReader.read()))
  }

  func getTimeline(
    in context: Context,
    completion: @escaping (Timeline<ReminderHomeWidgetTimelineEntry>) -> Void
  ) {
    let entry = ReminderHomeWidgetTimelineEntry(date: Date(), state: ReminderHomeWidgetSnapshotReader.read())
    completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
  }
}
