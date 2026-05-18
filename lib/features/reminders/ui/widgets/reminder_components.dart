import 'package:flutter/material.dart';

import '../../../../app/theme/reminder_theme.dart';

class ReminderPaperCard extends StatelessWidget {
  const ReminderPaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ReminderSpacing.card),
    this.margin = EdgeInsets.zero,
    this.backgroundColor,
    this.borderColor,
    this.radius = ReminderRadius.card,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surfaceCard,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? palette.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    return Material(
      color: Colors.transparent,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: content,
            ),
    );
  }
}

class ReminderRailCard extends StatelessWidget {
  const ReminderRailCard({
    super.key,
    required this.railColor,
    required this.child,
    this.padding = const EdgeInsets.all(ReminderSpacing.card),
    this.radius = ReminderRadius.card,
    this.onTap,
  });

  final Color railColor;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ReminderPaperCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      radius: radius,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(width: 6, color: railColor),
              ),
            ),
            Padding(
              padding: padding.add(const EdgeInsets.only(left: 6)),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderBadge extends StatelessWidget {
  const ReminderBadge({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final foreground = color ?? palette.primaryWarmDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.primaryWarmContainer,
        borderRadius: BorderRadius.circular(ReminderRadius.badge),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ReminderIconBubble extends StatelessWidget {
  const ReminderIconBubble({
    super.key,
    required this.child,
    this.size = 56,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surfaceWarm,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor ?? palette.borderSubtle),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(fontSize: size * 0.46),
        child: child,
      ),
    );
  }
}

class ReminderSectionHeader extends StatelessWidget {
  const ReminderSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: palette.primaryWarm),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    );
  }
}

class ReminderEmptyState extends StatelessWidget {
  const ReminderEmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      backgroundColor: palette.surfaceWarm,
      padding: const EdgeInsets.all(ReminderSpacing.cardCompact),
      child: Row(
        children: [
          Icon(icon ?? Icons.check_circle_outline, color: palette.statusNormal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class ReminderFooterMark extends StatelessWidget {
  const ReminderFooterMark({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          '一點進度，每天都看得見。',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

class ReminderTimelineDots extends StatelessWidget {
  const ReminderTimelineDots({
    super.key,
    required this.labels,
    required this.activeIndex,
  });

  final List<String> labels;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final cappedIndex = activeIndex.clamp(0, labels.length - 1);
    return Column(
      children: [
        Row(
          children: [
            for (var index = 0; index < labels.length; index++) ...[
              _TimelineDot(active: index <= cappedIndex),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < cappedIndex
                        ? palette.statusNormal
                        : palette.borderSubtle,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final label in labels)
              Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: active ? palette.statusNormal : palette.surfaceMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? palette.statusNormal : palette.borderSubtle,
          width: 2,
        ),
      ),
    );
  }
}
