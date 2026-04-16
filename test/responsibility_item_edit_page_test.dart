import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/reminders/data/local/responsibility_timeline_dao.dart';
import 'package:reminder_app/features/reminders/domain/responsibility_item.dart';
import 'package:reminder_app/features/reminders/domain/responsibility_pack.dart';
import 'package:reminder_app/features/reminders/providers/responsibility_providers.dart';
import 'package:reminder_app/features/reminders/ui/pages/responsibility_item_edit_page.dart';

void main() {
  testWidgets('responsibility item editor toggles fields by item type', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ResponsibilityItemEditPage(
            mode: ResponsibilityItemEditMode.create,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('expected-interval-field')), findsOneWidget);
    expect(find.byKey(const Key('estimated-duration-field')), findsNothing);

    await tester.tap(find.text(ResponsibilityItemType.stateBased.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ResponsibilityItemType.resourceBased.name).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expected-interval-field')), findsNothing);
    expect(find.byKey(const Key('estimated-duration-field')), findsOneWidget);
  });

  testWidgets('editor loads existing state-based responsibility item', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          responsibilityItemProvider(7).overrideWith(
            (ref) => Future.value(
              ResponsibilityItemBundle(
                item: ResponsibilityItem(
                  id: 7,
                  packId: 1,
                  title: 'Weekly grooming',
                  description: 'Brush and trim',
                  type: ResponsibilityItemType.stateBased,
                  config: const StateBasedItemConfig(
                    expectedInterval: Duration(days: 7),
                    warningAfter: Duration(days: 7),
                    dangerAfter: Duration(days: 14),
                  ),
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
                pack: ResponsibilityPack(
                  id: 1,
                  title: 'Default Responsibility Pack',
                  createdAt: DateTime(2026, 4, 1),
                  updatedAt: DateTime(2026, 4, 2),
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ResponsibilityItemEditPage(
            mode: ResponsibilityItemEditMode.edit,
            id: 7,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Weekly grooming'), findsOneWidget);
    expect(find.text('Brush and trim'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.byKey(const Key('danger-after-field')), findsOneWidget);
  });
}
