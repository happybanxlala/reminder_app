import 'package:flutter/material.dart';

@immutable
class ReminderPalette extends ThemeExtension<ReminderPalette> {
  const ReminderPalette({
    required this.appBackground,
    required this.surfaceCard,
    required this.surfaceWarm,
    required this.surfaceMuted,
    required this.primaryWarm,
    required this.primaryWarmDark,
    required this.primaryWarmContainer,
    required this.statusNormal,
    required this.statusNormalContainer,
    required this.statusWarning,
    required this.statusWarningContainer,
    required this.statusDanger,
    required this.statusDangerContainer,
    required this.statusUnknown,
    required this.statusUnknownContainer,
    required this.domainItem,
    required this.domainResource,
    required this.domainStage,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color appBackground;
  final Color surfaceCard;
  final Color surfaceWarm;
  final Color surfaceMuted;
  final Color primaryWarm;
  final Color primaryWarmDark;
  final Color primaryWarmContainer;
  final Color statusNormal;
  final Color statusNormalContainer;
  final Color statusWarning;
  final Color statusWarningContainer;
  final Color statusDanger;
  final Color statusDangerContainer;
  final Color statusUnknown;
  final Color statusUnknownContainer;
  final Color domainItem;
  final Color domainResource;
  final Color domainStage;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  static const light = ReminderPalette(
    appBackground: Color(0xFFFAF5EA),
    surfaceCard: Color(0xFFFFFDF8),
    surfaceWarm: Color(0xFFFFF7E8),
    surfaceMuted: Color(0xFFF7EDE0),
    primaryWarm: Color(0xFFD9852B),
    primaryWarmDark: Color(0xFFB86712),
    primaryWarmContainer: Color(0xFFFFE8BC),
    statusNormal: Color(0xFF6F9A55),
    statusNormalContainer: Color(0xFFEAF4DF),
    statusWarning: Color(0xFFE09620),
    statusWarningContainer: Color(0xFFFFF0CF),
    statusDanger: Color(0xFFD96B5F),
    statusDangerContainer: Color(0xFFFFE6E1),
    statusUnknown: Color(0xFFA89F94),
    statusUnknownContainer: Color(0xFFF0EAE3),
    domainItem: Color(0xFFD9852B),
    domainResource: Color(0xFFB98542),
    domainStage: Color(0xFF7FA77B),
    borderSubtle: Color(0xFFE9DDC8),
    textPrimary: Color(0xFF2F241D),
    textSecondary: Color(0xFF6F6256),
    textMuted: Color(0xFFA09589),
  );

  @override
  ReminderPalette copyWith({
    Color? appBackground,
    Color? surfaceCard,
    Color? surfaceWarm,
    Color? surfaceMuted,
    Color? primaryWarm,
    Color? primaryWarmDark,
    Color? primaryWarmContainer,
    Color? statusNormal,
    Color? statusNormalContainer,
    Color? statusWarning,
    Color? statusWarningContainer,
    Color? statusDanger,
    Color? statusDangerContainer,
    Color? statusUnknown,
    Color? statusUnknownContainer,
    Color? domainItem,
    Color? domainResource,
    Color? domainStage,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return ReminderPalette(
      appBackground: appBackground ?? this.appBackground,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceWarm: surfaceWarm ?? this.surfaceWarm,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primaryWarm: primaryWarm ?? this.primaryWarm,
      primaryWarmDark: primaryWarmDark ?? this.primaryWarmDark,
      primaryWarmContainer: primaryWarmContainer ?? this.primaryWarmContainer,
      statusNormal: statusNormal ?? this.statusNormal,
      statusNormalContainer:
          statusNormalContainer ?? this.statusNormalContainer,
      statusWarning: statusWarning ?? this.statusWarning,
      statusWarningContainer:
          statusWarningContainer ?? this.statusWarningContainer,
      statusDanger: statusDanger ?? this.statusDanger,
      statusDangerContainer:
          statusDangerContainer ?? this.statusDangerContainer,
      statusUnknown: statusUnknown ?? this.statusUnknown,
      statusUnknownContainer:
          statusUnknownContainer ?? this.statusUnknownContainer,
      domainItem: domainItem ?? this.domainItem,
      domainResource: domainResource ?? this.domainResource,
      domainStage: domainStage ?? this.domainStage,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ReminderPalette lerp(ThemeExtension<ReminderPalette>? other, double t) {
    if (other is! ReminderPalette) {
      return this;
    }
    return ReminderPalette(
      appBackground: Color.lerp(appBackground, other.appBackground, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceWarm: Color.lerp(surfaceWarm, other.surfaceWarm, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primaryWarm: Color.lerp(primaryWarm, other.primaryWarm, t)!,
      primaryWarmDark: Color.lerp(primaryWarmDark, other.primaryWarmDark, t)!,
      primaryWarmContainer: Color.lerp(
        primaryWarmContainer,
        other.primaryWarmContainer,
        t,
      )!,
      statusNormal: Color.lerp(statusNormal, other.statusNormal, t)!,
      statusNormalContainer: Color.lerp(
        statusNormalContainer,
        other.statusNormalContainer,
        t,
      )!,
      statusWarning: Color.lerp(statusWarning, other.statusWarning, t)!,
      statusWarningContainer: Color.lerp(
        statusWarningContainer,
        other.statusWarningContainer,
        t,
      )!,
      statusDanger: Color.lerp(statusDanger, other.statusDanger, t)!,
      statusDangerContainer: Color.lerp(
        statusDangerContainer,
        other.statusDangerContainer,
        t,
      )!,
      statusUnknown: Color.lerp(statusUnknown, other.statusUnknown, t)!,
      statusUnknownContainer: Color.lerp(
        statusUnknownContainer,
        other.statusUnknownContainer,
        t,
      )!,
      domainItem: Color.lerp(domainItem, other.domainItem, t)!,
      domainResource: Color.lerp(domainResource, other.domainResource, t)!,
      domainStage: Color.lerp(domainStage, other.domainStage, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

class ReminderSpacing {
  const ReminderSpacing._();

  static const page = 16.0;
  static const section = 20.0;
  static const card = 16.0;
  static const cardCompact = 12.0;
  static const inline = 8.0;
  static const listGap = 12.0;
}

class ReminderRadius {
  const ReminderRadius._();

  static const card = 20.0;
  static const section = 24.0;
  static const badge = 999.0;
  static const button = 18.0;
  static const input = 16.0;
}

extension ReminderThemeContext on BuildContext {
  ReminderPalette get reminderPalette =>
      Theme.of(this).extension<ReminderPalette>() ?? ReminderPalette.light;
}

class ReminderTheme {
  const ReminderTheme._();

  static ThemeData light() {
    const palette = ReminderPalette.light;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.primaryWarm,
      brightness: Brightness.light,
      primary: palette.primaryWarm,
      onPrimary: Colors.white,
      primaryContainer: palette.primaryWarmContainer,
      onPrimaryContainer: palette.textPrimary,
      secondary: palette.domainStage,
      surface: palette.surfaceCard,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.surfaceMuted,
      onSurfaceVariant: palette.textSecondary,
      error: palette.statusDanger,
    );

    final base = ThemeData(
      colorScheme: colorScheme,
      extensions: const [palette],
      scaffoldBackgroundColor: palette.appBackground,
      useMaterial3: true,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(color: palette.textMuted),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.appBackground,
        foregroundColor: palette.textPrimary,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReminderRadius.card),
          side: BorderSide(color: palette.borderSubtle),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primaryWarm,
          foregroundColor: Colors.white,
          disabledBackgroundColor: palette.surfaceMuted,
          disabledForegroundColor: palette.textMuted,
          elevation: 2,
          shadowColor: palette.primaryWarm.withValues(alpha: 0.20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ReminderRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primaryWarmDark,
          side: BorderSide(color: palette.primaryWarm),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ReminderRadius.button),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryWarmDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ReminderRadius.button),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceCard,
        selectedColor: palette.primaryWarmContainer,
        disabledColor: palette.surfaceMuted,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: palette.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: palette.primaryWarmDark,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: palette.borderSubtle),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ReminderRadius.badge),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReminderRadius.input),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReminderRadius.input),
          borderSide: BorderSide(color: palette.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ReminderRadius.input),
          borderSide: BorderSide(color: palette.primaryWarm, width: 1.4),
        ),
        labelStyle: TextStyle(color: palette.textSecondary),
        helperStyle: TextStyle(color: palette.textMuted),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: palette.surfaceCard,
        foregroundColor: palette.primaryWarm,
        elevation: 2,
        shape: CircleBorder(side: BorderSide(color: palette.borderSubtle)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surfaceCard,
        indicatorColor: palette.primaryWarmContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? palette.primaryWarmDark : palette.textSecondary,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.primaryWarm : palette.textSecondary,
          );
        }),
      ),
      dividerTheme: DividerThemeData(color: palette.borderSubtle),
      listTileTheme: ListTileThemeData(
        iconColor: palette.primaryWarm,
        textColor: palette.textPrimary,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
