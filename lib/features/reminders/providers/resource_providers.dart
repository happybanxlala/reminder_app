import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/reminder_dao.dart';
import '../data/resource_repository.dart';
import '../domain/resource.dart';
import 'database_providers.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository(ref.watch(appDatabaseProvider).reminderDao);
});

final resourcesProvider = StreamProvider<List<ResourceBundle>>((ref) {
  return ref.watch(resourceRepositoryProvider).watchResources();
});

final managedResourcesProvider = StreamProvider<List<ResourceBundle>>((ref) {
  return ref.watch(resourceRepositoryProvider).watchManagedResources();
});

final resourceProvider = FutureProvider.family<ResourceBundle?, int>((ref, id) {
  return ref.watch(resourceRepositoryProvider).getResourceById(id);
});

final resourceBindingsProvider =
    StreamProvider.family<List<ResourceBinding>, int>((ref, resourceId) {
      return ref.watch(resourceRepositoryProvider).watchBindings(resourceId);
    });

final resourceActionHistoryProvider =
    StreamProvider.family<List<ResourceActionRecord>, int>((ref, resourceId) {
      return ref
          .watch(resourceRepositoryProvider)
          .watchActionHistory(resourceId);
    });

final resourceActionHistoryEntriesProvider =
    StreamProvider.family<List<ResourceActionHistoryEntry>, int>((
      ref,
      resourceId,
    ) {
      return ref
          .watch(resourceRepositoryProvider)
          .watchActionHistoryEntries(resourceId);
    });

final resourceActionHistoryEntriesWithRevertedProvider =
    StreamProvider.family<List<ResourceActionHistoryEntry>, int>((
      ref,
      resourceId,
    ) {
      return ref
          .watch(resourceRepositoryProvider)
          .watchActionHistoryEntries(resourceId, includeReverted: true);
    });

final itemConsumptionRulesProvider =
    StreamProvider.family<List<ResourceConsumptionRule>, int>((ref, itemId) {
      return ref.watch(resourceRepositoryProvider).watchRulesForItem(itemId);
    });
