import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/reminders_service.dart';

class ReminderEditPage extends ConsumerStatefulWidget {
  const ReminderEditPage({super.key, this.reminderId});

  static const newRouteName = 'reminder-new';
  static const newRoutePath = '/reminders/new';
  static const editRouteName = 'reminder-edit';
  static const editRoutePath = '/reminders/:id/edit';

  final String? reminderId;

  bool get isEditing => reminderId != null && reminderId!.isNotEmpty;

  @override
  ConsumerState<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends ConsumerState<ReminderEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();

    final service = ref.read(remindersServiceProvider.notifier);
    final reminder = widget.reminderId == null
        ? null
        : service.findById(widget.reminderId!);

    _titleController = TextEditingController(text: reminder?.title ?? '');
    _noteController = TextEditingController(text: reminder?.note ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '編輯提醒' : '新增提醒'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onSave,
                  child: const Text('儲存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(remindersServiceProvider.notifier);

    service.save(
      id: widget.reminderId,
      title: _titleController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text,
    );

    context.pop();
  }
}
