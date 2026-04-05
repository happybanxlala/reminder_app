import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/reminder_repository.dart';
import '../../domain/demo_reminder_draft.dart';
import '../../domain/handle_type.dart';
import '../../domain/issue_type.dart';
import '../../domain/reminder.dart';

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({
    super.key,
    this.reminderId,
    this.demoDataFactory,
  });

  static const newRouteName = 'reminder-new';
  static const newRoutePath = '/reminder/new';
  static const editRouteName = 'reminder-edit';
  static const editRoutePath = '/reminder/:id';

  final int? reminderId;
  final DemoReminderDraft Function()? demoDataFactory;

  bool get isEditing => reminderId != null;

  @override
  ConsumerState<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends ConsumerState<ReminderEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _remindDaysController;
  late final TextEditingController _repeatIntervalController;

  bool _initialized = false;
  int _timeBasis = ReminderTimeBasis.countdown;
  int _notifyStrategy = ReminderNotifyStrategy.inRange;
  String? _repeatType;
  DateTime? _dueAt;
  DateTime? _startAt;
  int? _selectedIssueTypeId;
  int? _selectedHandleTypeId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _remindDaysController = TextEditingController(text: '0');
    _repeatIntervalController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _remindDaysController.dispose();
    _repeatIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = widget.isEditing
        ? ref.watch(reminderDetailProvider(widget.reminderId!))
        : const AsyncData<ReminderModel?>(null);
    final issueTypesAsync = ref.watch(issueTypesProvider);
    final handleTypesAsync = ref.watch(handleTypesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '編輯提醒' : '新增提醒')),
      body: detailAsync.when(
        data: (detail) {
          if (widget.isEditing && detail == null) {
            return const Center(child: Text('此提醒不存在或不可編輯'));
          }

          if (!_initialized) {
            _initializeForm(detail);
          }

          final issueTypes = issueTypesAsync.valueOrNull ?? const <IssueTypeModel>[];
          final handleTypes = handleTypesAsync.valueOrNull ?? const <HandleTypeModel>[];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    key: const Key('edit-title-field'),
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: '標題',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '請輸入標題';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('edit-note-field'),
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '備註（選填）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimeBasisSection(),
                  const SizedBox(height: 16),
                  _buildNotifyStrategySection(),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('edit-remind-days-field'),
                    controller: _remindDaysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _timeBasis == ReminderTimeBasis.countdown
                          ? '提前提醒天數'
                          : '累積提醒天數',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final days = int.tryParse(value ?? '');
                      if (days == null || days < 0) {
                        return '請輸入 0 或以上';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_timeBasis == ReminderTimeBasis.countdown) ...[
                    _buildDueAtSection(context),
                    const SizedBox(height: 16),
                  ] else ...[
                    _buildStartAtSection(context),
                    const SizedBox(height: 16),
                  ],
                  _buildRepeatSection(),
                  const SizedBox(height: 16),
                  _buildIssueTypeSection(issueTypes),
                  const SizedBox(height: 16),
                  _buildHandleTypeSection(handleTypes),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const Key('random-fill-button'),
                    onPressed: _fillWithRandomDemoData,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('[demo]隨機生成欄位資料'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _onSave,
                          child: const Text('儲存'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        error: (error, stack) => Center(child: Text('讀取失敗: $error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  void _initializeForm(ReminderModel? detail) {
    if (detail != null) {
      _titleController.text = detail.title;
      _noteController.text = detail.note ?? '';
      _remindDaysController.text = (detail.remindDays ?? 0).toString();
      _timeBasis = detail.timeBasis;
      _notifyStrategy = detail.notifyStrategy;
      _dueAt = detail.dueAt;
      _startAt = detail.startAt;
      _selectedIssueTypeId = detail.issueTypeId;
      _selectedHandleTypeId = detail.handleTypeId;
      _applyRepeatRule(detail.repeatRule);
    } else {
      _startAt = DateTime.now();
    }
    _initialized = true;
  }

  Widget _buildTimeBasisSection() {
    return DropdownButtonFormField<int>(
      key: const Key('edit-time-basis-field'),
      initialValue: _timeBasis,
      decoration: const InputDecoration(
        labelText: '提醒類型',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(
          value: ReminderTimeBasis.countdown,
          child: Text('倒數式'),
        ),
        DropdownMenuItem(
          value: ReminderTimeBasis.countUp,
          child: Text('起計式'),
        ),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _timeBasis = value;
          _startAt ??= DateTime.now();
          if (_timeBasis == ReminderTimeBasis.countUp) {
            _dueAt = null;
            _notifyStrategy = ReminderNotifyStrategy.inRange;
          }
        });
      },
    );
  }

  Widget _buildNotifyStrategySection() {
    final items = _timeBasis == ReminderTimeBasis.countdown
        ? const [
            DropdownMenuItem(
              value: ReminderNotifyStrategy.inRange,
              child: Text('進入範圍提醒'),
            ),
            DropdownMenuItem(
              value: ReminderNotifyStrategy.immediate,
              child: Text('建立後立即提醒'),
            ),
            DropdownMenuItem(
              value: ReminderNotifyStrategy.onPoint,
              child: Text('到期才提醒'),
            ),
          ]
        : const [
            DropdownMenuItem(
              value: ReminderNotifyStrategy.inRange,
              child: Text('累積達標後提醒'),
            ),
          ];

    return DropdownButtonFormField<int>(
      key: const Key('edit-notify-strategy-field'),
      initialValue: _notifyStrategy,
      decoration: const InputDecoration(
        labelText: '提醒策略',
        border: OutlineInputBorder(),
      ),
      items: items,
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _notifyStrategy = value;
        });
      },
    );
  }

  Widget _buildDueAtSection(BuildContext context) {
    final dueText = _dueAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(_dueAt!.toLocal());

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '到期時間',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(dueText, key: const Key('edit-due-at-text')),
          ),
          TextButton(
            onPressed: () => _pickDate(
              context,
              initial: _dueAt ?? DateTime.now(),
              onPicked: (value) => setState(() => _dueAt = value),
            ),
            child: const Text('選擇'),
          ),
          TextButton(
            onPressed: () => setState(() => _dueAt = null),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartAtSection(BuildContext context) {
    final startText = _startAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd').format(_startAt!.toLocal());

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '起計時間',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(startText, key: const Key('edit-start-at-text')),
          ),
          TextButton(
            onPressed: () => _pickDate(
              context,
              initial: _startAt ?? DateTime.now(),
              onPicked: (value) => setState(() => _startAt = value),
            ),
            child: const Text('選擇'),
          ),
          TextButton(
            onPressed: () => setState(() => _startAt = DateTime.now()),
            child: const Text('現在'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          key: ValueKey<String?>(
            _repeatType == null ? 'repeat-type-null' : 'repeat-type-$_repeatType',
          ),
          initialValue: _repeatType,
          decoration: const InputDecoration(
            labelText: '重複規則類型',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('不重複')),
            DropdownMenuItem<String?>(value: 'D', child: Text('每 N 天')),
            DropdownMenuItem<String?>(value: 'W', child: Text('每 N 週')),
            DropdownMenuItem<String?>(value: 'M', child: Text('每 N 月')),
            DropdownMenuItem<String?>(value: 'Y', child: Text('每 N 年')),
          ],
          onChanged: (value) {
            setState(() {
              _repeatType = value;
            });
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('edit-repeat-interval-field'),
          controller: _repeatIntervalController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '重複間隔（預設 1）',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_repeatType == null) {
              return null;
            }
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

  Widget _buildIssueTypeSection(List<IssueTypeModel> issueTypes) {
    return DropdownButtonFormField<int?>(
      key: const Key('edit-issue-type-field'),
      initialValue: _selectedIssueTypeId,
      decoration: const InputDecoration(
        labelText: '內容分類',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
        ...issueTypes.map(
          (item) => DropdownMenuItem<int?>(
            value: item.id,
            child: Text(item.name),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedIssueTypeId = value;
        });
      },
    );
  }

  Widget _buildHandleTypeSection(List<HandleTypeModel> handleTypes) {
    return DropdownButtonFormField<int?>(
      key: const Key('edit-handle-type-field'),
      initialValue: _selectedHandleTypeId,
      decoration: const InputDecoration(
        labelText: '操作分類',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('未指定')),
        ...handleTypes.map(
          (item) => DropdownMenuItem<int?>(
            value: item.id,
            child: Text(item.name),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedHandleTypeId = value;
        });
      },
    );
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

  void _applyRepeatRule(String? repeatRule) {
    if (repeatRule == null || repeatRule.isEmpty) {
      _repeatType = null;
      _repeatIntervalController.text = '1';
      return;
    }

    final match = RegExp(r'^([DWMY])(\d+)$').firstMatch(repeatRule);
    if (match == null) {
      _repeatType = null;
      _repeatIntervalController.text = '1';
      return;
    }

    _repeatType = match.group(1);
    _repeatIntervalController.text = match.group(2)!;
  }

  void _fillWithRandomDemoData() {
    final draft = widget.demoDataFactory?.call() ?? DemoReminderDraft.random();
    setState(() {
      _titleController.text = draft.title;
      _noteController.text = draft.note ?? '';
      _timeBasis = draft.timeBasis;
      _notifyStrategy = draft.notifyStrategy;
      _remindDaysController.text = draft.remindDays.toString();
      _dueAt = draft.dueAt;
      _startAt = draft.startAt;
      _repeatType = draft.repeatType;
      _repeatIntervalController.text = draft.repeatInterval.toString();
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_timeBasis == ReminderTimeBasis.countdown && _dueAt == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('倒數式提醒需要設定到期時間')));
      return;
    }

    final repository = ref.read(reminderRepositoryProvider);
    final repeatRule = _buildRepeatRule();
    final input = ReminderUpsert(
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      timeBasis: _timeBasis,
      notifyStrategy: _notifyStrategy,
      remindDays: int.parse(_remindDaysController.text),
      dueAt: _timeBasis == ReminderTimeBasis.countdown ? _dueAt : null,
      startAt: _startAt ?? DateTime.now(),
      repeatRule: repeatRule,
      issueTypeId: _selectedIssueTypeId,
      handleTypeId: _selectedHandleTypeId,
    );

    if (widget.isEditing) {
      await repository.updateById(widget.reminderId!, input);
    } else {
      await repository.create(input);
    }

    if (mounted) {
      context.pop();
    }
  }

  String? _buildRepeatRule() {
    if (_repeatType == null) {
      return null;
    }

    final interval = int.tryParse(_repeatIntervalController.text);
    if (interval == null || interval < 1) {
      return null;
    }

    return '$_repeatType$interval';
  }
}
