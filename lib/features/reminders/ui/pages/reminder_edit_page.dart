import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/reminder_repository.dart';
import '../../domain/demo_reminder_draft.dart';
import '../../domain/action_category.dart';
import '../../domain/reminder.dart';
import '../../domain/recurring_reminder.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/topic_category.dart';
import '../../presentation/reminder_view_models.dart';

enum ReminderFormMode { reminderCreate, reminderEdit, seriesCreate, seriesEdit }

extension on ReminderFormMode {
  bool get isSeriesMode =>
      this == ReminderFormMode.seriesCreate ||
      this == ReminderFormMode.seriesEdit;

  bool get isEditing =>
      this == ReminderFormMode.reminderEdit ||
      this == ReminderFormMode.seriesEdit;
}

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({
    super.key,
    this.mode = ReminderFormMode.reminderCreate,
    this.reminderId,
    this.seriesId,
    this.demoDataFactory,
  });

  static const newRouteName = 'reminder-new';
  static const newRoutePath = '/reminder/new';
  static const editRouteName = 'reminder-edit';
  static const editRoutePath = '/reminder/:id';
  static const recurringNewRouteName = 'recurring-reminder-new';
  static const recurringNewRoutePath = '/recurring/new';
  static const recurringEditRouteName = 'recurring-reminder-edit';
  static const recurringEditRoutePath = '/recurring/:id';
  static const seriesNewRouteName = recurringNewRouteName;
  static const seriesNewRoutePath = recurringNewRoutePath;
  static const seriesEditRouteName = recurringEditRouteName;
  static const seriesEditRoutePath = recurringEditRoutePath;

  final ReminderFormMode mode;
  final int? reminderId;
  final int? seriesId;
  final DemoReminderDraft Function()? demoDataFactory;

  bool get isReminderEdit => mode == ReminderFormMode.reminderEdit;
  bool get isSeriesCreate => mode == ReminderFormMode.seriesCreate;
  bool get isSeriesEdit => mode == ReminderFormMode.seriesEdit;
  bool get isSeriesMode => mode.isSeriesMode;

  @override
  ConsumerState<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends ConsumerState<ReminderEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _triggerOffsetDaysController;
  late final TextEditingController _repeatIntervalController;

  bool _initialized = false;
  bool _initializing = false;

  bool get _showsDateFields => !widget.isSeriesEdit;
  bool get _requiresRepeatRule => widget.isSeriesMode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _triggerOffsetDaysController = TextEditingController(text: '0');
    _repeatIntervalController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _triggerOffsetDaysController.dispose();
    _repeatIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderDetailAsync =
        widget.isReminderEdit && widget.reminderId != null
        ? ref.watch(reminderDetailProvider(widget.reminderId!))
        : const AsyncData<ReminderModel?>(null);
    final recurringReminderDetailAsync =
        widget.isSeriesEdit && widget.seriesId != null
        ? ref.watch(recurringReminderDetailProvider(widget.seriesId!))
        : const AsyncData<RecurringReminderModel?>(null);
    final topicCategoriesAsync = ref.watch(topicCategoriesProvider);
    final actionCategoriesAsync = ref.watch(actionCategoriesProvider);

    final error =
        reminderDetailAsync.asError?.error ??
        recurringReminderDetailAsync.asError?.error ??
        topicCategoriesAsync.asError?.error ??
        actionCategoriesAsync.asError?.error;

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: Center(child: Text('讀取失敗: $error')),
      );
    }

    final isLoading =
        reminderDetailAsync.isLoading ||
        recurringReminderDetailAsync.isLoading ||
        topicCategoriesAsync.isLoading ||
        actionCategoriesAsync.isLoading;
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final seed = _resolveSeed(
      reminderDetailAsync.valueOrNull,
      recurringReminderDetailAsync.valueOrNull,
    );
    if (widget.mode.isEditing && seed == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: Center(
          child: Text(widget.isSeriesMode ? '此習慣不存在' : '此任務不存在或不可編輯'),
        ),
      );
    }

    if (!_initialized) {
      _scheduleInitializeForm(seed);
      return Scaffold(
        appBar: AppBar(title: Text(_pageTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final draft = ref.watch(reminderWizardDraftProvider);
    final topicCategories =
        topicCategoriesAsync.valueOrNull ?? const <TopicCategoryModel>[];
    final actionCategories =
        actionCategoriesAsync.valueOrNull ?? const <ActionCategoryModel>[];

    return Scaffold(
      appBar: AppBar(title: Text(_pageTitle)),
      bottomNavigationBar: _buildBottomActions(draft),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            children: [
              _buildStepTitle(1, '輸入任務內容'),
              _buildTaskContentSection(
                draft,
                topicCategories,
                actionCategories,
              ),
              const SizedBox(height: 16),
              _buildStepTitle(2, '是否需要重複'),
              _buildRepeatChoiceSection(draft),
              const SizedBox(height: 16),
              if (draft.repeatChoice ==
                  ReminderWizardRepeatChoice.recurring) ...[
                _buildStepTitle(3, '選擇重複方式'),
                _buildRepeatPatternSection(draft),
                const SizedBox(height: 16),
              ],
              ..._buildSettingsStep(context, draft),
              if (!draft.readOnly) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('random-fill-button'),
                  onPressed: _fillWithRandomDemoData,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('[demo]隨機生成欄位資料'),
                ),
              ],
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomActions(ReminderWizardDraft draft) {
    final hasEnoughWizardContext =
        draft.repeatChoice == ReminderWizardRepeatChoice.once ||
        draft.repeatPattern != null;
    if (!widget.mode.isEditing && !hasEnoughWizardContext) {
      return null;
    }

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _closePage,
              child: Text(draft.readOnly ? '返回' : '取消'),
            ),
          ),
          if (!draft.readOnly) ...[
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(onPressed: _onSave, child: const Text('儲存')),
            ),
          ],
        ],
      ),
    );
  }

  String get _pageTitle {
    final isReadOnly =
        _initialized && ref.read(reminderWizardDraftProvider).readOnly;
    if (isReadOnly) {
      return ReminderUiText.viewHabit;
    }
    switch (widget.mode) {
      case ReminderFormMode.reminderCreate:
        return ReminderUiText.addTask;
      case ReminderFormMode.reminderEdit:
        return ReminderUiText.editTask;
      case ReminderFormMode.seriesCreate:
        return ReminderUiText.addHabit;
      case ReminderFormMode.seriesEdit:
        return ReminderUiText.editHabit;
    }
  }

  ReminderFormDraft? _resolveSeed(
    ReminderModel? reminder,
    RecurringReminderModel? recurringReminder,
  ) {
    if (reminder != null) {
      return ReminderFormDraft.fromReminder(reminder);
    }
    if (recurringReminder != null) {
      return ReminderFormDraft.fromRecurringReminder(recurringReminder);
    }
    if (widget.mode.isEditing) {
      return null;
    }
    return ReminderFormDraft.createDefault();
  }

  void _scheduleInitializeForm(ReminderFormDraft? seed) {
    if (_initializing) {
      return;
    }
    _initializing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _initializeForm(seed);
      setState(() {
        _initialized = true;
        _initializing = false;
      });
    });
  }

  void _initializeForm(ReminderFormDraft? seed) {
    final currentSeed = seed ?? ReminderFormDraft.createDefault();
    _applyFormDraftToControllers(currentSeed);
    ref
        .read(reminderWizardDraftProvider.notifier)
        .initialize(currentSeed, waitForRepeatChoice: !widget.mode.isEditing);
  }

  void _applyFormDraftToControllers(ReminderFormDraft draft) {
    _titleController.text = draft.title;
    _noteController.text = draft.note ?? '';
    _triggerOffsetDaysController.text = draft.triggerOffsetDays.toString();
    final repeatRule = RepeatRule.parse(draft.repeatRule);
    _repeatIntervalController.text = (repeatRule?.interval ?? 1).toString();
  }

  Widget _buildStepTitle(Object step, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'Step $step：$title',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildTaskContentSection(
    ReminderWizardDraft draft,
    List<TopicCategoryModel> topicCategories,
    List<ActionCategoryModel> actionCategories,
  ) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('edit-title-field'),
          controller: _titleController,
          enabled: !draft.readOnly,
          decoration: const InputDecoration(
            labelText: '你想提醒什麼？',
            border: OutlineInputBorder(),
          ),
          onChanged: notifier.setTitle,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '請輸入任務內容';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Text('分類（選填）', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        _buildTopicCategorySection(draft, topicCategories),
        const SizedBox(height: 12),
        _buildActionCategorySection(draft, actionCategories),
        const SizedBox(height: 8),
        ExpansionTile(
          key: ValueKey<bool>(draft.note != null),
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: draft.note != null,
          title: const Text('進階'),
          children: [
            TextFormField(
              key: const Key('edit-note-field'),
              controller: _noteController,
              enabled: !draft.readOnly,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '備註（選填）',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.setNote,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRepeatChoiceSection(ReminderWizardDraft draft) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return Column(
      children: [
        _buildOptionTile(
          key: const Key('wizard-repeat-once'),
          selected: draft.repeatChoice == ReminderWizardRepeatChoice.once,
          enabled: !draft.readOnly && !widget.isSeriesEdit,
          title: const Text('不需要'),
          subtitle: const Text('只提醒一次'),
          onTap: () =>
              notifier.setRepeatChoice(ReminderWizardRepeatChoice.once),
        ),
        _buildOptionTile(
          key: const Key('wizard-repeat-recurring'),
          selected: draft.repeatChoice == ReminderWizardRepeatChoice.recurring,
          enabled: !draft.readOnly,
          title: const Text('需要'),
          subtitle: const Text('系統會自動幫你安排下一次'),
          onTap: () =>
              notifier.setRepeatChoice(ReminderWizardRepeatChoice.recurring),
        ),
      ],
    );
  }

  Widget _buildRepeatPatternSection(ReminderWizardDraft draft) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    final isLocked = draft.readOnly || widget.isSeriesEdit;
    return Column(
      key: const Key('edit-time-basis-field'),
      children: [
        _buildOptionTile(
          key: const Key('wizard-repeat-pattern-fixed'),
          selected:
              draft.repeatPattern == ReminderWizardRepeatPattern.fixedTime,
          enabled: !isLocked,
          title: const Text('固定時間'),
          subtitle: const Text('例如每天、每週一'),
          onTap: () =>
              notifier.setRepeatPattern(ReminderWizardRepeatPattern.fixedTime),
        ),
        _buildOptionTile(
          key: const Key('wizard-repeat-pattern-start'),
          selected:
              draft.repeatPattern == ReminderWizardRepeatPattern.fromStart,
          enabled: !isLocked,
          title: const Text('從某天開始'),
          subtitle: const Text('例如紀念日、養寵物第幾天'),
          onTap: () =>
              notifier.setRepeatPattern(ReminderWizardRepeatPattern.fromStart),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required Key key,
    required bool selected,
    required bool enabled,
    required Widget title,
    required Widget subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      key: key,
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: title,
      subtitle: subtitle,
      onTap: enabled ? onTap : null,
    );
  }

  List<Widget> _buildSettingsStep(
    BuildContext context,
    ReminderWizardDraft draft,
  ) {
    if (draft.repeatChoice == null) {
      return const [];
    }
    if (draft.repeatChoice == ReminderWizardRepeatChoice.once) {
      return [
        _buildStepTitle('4A', '單次任務設定'),
        _buildSingleTaskSettings(context, draft),
      ];
    }
    if (draft.repeatPattern == ReminderWizardRepeatPattern.fixedTime) {
      return [
        _buildStepTitle('4B', '固定時間設定'),
        _buildFixedTimeSettings(context, draft),
      ];
    }
    if (draft.repeatPattern == ReminderWizardRepeatPattern.fromStart) {
      return [
        _buildStepTitle('4C', '從某天開始設定'),
        _buildStartBasedSettings(context, draft),
      ];
    }
    return const [];
  }

  Widget _buildSingleTaskSettings(
    BuildContext context,
    ReminderWizardDraft draft,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showsDateFields) _buildDueAtSection(context, draft),
        const SizedBox(height: 12),
        const Text('時間：暫不支援時間選擇，會依日期提醒。'),
      ],
    );
  }

  Widget _buildFixedTimeSettings(
    BuildContext context,
    ReminderWizardDraft draft,
  ) {
    return Column(
      children: [
        _buildRepeatSection(draft, labelText: '頻率'),
        if (_showsDateFields) ...[
          const SizedBox(height: 12),
          _buildDueAtSection(context, draft),
        ],
        const SizedBox(height: 12),
        _buildTriggerModeSection(draft),
        const SizedBox(height: 12),
        _buildTriggerOffsetSection(draft),
      ],
    );
  }

  Widget _buildStartBasedSettings(
    BuildContext context,
    ReminderWizardDraft draft,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_showsDateFields) _buildStartAtSection(context, draft),
        const SizedBox(height: 12),
        _buildAccumulationDisplaySection(draft),
        const SizedBox(height: 12),
        Text(
          _accumulationPreviewText(draft),
          key: const Key('wizard-accumulation-preview'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        _buildRepeatSection(draft, labelText: '提醒頻率'),
        const SizedBox(height: 12),
        _buildTriggerOffsetSection(draft),
      ],
    );
  }

  Widget _buildTriggerModeSection(ReminderWizardDraft draft) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    final options = ReminderTriggerModeOption.forTrackingMode(
      draft.trackingMode,
    );
    final values = options.map((item) => item.value).toSet();
    final effectiveValue = values.contains(draft.triggerMode)
        ? draft.triggerMode
        : ReminderTriggerMode.inRange;

    return DropdownButtonFormField<int>(
      key: const Key('edit-notify-strategy-field'),
      initialValue: effectiveValue,
      decoration: const InputDecoration(
        labelText: '提醒方式',
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(growable: false),
      onChanged: draft.readOnly
          ? null
          : (value) {
              if (value != null) {
                notifier.setTriggerMode(value);
              }
            },
    );
  }

  Widget _buildTriggerOffsetSection(ReminderWizardDraft draft) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return TextFormField(
      key: const Key('edit-remind-days-field'),
      controller: _triggerOffsetDaysController,
      enabled: !draft.readOnly,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: draft.trackingMode == ReminderTrackingMode.countdown
            ? '提前提醒天數'
            : '第幾天提醒',
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final days = int.tryParse(value);
        if (days != null && days >= 0) {
          notifier.setTriggerOffsetDays(days);
        }
      },
      validator: (value) {
        final days = int.tryParse(value ?? '');
        if (days == null || days < 0) {
          return '請輸入 0 或以上';
        }
        return null;
      },
    );
  }

  Widget _buildDueAtSection(BuildContext context, ReminderWizardDraft draft) {
    final dueText = draft.dueAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(draft.dueAt!.toLocal());
    final notifier = ref.read(reminderWizardDraftProvider.notifier);

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '日期（必填）',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(dueText, key: const Key('edit-due-at-text'))),
          TextButton(
            onPressed: draft.readOnly
                ? null
                : () => _pickDate(
                    context,
                    initial: draft.dueAt ?? DateTime.now(),
                    onPicked: notifier.setDueAt,
                  ),
            child: const Text('選擇'),
          ),
          TextButton(
            onPressed: draft.readOnly ? null : () => notifier.setDueAt(null),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartAtSection(BuildContext context, ReminderWizardDraft draft) {
    final startText = draft.startAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(draft.startAt!.toLocal());
    final notifier = ref.read(reminderWizardDraftProvider.notifier);

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '起始日期',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(startText, key: const Key('edit-start-at-text')),
          ),
          TextButton(
            onPressed: draft.readOnly
                ? null
                : () => _pickDate(
                    context,
                    initial: draft.startAt ?? DateTime.now(),
                    onPicked: notifier.setStartAt,
                  ),
            child: const Text('選擇'),
          ),
          TextButton(
            onPressed: draft.readOnly
                ? null
                : () => notifier.setStartAt(DateTime.now()),
            child: const Text('今天'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatSection(
    ReminderWizardDraft draft, {
    required String labelText,
  }) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          key: ValueKey<String?>(
            draft.repeatType == null
                ? 'repeat-type-null'
                : 'repeat-type-${draft.repeatType}',
          ),
          initialValue: draft.repeatType,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String?>(value: 'D', child: Text('每天 / 每 X 天')),
            DropdownMenuItem<String?>(value: 'W', child: Text('每週')),
            DropdownMenuItem<String?>(value: 'M', child: Text('每月')),
            DropdownMenuItem<String?>(value: 'Y', child: Text('每年')),
          ],
          onChanged: draft.readOnly
              ? null
              : (value) {
                  notifier.setRepeatType(value);
                },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit-repeat-interval-field'),
          controller: _repeatIntervalController,
          enabled: !draft.readOnly,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '間隔（1 代表每次）',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final interval = int.tryParse(value);
            if (interval != null && interval >= 1) {
              notifier.setRepeatInterval(interval);
            }
          },
          validator: (value) {
            final interval = int.tryParse(value ?? '');
            if (interval == null || interval < 1) {
              return '請輸入 1 或以上';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccumulationDisplaySection(ReminderWizardDraft draft) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return DropdownButtonFormField<ReminderWizardAccumulationDisplay>(
      key: const Key('wizard-accumulation-display-field'),
      initialValue: draft.accumulationDisplay,
      decoration: const InputDecoration(
        labelText: '顯示方式',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: ReminderWizardAccumulationDisplay.day,
          child: Text('第幾天'),
        ),
        DropdownMenuItem(
          value: ReminderWizardAccumulationDisplay.week,
          child: Text('第幾週'),
        ),
        DropdownMenuItem(
          value: ReminderWizardAccumulationDisplay.year,
          child: Text('第幾年'),
        ),
      ],
      onChanged: draft.readOnly
          ? null
          : (value) {
              if (value != null) {
                notifier.setAccumulationDisplay(value);
              }
            },
    );
  }

  Widget _buildTopicCategorySection(
    ReminderWizardDraft draft,
    List<TopicCategoryModel> topicCategories,
  ) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return DropdownButtonFormField<int?>(
      key: const Key('edit-issue-type-field'),
      initialValue: draft.topicCategoryId,
      decoration: const InputDecoration(
        labelText: '主題分類（選填）',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
        ...topicCategories.map(
          (item) =>
              DropdownMenuItem<int?>(value: item.id, child: Text(item.name)),
        ),
      ],
      onChanged: draft.readOnly ? null : notifier.setTopicCategoryId,
    );
  }

  Widget _buildActionCategorySection(
    ReminderWizardDraft draft,
    List<ActionCategoryModel> actionCategories,
  ) {
    final notifier = ref.read(reminderWizardDraftProvider.notifier);
    return DropdownButtonFormField<int?>(
      key: const Key('edit-handle-type-field'),
      initialValue: draft.actionCategoryId,
      decoration: const InputDecoration(
        labelText: '行動分類（選填）',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
        ...actionCategories.map(
          (item) =>
              DropdownMenuItem<int?>(value: item.id, child: Text(item.name)),
        ),
      ],
      onChanged: draft.readOnly ? null : notifier.setActionCategoryId,
    );
  }

  String _accumulationPreviewText(ReminderWizardDraft draft) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startValue = draft.startAt ?? today;
    final start = DateTime(startValue.year, startValue.month, startValue.day);
    final diffDays = today.difference(start).inDays;
    if (diffDays < 0) {
      return '還有 ${diffDays.abs()} 天開始';
    }

    final count = switch (draft.accumulationDisplay) {
      ReminderWizardAccumulationDisplay.day => diffDays + 1,
      ReminderWizardAccumulationDisplay.week => (diffDays ~/ 7) + 1,
      ReminderWizardAccumulationDisplay.year => _yearCount(start, today),
    };
    final unit = switch (draft.accumulationDisplay) {
      ReminderWizardAccumulationDisplay.day => '天',
      ReminderWizardAccumulationDisplay.week => '週',
      ReminderWizardAccumulationDisplay.year => '年',
    };
    return '今天是第 $count $unit';
  }

  int _yearCount(DateTime start, DateTime today) {
    var years = today.year - start.year;
    final anniversaryThisYear = DateTime(today.year, start.month, start.day);
    if (today.isBefore(anniversaryThisYear)) {
      years -= 1;
    }
    return years + 1;
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (pickedDate == null || !mounted || !context.mounted) {
      return;
    }

    onPicked(DateTime(pickedDate.year, pickedDate.month, pickedDate.day));
  }

  void _fillWithRandomDemoData() {
    final draft = ReminderFormDraft.fromDemo(
      widget.demoDataFactory?.call() ?? DemoReminderDraft.random(),
    );
    _applyFormDraftToControllers(draft);
    ref.read(reminderWizardDraftProvider.notifier).applyDemo(draft);
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final draft = ref.read(reminderWizardDraftProvider);
    if (draft.repeatChoice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇是否需要重複')));
      return;
    }

    if (draft.repeatChoice == ReminderWizardRepeatChoice.recurring &&
        draft.repeatPattern == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('請先選擇重複方式')));
      return;
    }

    final repeatRule = _buildRepeatRule(draft);
    if ((draft.repeatChoice == ReminderWizardRepeatChoice.recurring ||
            _requiresRepeatRule) &&
        repeatRule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.habitRepeatRuleRequired)),
      );
      return;
    }

    if (_showsDateFields &&
        draft.trackingMode == ReminderTrackingMode.countdown &&
        draft.dueAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(ReminderUiText.fixedTimeRequired)),
      );
      return;
    }

    final repository = ref.read(reminderRepositoryProvider);
    final input = ReminderInput(
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      trackingMode: draft.trackingMode,
      triggerMode: draft.triggerMode,
      triggerOffsetDays: int.parse(_triggerOffsetDaysController.text),
      dueAt: draft.trackingMode == ReminderTrackingMode.countdown
          ? draft.dueAt
          : null,
      startAt: draft.startAt ?? DateTime.now(),
      repeatRule: repeatRule,
      topicCategoryId: draft.topicCategoryId,
      actionCategoryId: draft.actionCategoryId,
    );

    var success = true;
    switch (widget.mode) {
      case ReminderFormMode.reminderCreate:
        await repository.create(input);
      case ReminderFormMode.reminderEdit:
        success = await repository.updateById(widget.reminderId!, input);
      case ReminderFormMode.seriesCreate:
        await repository.createRecurringReminderWithFirstOccurrence(input);
      case ReminderFormMode.seriesEdit:
        success = await repository.updateRecurringReminderById(
          widget.seriesId!,
          input,
        );
    }

    if (!success && mounted) {
      final message = widget.isSeriesMode ? '此習慣不可編輯' : '此任務不可編輯';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    if (mounted) {
      _closePage();
    }
  }

  void _closePage() {
    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.pop();
    }
  }

  String? _buildRepeatRule(ReminderWizardDraft draft) {
    if (draft.repeatChoice != ReminderWizardRepeatChoice.recurring ||
        draft.repeatType == null) {
      return null;
    }

    final interval = int.tryParse(_repeatIntervalController.text);
    if (interval == null || interval < 1) {
      return null;
    }

    return '${draft.repeatType}$interval';
  }
}
