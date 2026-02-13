import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/reminder_repository.dart';

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({super.key, this.reminderId});

  static const newRouteName = 'reminder-new';
  static const newRoutePath = '/reminder/new';
  static const editRouteName = 'reminder-edit';
  static const editRoutePath = '/reminder/:id';

  final int? reminderId;

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
  String? _repeatType;
  DateTime? _dueAt;

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
        : const AsyncData(null);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? '編輯提醒' : '新增提醒')),
      body: detailAsync.when(
        data: (detail) {
          if (widget.isEditing && detail == null) {
            return const Center(child: Text('此提醒不存在或不可編輯'));
          }

          if (!_initialized && detail != null) {
            _titleController.text = detail.title;
            _noteController.text = detail.note ?? '';
            _remindDaysController.text = detail.remindDays.toString();
            _dueAt = detail.dueAt;
            _applyRepeatRule(detail.repeatRule);
            _initialized = true;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
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
                    controller: _noteController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: '備註（選填）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _remindDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '提前提醒天數',
                      border: OutlineInputBorder(),
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
                  _buildDueAtSection(context),
                  const SizedBox(height: 16),
                  _buildRepeatSection(),
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

  Widget _buildDueAtSection(BuildContext context) {
    final dueText = _dueAt == null
        ? '未設定'
        : DateFormat('yyyy/MM/dd HH:mm').format(_dueAt!.toLocal());

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '到期時間',
        border: OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(dueText)),
          TextButton(
            onPressed: () => _pickDueAt(context),
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

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _repeatType,
          decoration: const InputDecoration(
            labelText: '重複規則類型',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem<String?>(value: null, child: Text('不重複')),
            DropdownMenuItem<String?>(value: 'D', child: Text('每 N 天')),
            DropdownMenuItem<String?>(value: 'W', child: Text('每 N 週')),
            DropdownMenuItem<String?>(value: 'N', child: Text('每 N 月')),
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

  Future<void> _pickDueAt(BuildContext context) async {
    final now = DateTime.now();
    final initial = _dueAt ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      _dueAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _applyRepeatRule(String? repeatRule) {
    if (repeatRule == null || repeatRule.isEmpty) {
      _repeatType = null;
      _repeatIntervalController.text = '1';
      return;
    }

    final match = RegExp(r'^([DWNY])(\d+)$').firstMatch(repeatRule);
    if (match == null) {
      _repeatType = null;
      _repeatIntervalController.text = '1';
      return;
    }

    _repeatType = match.group(1);
    _repeatIntervalController.text = match.group(2)!;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(reminderRepositoryProvider);
    final repeatRule = _buildRepeatRule();

    final input = ReminderUpsert(
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      remindDays: int.parse(_remindDaysController.text),
      dueAt: _dueAt,
      repeatRule: repeatRule,
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
