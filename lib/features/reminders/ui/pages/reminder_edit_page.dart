import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/reminder_repository.dart';
import '../../domain/demo_reminder_draft.dart';
import '../../domain/action_category.dart';
import '../../domain/reminder.dart';
import '../../domain/recurring_reminder.dart';
import '../../domain/repeat_rule.dart';
import '../../domain/topic_category.dart';
import '../../presentation/reminder_view_models.dart';
import '../widgets/step1_input_widget.dart';
import '../widgets/step2_repeat_toggle_widget.dart';
import '../widgets/step3_repeat_type_widget.dart';
import '../widgets/step4_fixed_widget.dart';
import '../widgets/step4_once_widget.dart';
import '../widgets/step4_since_start_widget.dart';

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
              Step1InputWidget(
                draft: draft,
                titleController: _titleController,
                noteController: _noteController,
                topicCategories: topicCategories,
                actionCategories: actionCategories,
                onTitleChanged: ref
                    .read(reminderWizardDraftProvider.notifier)
                    .setTitle,
                onNoteChanged: ref
                    .read(reminderWizardDraftProvider.notifier)
                    .setNote,
                onTopicCategoryChanged: ref
                    .read(reminderWizardDraftProvider.notifier)
                    .setTopicCategoryId,
                onActionCategoryChanged: ref
                    .read(reminderWizardDraftProvider.notifier)
                    .setActionCategoryId,
              ),
              const SizedBox(height: 16),
              _buildStepTitle(2, '是否需要重複'),
              Step2RepeatToggleWidget(
                draft: draft,
                isSeriesEdit: widget.isSeriesEdit,
                onRepeatChoiceChanged: ref
                    .read(reminderWizardDraftProvider.notifier)
                    .setRepeatChoice,
              ),
              const SizedBox(height: 16),
              if (draft.repeatChoice ==
                  ReminderWizardRepeatChoice.recurring) ...[
                _buildStepTitle(3, '選擇重複方式'),
                Step3RepeatTypeWidget(
                  draft: draft,
                  isSeriesEdit: widget.isSeriesEdit,
                  onRepeatPatternChanged: ref
                      .read(reminderWizardDraftProvider.notifier)
                      .setRepeatPattern,
                ),
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
        Step4OnceWidget(
          draft: draft,
          showsDateFields: _showsDateFields,
          onPickDueAt: () => _pickDate(
            context,
            initial: draft.dueAt ?? DateTime.now(),
            onPicked: ref.read(reminderWizardDraftProvider.notifier).setDueAt,
          ),
          onClearDueAt: () =>
              ref.read(reminderWizardDraftProvider.notifier).setDueAt(null),
        ),
      ];
    }
    if (draft.repeatPattern == ReminderWizardRepeatPattern.fixedTime) {
      return [
        _buildStepTitle('4B', '固定時間設定'),
        Step4FixedWidget(
          draft: draft,
          repeatIntervalController: _repeatIntervalController,
          triggerOffsetDaysController: _triggerOffsetDaysController,
          showsDateFields: _showsDateFields,
          onRepeatTypeChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setRepeatType,
          onRepeatIntervalChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setRepeatInterval,
          onTriggerModeChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setTriggerMode,
          onTriggerOffsetDaysChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setTriggerOffsetDays,
          onPickDueAt: () => _pickDate(
            context,
            initial: draft.dueAt ?? DateTime.now(),
            onPicked: ref.read(reminderWizardDraftProvider.notifier).setDueAt,
          ),
          onClearDueAt: () =>
              ref.read(reminderWizardDraftProvider.notifier).setDueAt(null),
        ),
      ];
    }
    if (draft.repeatPattern == ReminderWizardRepeatPattern.fromStart) {
      return [
        _buildStepTitle('4C', '從某天開始設定'),
        Step4SinceStartWidget(
          draft: draft,
          repeatIntervalController: _repeatIntervalController,
          triggerOffsetDaysController: _triggerOffsetDaysController,
          showsDateFields: _showsDateFields,
          onPickStartAt: () => _pickDate(
            context,
            initial: draft.startAt ?? DateTime.now(),
            onPicked: ref.read(reminderWizardDraftProvider.notifier).setStartAt,
          ),
          onSetToday: () => ref
              .read(reminderWizardDraftProvider.notifier)
              .setStartAt(DateTime.now()),
          onAccumulationDisplayChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setAccumulationDisplay,
          onRepeatTypeChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setRepeatType,
          onRepeatIntervalChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setRepeatInterval,
          onTriggerOffsetDaysChanged: ref
              .read(reminderWizardDraftProvider.notifier)
              .setTriggerOffsetDays,
        ),
      ];
    }
    return const [];
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
      title: draft.title.trim(),
      note: draft.note?.trim().isEmpty ?? true ? null : draft.note?.trim(),
      trackingMode: draft.trackingMode,
      triggerMode: draft.triggerMode,
      triggerOffsetDays: draft.triggerOffsetDays,
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

    if (draft.repeatInterval < 1) {
      return null;
    }

    return '${draft.repeatType}${draft.repeatInterval}';
  }
}
