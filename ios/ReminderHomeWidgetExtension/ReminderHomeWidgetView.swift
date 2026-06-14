import AppIntents
import SwiftUI
import WidgetKit

struct ReminderHomeWidgetView: View {
  let entry: ReminderHomeWidgetTimelineEntry

  var body: some View {
    switch entry.state {
    case .ready(let snapshot):
      SnapshotContentView(snapshot: snapshot)
    case .unavailable(let problem):
      FallbackView(problem: problem)
    }
  }
}

private struct SnapshotContentView: View {
  let snapshot: ReminderHomeWidgetSnapshot

  private var selectedTabId: String {
    ReminderHomeWidgetShared.selectedTab(fallback: snapshot.selectedTab)
  }

  private var selectedTab: ReminderHomeWidgetTab? {
    snapshot.tab(selectedTabId) ?? snapshot.tabs.first
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      TabBarView(tabs: snapshot.tabs, selectedTabId: selectedTabId)

      if let selectedTab {
        if selectedTab.entries.isEmpty {
          EmptyStateView(text: ReminderHomeWidgetShared.emptyText(for: selectedTab.id))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          VStack(spacing: 7) {
            ForEach(selectedTab.entries.prefix(5)) { row in
              RowView(entry: row)
            }
          }
        }
      } else {
        EmptyStateView(text: "尚未有 widget 資料")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .padding(14)
    .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.94), for: .widget)
  }
}

private struct TabBarView: View {
  let tabs: [ReminderHomeWidgetTab]
  let selectedTabId: String

  private var visibleTabs: [ReminderHomeWidgetTab] {
    let ids = [
      ReminderHomeWidgetShared.needsHandling,
      ReminderHomeWidgetShared.attention,
      ReminderHomeWidgetShared.todayCompleted,
    ]
    return ids.map { id in
      tabs.first { $0.id == id }
        ?? ReminderHomeWidgetTab(id: id, label: ReminderHomeWidgetShared.label(for: id), count: 0, entries: [])
    }
  }

  var body: some View {
    HStack(spacing: 6) {
      ForEach(visibleTabs) { tab in
        Button(intent: SwitchHomeWidgetTabIntent(tab: tab.id)) {
          VStack(spacing: 2) {
            Text(tab.label)
              .font(.caption2.weight(.semibold))
              .lineLimit(1)
              .minimumScaleFactor(0.8)
            Text("\(tab.count)")
              .font(.caption2)
              .monospacedDigit()
          }
          .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(tab.id == selectedTabId ? Color(red: 0.14, green: 0.20, blue: 0.18) : Color(red: 0.42, green: 0.43, blue: 0.39))
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(tab.id == selectedTabId ? Color(red: 0.86, green: 0.91, blue: 0.86) : Color(red: 0.94, green: 0.93, blue: 0.89))
        )
      }
    }
  }
}

private struct RowView: View {
  let entry: ReminderHomeWidgetEntry

  var body: some View {
    HStack(alignment: .center, spacing: 8) {
      VStack(alignment: .leading, spacing: 3) {
        Text(entry.title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color(red: 0.14, green: 0.15, blue: 0.13))
          .lineLimit(1)
        Text(entry.statusText)
          .font(.caption)
          .foregroundStyle(Color(red: 0.43, green: 0.44, blue: 0.40))
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      actionButton
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(red: 1.0, green: 0.995, blue: 0.97))
        .stroke(Color(red: 0.88, green: 0.86, blue: 0.80), lineWidth: 0.7)
    )
  }

  @ViewBuilder
  private var actionButton: some View {
    if entry.canAct, let buttonText = entry.buttonText, let action = entry.action {
      switch action {
      case "complete":
        Link(
          destination: ReminderHomeWidgetShared.actionURL(
            action: action,
            entryId: entry.entryId
          )
        ) {
          ActionLabel(text: buttonText)
        }
      case "undo":
        Link(
          destination: ReminderHomeWidgetShared.actionURL(
            action: action,
            entryId: entry.entryId
          )
        ) {
          ActionLabel(text: buttonText)
        }
      default:
        EmptyView()
      }
    }
  }
}

private struct ActionLabel: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.caption.weight(.semibold))
      .foregroundStyle(Color(red: 0.13, green: 0.24, blue: 0.20))
      .lineLimit(1)
      .padding(.horizontal, 10)
      .frame(height: 28)
      .background(
        RoundedRectangle(cornerRadius: 7)
          .fill(Color(red: 0.86, green: 0.91, blue: 0.86))
      )
  }
}

private struct EmptyStateView: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.subheadline.weight(.medium))
      .foregroundStyle(Color(red: 0.47, green: 0.47, blue: 0.42))
      .multilineTextAlignment(.center)
  }
}

private struct FallbackView: View {
  let problem: ReminderHomeWidgetSnapshotProblem

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(problem.title)
        .font(.headline)
        .foregroundStyle(Color(red: 0.15, green: 0.16, blue: 0.14))
      Text("打開 app 以更新主畫面 widget。")
        .font(.subheadline)
        .foregroundStyle(Color(red: 0.43, green: 0.44, blue: 0.40))
      Spacer()
      Link(destination: ReminderHomeWidgetShared.openAppURL) {
        Text("打開 app")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color(red: 0.13, green: 0.24, blue: 0.20))
          .frame(maxWidth: .infinity, minHeight: 36)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(red: 0.86, green: 0.91, blue: 0.86))
          )
      }
    }
    .padding(16)
    .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.94), for: .widget)
  }
}
