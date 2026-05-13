import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/item_timeline_dao.dart';
import '../data/resource_repository.dart';
import '../domain/resource.dart';
import 'database_providers.dart';

final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  return ResourceRepository(ref.watch(appDatabaseProvider).itemTimelineDao);
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

final itemConsumptionRulesProvider =
    StreamProvider.family<List<ResourceConsumptionRule>, int>((ref, itemId) {
      return ref.watch(resourceRepositoryProvider).watchRulesForItem(itemId);
    });
