import AppIntents
import SwiftUI
import WidgetKit

struct ReminderHomeWidgetView: View {
  let entry: ReminderHomeWidgetTimelineEntry

  var body: some View {
    switch entry.state {
    case .ready(let snapshot):
      WidgetShell {
        SnapshotContentView(snapshot: snapshot)
      }
    case .unavailable(let problem):
      WidgetShell {
        WidgetFallbackView(problem: problem)
      }
    }
  }
}

private enum HomeWidgetDesignTokens {
  static let appBackground = Color(hex: 0xFAF5EA)
  static let surfaceCard = Color(hex: 0xFFFDF8)
  static let surfaceWarm = Color(hex: 0xFFF7E8)
  static let surfaceMuted = Color(hex: 0xF7EDE0)
  static let primaryWarm = Color(hex: 0xD9852B)
  static let primaryWarmDark = Color(hex: 0xB86712)
  static let primaryWarmContainer = Color(hex: 0xFFE8BC)
  static let statusNormal = Color(hex: 0x6F9A55)
  static let statusNormalContainer = Color(hex: 0xEAF4DF)
  static let statusWarning = Color(hex: 0xE09620)
  static let statusWarningContainer = Color(hex: 0xFFF0CF)
  static let statusDanger = Color(hex: 0xD96B5F)
  static let statusDangerContainer = Color(hex: 0xFFE6E1)
  static let domainResource = Color(hex: 0xB98542)
  static let domainStage = Color(hex: 0x7FA77B)
  static let borderSubtle = Color(hex: 0xE9DDC8)
  static let textPrimary = Color(hex: 0x2F241D)
  static let textSecondary = Color(hex: 0x6F6256)
  static let textMuted = Color(hex: 0xA09589)

  static let shellRadius: CGFloat = 24
  static let cardRadius: CGFloat = 16
  static let chipRadius: CGFloat = 14
  static let iconRadius: CGFloat = 10
  static let railWidth: CGFloat = 6
  static let borderWidth: CGFloat = 1
  static let packIconSize: CGFloat = 27
  static let actionSize: CGFloat = 32
}

private struct WidgetShell<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    ZStack {
      HomeWidgetDesignTokens.appBackground
      content
        .padding(14)
    }
    .containerBackground(HomeWidgetDesignTokens.appBackground, for: .widget)
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
          WidgetEmptyState(text: ReminderHomeWidgetShared.emptyText(for: selectedTab.id))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          VStack(spacing: 7) {
            ForEach(Array(selectedTab.entries.prefix(3))) { row in
              WidgetEntryCard(entry: row, selectedTabId: selectedTab.id)
            }
          }
          .frame(maxHeight: .infinity, alignment: .top)
        }
      } else {
        WidgetEmptyState(text: "尚未有 widget 資料")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
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
        TabChip(tab: tab, isSelected: tab.id == selectedTabId)
      }
    }
  }
}

private struct TabChip: View {
  let tab: ReminderHomeWidgetTab
  let isSelected: Bool

  var body: some View {
    Button(intent: SwitchHomeWidgetTabIntent(tab: tab.id)) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 4) {
          Image(systemName: iconName)
            .font(.caption2.weight(.bold))
            .imageScale(.small)
          Text(tab.label)
            .font(.system(size: 10.5, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
        }
        Text("\(tab.count)")
          .font(.system(size: 15, weight: .heavy, design: .rounded))
          .monospacedDigit()
      }
      .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
      .padding(.horizontal, 8)
      .padding(.vertical, 6)
      .background(
        RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.chipRadius, style: .continuous)
          .fill(backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.chipRadius, style: .continuous)
          .stroke(borderColor, lineWidth: HomeWidgetDesignTokens.borderWidth)
      )
    }
    .buttonStyle(.plain)
    .foregroundStyle(foregroundColor)
  }

  private var iconName: String {
    switch tab.id {
    case ReminderHomeWidgetShared.needsHandling:
      return isSelected ? "exclamationmark.circle.fill" : "exclamationmark.circle"
    case ReminderHomeWidgetShared.attention:
      return isSelected ? "eye.fill" : "eye"
    case ReminderHomeWidgetShared.todayCompleted:
      return isSelected ? "checkmark.circle.fill" : "checkmark.circle"
    default:
      return "circle"
    }
  }

  private var foregroundColor: Color {
    isSelected ? accentColor : HomeWidgetDesignTokens.textSecondary
  }

  private var backgroundColor: Color {
    if isSelected {
      return selectedBackgroundColor
    }
    return HomeWidgetDesignTokens.surfaceWarm
  }

  private var borderColor: Color {
    isSelected ? accentColor.opacity(0.28) : HomeWidgetDesignTokens.borderSubtle
  }

  private var selectedBackgroundColor: Color {
    switch tab.id {
    case ReminderHomeWidgetShared.needsHandling:
      return HomeWidgetDesignTokens.statusDangerContainer
    case ReminderHomeWidgetShared.attention:
      return HomeWidgetDesignTokens.statusWarningContainer
    case ReminderHomeWidgetShared.todayCompleted:
      return HomeWidgetDesignTokens.statusNormalContainer
    default:
      return HomeWidgetDesignTokens.primaryWarmContainer
    }
  }

  private var accentColor: Color {
    switch tab.id {
    case ReminderHomeWidgetShared.needsHandling:
      return HomeWidgetDesignTokens.statusDanger
    case ReminderHomeWidgetShared.attention:
      return HomeWidgetDesignTokens.statusWarning
    case ReminderHomeWidgetShared.todayCompleted:
      return HomeWidgetDesignTokens.statusNormal
    default:
      return HomeWidgetDesignTokens.primaryWarm
    }
  }
}

private struct WidgetEntryCard: View {
  let entry: ReminderHomeWidgetEntry
  let selectedTabId: String

  var body: some View {
    HStack(spacing: 0) {
      Rectangle()
        .fill(railColor)
        .frame(width: HomeWidgetDesignTokens.railWidth)

      HStack(alignment: .center, spacing: 8) {
        PackIconChip(entry: entry, accentColor: railColor)

        VStack(alignment: .leading, spacing: 3) {
          Text(entry.title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(HomeWidgetDesignTokens.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
          Text(statusLine)
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(HomeWidgetDesignTokens.textSecondary)
            .lineLimit(1)
            .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        actionButton
      }
      .padding(.leading, 8)
      .padding(.trailing, 9)
      .padding(.vertical, 9)
    }
    .background(HomeWidgetDesignTokens.surfaceCard)
    .clipShape(RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.cardRadius, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.cardRadius, style: .continuous)
        .stroke(HomeWidgetDesignTokens.borderSubtle, lineWidth: HomeWidgetDesignTokens.borderWidth)
    )
    .shadow(color: Color.black.opacity(0.045), radius: 9, x: 0, y: 4)
  }

  @ViewBuilder
  private var actionButton: some View {
    if entry.canAct, let action = entry.action {
      switch action {
      case "complete", "undo", "add":
        Link(
          destination: ReminderHomeWidgetShared.actionURL(
            action: action,
            entryId: entry.entryId
          )
        ) {
          WidgetIconActionButton(action: action)
        }
      default:
        EmptyView()
      }
    }
  }

  private var railColor: Color {
    switch selectedTabId {
    case ReminderHomeWidgetShared.needsHandling:
      return HomeWidgetDesignTokens.statusDanger
    case ReminderHomeWidgetShared.attention:
      return HomeWidgetDesignTokens.statusWarning
    case ReminderHomeWidgetShared.todayCompleted:
      return completedColor
    default:
      return fallbackTypeColor
    }
  }

  private var completedColor: Color {
    switch entry.type {
    case "completedResource":
      return HomeWidgetDesignTokens.domainResource
    case "completedStage":
      return HomeWidgetDesignTokens.domainStage
    default:
      return HomeWidgetDesignTokens.statusNormal
    }
  }

  private var fallbackTypeColor: Color {
    switch entry.type {
    case "resourceAttention", "completedResource":
      return HomeWidgetDesignTokens.domainResource
    case "completedStage":
      return HomeWidgetDesignTokens.domainStage
    default:
      return HomeWidgetDesignTokens.primaryWarm
    }
  }

  private var statusLine: String {
    guard let syncLabel = entry.syncLabel, !syncLabel.isEmpty else {
      return entry.statusText
    }
    return "\(entry.statusText) · \(syncLabel)"
  }
}

private struct PackIconChip: View {
  let entry: ReminderHomeWidgetEntry
  let accentColor: Color

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .fill(HomeWidgetDesignTokens.surfaceWarm)
        .overlay(
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(HomeWidgetDesignTokens.borderSubtle, lineWidth: HomeWidgetDesignTokens.borderWidth)
        )

      if let displayIcon = entry.displayIcon, !displayIcon.isEmpty {
        Text(displayIcon)
          .font(.system(size: 15))
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      } else {
        Image(systemName: fallbackIconName)
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(accentColor)
      }
    }
    .frame(width: HomeWidgetDesignTokens.packIconSize, height: HomeWidgetDesignTokens.packIconSize)
  }

  private var fallbackIconName: String {
    switch entry.type {
    case "resourceAttention", "completedResource":
      return "plus.circle"
    case "completedStage":
      return "calendar.badge.checkmark"
    case "completedItem":
      return "checkmark.circle"
    default:
      return "checklist"
    }
  }
}

private struct WidgetIconActionButton: View {
  let action: String

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.iconRadius, style: .continuous)
        .fill(backgroundColor)
        .overlay(
          RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.iconRadius, style: .continuous)
            .stroke(borderColor, lineWidth: HomeWidgetDesignTokens.borderWidth)
        )
      Image(systemName: iconName)
        .font(.system(size: 13, weight: .heavy))
        .foregroundStyle(iconColor)
    }
    .frame(width: HomeWidgetDesignTokens.actionSize, height: HomeWidgetDesignTokens.actionSize)
  }

  private var iconName: String {
    switch action {
    case "undo":
      return "arrow.uturn.backward"
    case "add":
      return "plus"
    default:
      return "checkmark"
    }
  }

  private var iconColor: Color {
    switch action {
    case "undo":
      return HomeWidgetDesignTokens.primaryWarmDark
    case "add":
      return HomeWidgetDesignTokens.domainResource
    default:
      return HomeWidgetDesignTokens.statusNormal
    }
  }

  private var backgroundColor: Color {
    switch action {
    case "undo":
      return HomeWidgetDesignTokens.primaryWarmContainer.opacity(0.72)
    case "add":
      return HomeWidgetDesignTokens.surfaceMuted
    default:
      return HomeWidgetDesignTokens.statusNormalContainer
    }
  }

  private var borderColor: Color {
    iconColor.opacity(0.22)
  }
}

private struct WidgetEmptyState: View {
  let text: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "checkmark.circle")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(HomeWidgetDesignTokens.statusNormal)
      Text(text)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(HomeWidgetDesignTokens.textSecondary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.cardRadius, style: .continuous)
        .fill(HomeWidgetDesignTokens.surfaceWarm)
    )
    .overlay(
      RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.cardRadius, style: .continuous)
        .stroke(HomeWidgetDesignTokens.borderSubtle, lineWidth: HomeWidgetDesignTokens.borderWidth)
    )
  }
}

private struct WidgetFallbackView: View {
  let problem: ReminderHomeWidgetSnapshotProblem

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "exclamationmark.circle")
          .foregroundStyle(HomeWidgetDesignTokens.primaryWarm)
        Text(problem.title)
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(HomeWidgetDesignTokens.textPrimary)
      }

      Text("打開 app 以更新主畫面 widget。")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(HomeWidgetDesignTokens.textSecondary)
        .lineLimit(2)

      Spacer()

      Link(destination: ReminderHomeWidgetShared.openAppURL) {
        HStack {
          Image(systemName: "arrow.up.forward.app")
            .font(.system(size: 13, weight: .bold))
          Text("打開 app")
            .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(HomeWidgetDesignTokens.primaryWarmDark)
        .frame(maxWidth: .infinity, minHeight: 38)
        .background(
          RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.chipRadius, style: .continuous)
            .fill(HomeWidgetDesignTokens.primaryWarmContainer)
        )
        .overlay(
          RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.chipRadius, style: .continuous)
            .stroke(HomeWidgetDesignTokens.primaryWarm.opacity(0.22), lineWidth: HomeWidgetDesignTokens.borderWidth)
        )
      }
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.shellRadius, style: .continuous)
        .fill(HomeWidgetDesignTokens.surfaceCard)
    )
    .overlay(
      RoundedRectangle(cornerRadius: HomeWidgetDesignTokens.shellRadius, style: .continuous)
        .stroke(HomeWidgetDesignTokens.borderSubtle, lineWidth: HomeWidgetDesignTokens.borderWidth)
    )
  }
}

private extension Color {
  init(hex: UInt32) {
    self.init(
      red: Double((hex >> 16) & 0xFF) / 255.0,
      green: Double((hex >> 8) & 0xFF) / 255.0,
      blue: Double(hex & 0xFF) / 255.0
    )
  }
}
