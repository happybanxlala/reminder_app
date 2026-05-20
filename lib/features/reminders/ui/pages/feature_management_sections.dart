import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/reminder_theme.dart';
import '../../data/item_repository.dart';
import '../../data/local/reminder_dao.dart';
import '../../data/resource_repository.dart';
import '../../domain/item.dart';
import '../../domain/item_pack.dart';
import '../../domain/resource.dart';
import '../../presentation/formatters/reminder_formatters.dart';
import '../../presentation/text/reminder_ui_text.dart';
import '../../presentation/view_models/management_item_card_view_model.dart';
import '../../providers/developer_settings_providers.dart';
import '../../providers/item_providers.dart';
import '../../providers/resource_providers.dart';
import '../../providers/settings_providers.dart';
import 'item_edit_page.dart';
import 'item_history_page.dart';
import 'resource_history_page.dart';
import '../widgets/editor_common_fields.dart';
import '../widgets/item_config_form_section.dart';
import '../widgets/pack_picker.dart';
import '../widgets/resource_binding_draft_section.dart';
import '../widgets/item_summary_dialog.dart';
import '../widgets/reminder_components.dart';

part 'feature_management_items.dart';
part 'feature_management_resources.dart';
part 'feature_management_dialogs.dart';

class ItemsManagementContent extends ConsumerStatefulWidget {
  const ItemsManagementContent({super.key});

  @override
  ConsumerState<ItemsManagementContent> createState() =>
      _ItemsManagementContentState();
}

class _ItemsManagementContentState
    extends ConsumerState<ItemsManagementContent> {
  final Set<int> _collapsedPackIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(itemManagementGroupsProvider);
    final previewDate = ref.watch(effectivePreviewDateProvider);

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(_ManagementDensity.pagePadding),
            children: [
              _ItemManagementHeader(
                onOpenResources: () =>
                    context.pushNamed(ResourceManagementPage.routeName),
                onAddItem: () => _showCreateItemDialog(context, ref),
              ),
              const SizedBox(height: _ManagementDensity.groupGap),
              const ReminderEmptyState(
                message: ReminderUiText.noDefaultItemPack,
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(_ManagementDensity.pagePadding),
          children: [
            _ItemManagementHeader(
              onOpenResources: () =>
                  context.pushNamed(ResourceManagementPage.routeName),
              onAddItem: () => _showCreateItemDialog(context, ref),
            ),
            const SizedBox(height: _ManagementDensity.groupGap),
            ...groups.map(
              (group) => Padding(
                padding: const EdgeInsets.only(
                  bottom: _ManagementDensity.groupGap,
                ),
                child: _ItemManagementGroupCard(
                  group: group,
                  previewDate: previewDate,
                  expanded: !_collapsedPackIds.contains(group.pack.id),
                  onToggle: () {
                    setState(() {
                      if (_collapsedPackIds.contains(group.pack.id)) {
                        _collapsedPackIds.remove(group.pack.id);
                      } else {
                        _collapsedPackIds.add(group.pack.id);
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
      error: (error, stack) => Center(child: Text('讀取失敗: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class ItemPacksManagementContent extends StatelessWidget {
  const ItemPacksManagementContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ItemsManagementContent();
  }
}
