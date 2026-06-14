import SwiftUI
import WidgetKit

struct ReminderHomeWidget: Widget {
  let kind: String = ReminderHomeWidgetShared.widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ReminderHomeWidgetTimelineProvider()) { entry in
      ReminderHomeWidgetView(entry: entry)
    }
    .configurationDisplayName("Reminder Home")
    .description("查看需要處理、要留意與今天已完成事項。")
    .supportedFamilies([.systemLarge])
  }
}
