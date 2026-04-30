import 'package:flutter/material.dart';

import '../../data/local/item_timeline_dao.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/management_item_card_view_model.dart';

Future<void> showItemSummaryDialog(
  BuildContext context,
  ItemBundle bundle, {
  required DateTime previewDate,
}) {
  final viewModel = ManagementItemCardViewModel.fromBundle(
    bundle,
    now: previewDate,
  );
  final detailRows = <Widget>[
    _ItemDetailRow(label: ReminderUiText.itemLabel, value: viewModel.title),
    _ItemDetailRow(
      label: ReminderUiText.itemTypeFieldLabel,
      value: viewModel.typeLabel,
    ),
    _ItemDetailRow(
      label: ReminderUiText.packFieldLabel,
      value: viewModel.packTitle,
    ),
    if (viewModel.anchorDateLabel != null)
      _ItemDetailRow(
        label: ReminderUiText.itemStartDateLabel,
        value: viewModel.anchorDateLabel!,
      ),
    if (viewModel.dueDateLabel != null)
      _ItemDetailRow(
        label: ReminderUiText.itemDueDateLabel,
        value: viewModel.dueDateLabel!,
      ),
    if (viewModel.overduePolicyLabel != null)
      _ItemDetailRow(
        label: ReminderUiText.overduePolicyFieldLabel,
        value: viewModel.overduePolicyLabel!,
      ),
    if (viewModel.stateBaselineLabel != null)
      _ItemDetailRow(
        label: ReminderUiText.itemStateBaselineLabel,
        value: viewModel.stateBaselineLabel!,
      ),
    if (viewModel.remainingInventoryLabel != null)
      _ItemDetailRow(
        label: ReminderUiText.itemInventoryRemainingLabel,
        value: viewModel.remainingInventoryLabel!,
      ),
    if (viewModel.availableDaysLabel != null)
      _ItemDetailRow(
        label: ReminderUiText.itemAvailableDaysLabel,
        value: viewModel.availableDaysLabel!,
      ),
    _ItemDetailRow(
      label: ReminderUiText.itemLifecycleLabel,
      value: viewModel.lifecycleLabel,
    ),
    _ItemDetailRow(
      label: ReminderUiText.updatedAtLabel,
      value: viewModel.updatedAtLabel,
    ),
  ];

  final note = bundle.item.description?.trim();
  if (note != null && note.isNotEmpty) {
    detailRows.insert(3, _ItemDetailRow(label: '備註', value: note));
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: Key('item-detail-dialog-${bundle.item.id}'),
      title: const Text(ReminderUiText.itemDetailTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detailRows,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(ReminderUiText.closeAction),
        ),
      ],
    ),
  );
}

class _ItemDetailRow extends StatelessWidget {
  const _ItemDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}
