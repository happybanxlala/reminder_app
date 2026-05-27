part of 'item_config_form_section.dart';

class RepeatRuleSheet extends StatefulWidget {
  const RepeatRuleSheet({
    super.key,
    required this.initialRule,
    required this.anchorDate,
    required this.dueDate,
  });

  final RepeatRuleV2? initialRule;
  final DateTime anchorDate;
  final DateTime dueDate;

  @override
  State<RepeatRuleSheet> createState() => _RepeatRuleSheetState();
}

class _RepeatRuleSheetState extends State<RepeatRuleSheet> {
  late bool _isCustom;
  late RepeatUnit _unit;
  late int _interval;
  late Set<int> _weekdays;
  late Set<int> _monthDays;
  late MonthlyRepeatMode _monthlyMode;
  late MonthlyWeekOrdinal _monthlyOrdinal;
  late int _monthlyWeekday;
  late RepeatEndType _endType;
  late DateTime _endDate;
  late int _endCount;

  @override
  void initState() {
    super.initState();
    final rule = widget.initialRule;
    _isCustom = false;
    _unit = rule?.unit ?? RepeatUnit.day;
    _interval = rule?.interval ?? 1;
    _weekdays = (rule?.weekdays.isNotEmpty ?? false)
        ? rule!.weekdays.toSet()
        : {widget.dueDate.weekday};
    _monthDays = (rule?.monthDays.isNotEmpty ?? false)
        ? rule!.monthDays.toSet()
        : {widget.dueDate.day.clamp(1, 31)};
    _monthlyMode = rule?.kind == RepeatRuleV2Kind.monthlyNthWeekday
        ? MonthlyRepeatMode.nthWeekday
        : MonthlyRepeatMode.dates;
    _monthlyOrdinal =
        rule?.monthlyWeekOrdinal ?? _ordinalForDate(widget.dueDate);
    _monthlyWeekday = rule?.monthlyWeekday ?? widget.dueDate.weekday;
    _endType = rule?.end.type ?? RepeatEndType.never;
    _endDate =
        rule?.end.untilDate ??
        DateTime(
          widget.dueDate.year,
          widget.dueDate.month + 1,
          widget.dueDate.day,
        );
    _endCount = rule?.end.occurrenceCount ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isCustom
              ? _buildCustom(context)
              : _buildQuickOptions(context),
        ),
      ),
    );
  }

  Widget _buildQuickOptions(BuildContext context) {
    final options = <_QuickRepeatOption>[
      const _QuickRepeatOption(
        label: ReminderUiText.noRepeatLabel,
        keyValue: 'never',
        rule: null,
      ),
      _QuickRepeatOption(
        label: '每天',
        keyValue: 'daily',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.day, interval: 1),
      ),
      _QuickRepeatOption(
        label: '每週',
        keyValue: 'weekly',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.week, interval: 1),
      ),
      _QuickRepeatOption(
        label: '每月',
        keyValue: 'monthly',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.month, interval: 1),
      ),
      _QuickRepeatOption(
        label: '每年',
        keyValue: 'yearly',
        rule: RepeatRuleV2.simple(unit: RepeatUnit.year, interval: 1),
      ),
    ];
    return Column(
      key: const ValueKey('quick-repeat-options'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(title: '重複', onBack: null),
        Column(
          children: [
            for (final option in options)
              _RepeatOptionTile(
                key: Key('repeat-option-${option.keyValue}'),
                label: option.label,
                selected: _matchesQuickOption(option.rule),
                onTap: () => Navigator.of(
                  context,
                ).pop(_RepeatRuleSelection(option.rule)),
              ),
            const Divider(height: 1),
            ReminderEditorPickerRow(
              key: const Key('repeat-option-custom'),
              label: '自訂',
              value: '設定頻率、星期與結束條件',
              onTap: () => setState(() {
                _isCustom = true;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showUnitPicker(BuildContext context) async {
    final value = await showModalBottomSheet<RepeatUnit>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('頻率', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final unit in RepeatUnit.values)
              ListTile(
                key: Key('repeat-frequency-${unit.name}'),
                title: Text(_unitTitle(unit)),
                trailing: unit == _unit ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(unit),
              ),
          ],
        ),
      ),
    );
    if (value == null || !context.mounted) {
      return;
    }
    setState(() {
      _unit = value;
    });
  }

  Widget _buildCustom(BuildContext context) {
    final rule = _buildCurrentRule();
    return Column(
      key: const ValueKey('custom-repeat-options'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHeader(
          title: '自訂重複',
          onBack: () => setState(() {
            _isCustom = false;
          }),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ReminderEditorPickerRow(
                  key: const Key('repeat-frequency-field'),
                  label: '頻率',
                  value: _unitTitle(_unit),
                  onTap: () => _showUnitPicker(context),
                ),
                const SizedBox(height: 12),
                _StepperTile(
                  value: _interval,
                  unitLabel: _unitLabel(_unit),
                  onChanged: (value) => setState(() {
                    _interval = value;
                  }),
                ),
                if (_unit == RepeatUnit.week) ...[
                  const SizedBox(height: 12),
                  _WeekdaySection(
                    selected: _weekdays,
                    onChanged: (value) => setState(() {
                      _weekdays = value;
                    }),
                  ),
                ],
                if (_unit == RepeatUnit.month) ...[
                  const SizedBox(height: 12),
                  _MonthlySection(
                    mode: _monthlyMode,
                    monthDays: _monthDays,
                    ordinal: _monthlyOrdinal,
                    weekday: _monthlyWeekday,
                    onModeChanged: (value) => setState(() {
                      _monthlyMode = value;
                    }),
                    onMonthDaysChanged: (value) => setState(() {
                      _monthDays = value;
                    }),
                    onOrdinalChanged: (value) => setState(() {
                      _monthlyOrdinal = value;
                    }),
                    onWeekdayChanged: (value) => setState(() {
                      _monthlyWeekday = value;
                    }),
                  ),
                ],
                const SizedBox(height: 12),
                _EndRepeatSection(
                  endType: _endType,
                  endDate: _endDate,
                  endCount: _endCount,
                  onEndTypeChanged: (value) => setState(() {
                    _endType = value;
                  }),
                  onEndDateChanged: (value) => setState(() {
                    _endDate = value;
                  }),
                  onEndCountChanged: (value) => setState(() {
                    _endCount = value;
                  }),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ReminderFormatters.repeatRuleV2Description(rule),
                    key: const Key('repeat-description'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const Key('repeat-save-custom'),
            onPressed: () =>
                Navigator.of(context).pop(_RepeatRuleSelection(rule)),
            child: const Text('完成'),
          ),
        ),
      ],
    );
  }

  bool _matchesQuickOption(RepeatRuleV2? rule) {
    final initial = widget.initialRule;
    if (initial == null || rule == null) {
      return initial == null && rule == null;
    }
    return initial.kind == RepeatRuleV2Kind.simple &&
        initial.unit == rule.unit &&
        initial.interval == rule.interval &&
        initial.end.isNever;
  }

  RepeatRuleV2 _buildCurrentRule() {
    final end = _buildEndCondition();
    return switch (_unit) {
      RepeatUnit.day => RepeatRuleV2.simple(
        unit: RepeatUnit.day,
        interval: _interval,
        end: end,
      ),
      RepeatUnit.week => RepeatRuleV2.weeklyWeekdays(
        interval: _interval,
        weekdays: _weekdays,
        end: end,
      ),
      RepeatUnit.month =>
        _monthlyMode == MonthlyRepeatMode.dates
            ? RepeatRuleV2.monthlyDates(
                interval: _interval,
                monthDays: _monthDays,
                end: end,
              )
            : RepeatRuleV2.monthlyNthWeekday(
                interval: _interval,
                ordinal: _monthlyOrdinal,
                weekday: _monthlyWeekday,
                end: end,
              ),
      RepeatUnit.year => RepeatRuleV2.simple(
        unit: RepeatUnit.year,
        interval: _interval,
        end: end,
      ),
    };
  }

  RepeatEndCondition _buildEndCondition() {
    return switch (_endType) {
      RepeatEndType.never => const RepeatEndCondition.never(),
      RepeatEndType.onDate => RepeatEndCondition.onDate(_endDate),
      RepeatEndType.afterCount => RepeatEndCondition.afterCount(_endCount),
    };
  }

  String _unitLabel(RepeatUnit unit) {
    return switch (unit) {
      RepeatUnit.day => '天',
      RepeatUnit.week => '週',
      RepeatUnit.month => '個月',
      RepeatUnit.year => '年',
    };
  }

  String _unitTitle(RepeatUnit unit) {
    return switch (unit) {
      RepeatUnit.day => '每天',
      RepeatUnit.week => '每週',
      RepeatUnit.month => '每月',
      RepeatUnit.year => '每年',
    };
  }

  MonthlyWeekOrdinal _ordinalForDate(DateTime value) {
    final ordinal = ((value.day - 1) ~/ 7) + 1;
    return switch (ordinal) {
      1 => MonthlyWeekOrdinal.first,
      2 => MonthlyWeekOrdinal.second,
      3 => MonthlyWeekOrdinal.third,
      4 => MonthlyWeekOrdinal.fourth,
      _ => MonthlyWeekOrdinal.last,
    };
  }
}

class _QuickRepeatOption {
  const _QuickRepeatOption({
    required this.label,
    required this.keyValue,
    required this.rule,
  });

  final String label;
  final String keyValue;
  final RepeatRuleV2? rule;
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _RepeatOptionTile extends StatelessWidget {
  const _RepeatOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check) : null,
      onTap: onTap,
    );
  }
}

class _StepperTile extends StatelessWidget {
  const _StepperTile({
    required this.value,
    required this.unitLabel,
    required this.onChanged,
  });

  final int value;
  final String unitLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('每'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            key: const Key('repeat-interval-decrement'),
            onPressed: value <= 1 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
            tooltip: '減少',
          ),
          SizedBox(
            width: 88,
            child: Text(
              '$value $unitLabel',
              key: const Key('repeat-interval-value'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton.outlined(
            key: const Key('repeat-interval-increment'),
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add),
            tooltip: '增加',
          ),
        ],
      ),
    );
  }
}

class _WeekdaySection extends StatelessWidget {
  const _WeekdaySection({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('星期', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final weekday in _weekdays)
              FilterChip(
                key: Key('repeat-weekday-$weekday'),
                label: Text(_shortWeekday(weekday)),
                selected: selected.contains(weekday),
                onSelected: (value) {
                  final next = {...selected};
                  if (value) {
                    next.add(weekday);
                  } else if (next.length > 1) {
                    next.remove(weekday);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthlySection extends StatelessWidget {
  const _MonthlySection({
    required this.mode,
    required this.monthDays,
    required this.ordinal,
    required this.weekday,
    required this.onModeChanged,
    required this.onMonthDaysChanged,
    required this.onOrdinalChanged,
    required this.onWeekdayChanged,
  });

  final MonthlyRepeatMode mode;
  final Set<int> monthDays;
  final MonthlyWeekOrdinal ordinal;
  final int weekday;
  final ValueChanged<MonthlyRepeatMode> onModeChanged;
  final ValueChanged<Set<int>> onMonthDaysChanged;
  final ValueChanged<MonthlyWeekOrdinal> onOrdinalChanged;
  final ValueChanged<int> onWeekdayChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<MonthlyRepeatMode>(
          key: const Key('repeat-monthly-mode'),
          segments: const [
            ButtonSegment(value: MonthlyRepeatMode.dates, label: Text('日期')),
            ButtonSegment(
              value: MonthlyRepeatMode.nthWeekday,
              label: Text('星期'),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => onModeChanged(value.single),
        ),
        const SizedBox(height: 12),
        if (mode == MonthlyRepeatMode.dates)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var day = 1; day <= 31; day += 1)
                FilterChip(
                  key: Key('repeat-month-day-$day'),
                  label: Text('$day'),
                  selected: monthDays.contains(day),
                  onSelected: (value) {
                    final next = {...monthDays};
                    if (value) {
                      next.add(day);
                    } else if (next.length > 1) {
                      next.remove(day);
                    }
                    onMonthDaysChanged(next);
                  },
                ),
            ],
          )
        else ...[
          ReminderEditorPickerRow(
            key: const Key('repeat-monthly-ordinal'),
            label: '第幾個',
            value: _ordinalLabel(ordinal),
            onTap: () => _showOrdinalPicker(context),
          ),
          const SizedBox(height: 12),
          ReminderEditorPickerRow(
            key: const Key('repeat-monthly-weekday'),
            label: '星期',
            value: _weekday(weekday),
            onTap: () => _showWeekdayPicker(context),
          ),
        ],
      ],
    );
  }

  Future<void> _showOrdinalPicker(BuildContext context) async {
    final value = await showModalBottomSheet<MonthlyWeekOrdinal>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('第幾個', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final value in MonthlyWeekOrdinal.values)
              ListTile(
                key: Key('repeat-monthly-ordinal-${value.name}'),
                title: Text(_ordinalLabel(value)),
                trailing: value == ordinal ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    );
    if (value != null) {
      onOrdinalChanged(value);
    }
  }

  Future<void> _showWeekdayPicker(BuildContext context) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('星期', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final value in _weekdays)
              ListTile(
                key: Key('repeat-monthly-weekday-$value'),
                title: Text(_weekday(value)),
                trailing: value == weekday ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    );
    if (value != null) {
      onWeekdayChanged(value);
    }
  }
}

class _EndRepeatSection extends StatelessWidget {
  const _EndRepeatSection({
    required this.endType,
    required this.endDate,
    required this.endCount,
    required this.onEndTypeChanged,
    required this.onEndDateChanged,
    required this.onEndCountChanged,
  });

  final RepeatEndType endType;
  final DateTime endDate;
  final int endCount;
  final ValueChanged<RepeatEndType> onEndTypeChanged;
  final ValueChanged<DateTime> onEndDateChanged;
  final ValueChanged<int> onEndCountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReminderEditorPickerRow(
          key: const Key('repeat-end-type'),
          label: '結束重複',
          value: _endTypeLabel(endType),
          onTap: () => _showEndTypePicker(context),
        ),
        if (endType == RepeatEndType.onDate) ...[
          const SizedBox(height: 12),
          ReminderEditorDateRow(
            key: const Key('repeat-end-date-row'),
            label: '直到',
            date: endDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) {
                onEndDateChanged(
                  DateTime(picked.year, picked.month, picked.day),
                );
              }
            },
          ),
        ],
        if (endType == RepeatEndType.afterCount) ...[
          const SizedBox(height: 12),
          _StepperTile(
            value: endCount,
            unitLabel: '次',
            onChanged: onEndCountChanged,
          ),
        ],
      ],
    );
  }

  Future<void> _showEndTypePicker(BuildContext context) async {
    final value = await showModalBottomSheet<RepeatEndType>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text('結束重複', style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final value in RepeatEndType.values)
              ListTile(
                key: Key('repeat-end-option-${value.name}'),
                title: Text(_endTypeLabel(value)),
                trailing: value == endType ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ],
        ),
      ),
    );
    if (value != null) {
      onEndTypeChanged(value);
    }
  }
}

const _weekdays = <int>[
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];

String _shortWeekday(int weekday) {
  return switch (weekday) {
    DateTime.monday => '一',
    DateTime.tuesday => '二',
    DateTime.wednesday => '三',
    DateTime.thursday => '四',
    DateTime.friday => '五',
    DateTime.saturday => '六',
    DateTime.sunday => '日',
    _ => '一',
  };
}

String _weekday(int weekday) {
  return '星期${_shortWeekday(weekday)}';
}

String _ordinalLabel(MonthlyWeekOrdinal ordinal) {
  return switch (ordinal) {
    MonthlyWeekOrdinal.first => '第一個',
    MonthlyWeekOrdinal.second => '第二個',
    MonthlyWeekOrdinal.third => '第三個',
    MonthlyWeekOrdinal.fourth => '第四個',
    MonthlyWeekOrdinal.fifth => '第五個',
    MonthlyWeekOrdinal.last => '最後一個',
  };
}

String _endTypeLabel(RepeatEndType type) {
  return switch (type) {
    RepeatEndType.never => '永不',
    RepeatEndType.onDate => '指定日期',
    RepeatEndType.afterCount => '重複次數',
  };
}
