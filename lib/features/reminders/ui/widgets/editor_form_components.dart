import 'package:flutter/material.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import 'reminder_components.dart';

class ReminderEditorScaffold extends StatelessWidget {
  const ReminderEditorScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomBar,
    this.actions,
  });

  final String title;
  final Widget body;
  final Widget? bottomBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: bottomBar,
    );
  }
}

class ReminderEditorSection extends StatefulWidget {
  const ReminderEditorSection({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.toggleKey,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool collapsible;
  final bool initiallyExpanded;
  final Key? toggleKey;

  @override
  State<ReminderEditorSection> createState() => _ReminderEditorSectionState();
}

class _ReminderEditorSectionState extends State<ReminderEditorSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return ReminderPaperCard(
      padding: const EdgeInsets.all(ReminderSpacing.cardCompact),
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: widget.toggleKey,
            onTap: widget.collapsible
                ? () => setState(() {
                    _expanded = !_expanded;
                  })
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: widget.collapsible
                  ? const EdgeInsets.symmetric(vertical: 2)
                  : EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: palette.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 12),
                    widget.trailing!,
                  ],
                  if (widget.collapsible)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: palette.textSecondary,
                    ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.children.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._withGaps(widget.children),
          ],
        ],
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> children) {
    return [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0) const SizedBox(height: 12),
        children[index],
      ],
    ];
  }
}

class ReminderEditorAdvancedSection extends StatelessWidget {
  const ReminderEditorAdvancedSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
    this.toggleKey,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Key? toggleKey;

  @override
  Widget build(BuildContext context) {
    return ReminderEditorSection(
      title: title,
      subtitle: subtitle,
      collapsible: true,
      initiallyExpanded: initiallyExpanded,
      toggleKey: toggleKey,
      children: children,
    );
  }
}

class ReminderEditorPickerRow extends StatelessWidget {
  const ReminderEditorPickerRow({
    super.key,
    required this.label,
    required this.value,
    this.leading,
    this.onTap,
    this.readOnly = false,
    this.showChevron = true,
    this.errorText,
  });

  final String label;
  final String value;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool showChevron;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final enabled = onTap != null && !readOnly;
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              key: const Key('editor-picker-row-value'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (enabled && showChevron) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: palette.textMuted),
          ],
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: row,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class ReminderEditorDateRow extends StatelessWidget {
  const ReminderEditorDateRow({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ReminderEditorPickerRow(
      label: label,
      value: ReminderFormatters.date(date),
      onTap: onTap,
      leading: Icon(
        Icons.calendar_today_outlined,
        size: 18,
        color: context.reminderPalette.primaryWarm,
      ),
    );
  }
}

class ReminderEditorNumberField extends StatelessWidget {
  const ReminderEditorNumberField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.label,
    this.prefixText,
    this.suffixText,
    this.helperText,
    this.minimum = 0,
    this.onChanged,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String label;
  final String? prefixText;
  final String? suffixText;
  final String? helperText;
  final int minimum;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        suffixText: suffixText,
        helperText: helperText,
      ),
      onChanged: (_) => onChanged?.call(),
      validator: (value) {
        final parsed = int.tryParse((value ?? '').trim());
        if (parsed == null || parsed < minimum) {
          return minimum <= 0 ? '請輸入 0 或以上整數' : '請輸入 $minimum 或以上整數';
        }
        return null;
      },
    );
  }
}

class ReminderEditorSelectableCard extends StatelessWidget {
  const ReminderEditorSelectableCard({
    super.key,
    required this.selected,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    final borderColor = selected ? palette.primaryWarm : palette.borderSubtle;
    final backgroundColor = selected
        ? palette.primaryWarmContainer.withValues(alpha: 0.44)
        : palette.surfaceCard;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: palette.primaryWarmDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, size: 20, color: palette.primaryWarm),
            ],
          ),
        ),
      ),
    );
  }
}

class ReminderEditorBottomBar extends StatelessWidget {
  const ReminderEditorBottomBar({
    super.key,
    required this.onSave,
    this.enabled = true,
    this.loading = false,
  });

  final VoidCallback? onSave;
  final bool enabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = context.reminderPalette;
    return SafeArea(
      key: const Key('editor-bottom-save-bar'),
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: palette.appBackground,
          border: Border(top: BorderSide(color: palette.borderSubtle)),
        ),
        child: FilledButton(
          key: const Key('save-button'),
          onPressed: enabled && !loading ? onSave : null,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(ReminderUiText.saveAction),
        ),
      ),
    );
  }
}
