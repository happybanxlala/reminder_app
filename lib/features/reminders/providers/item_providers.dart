import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/item_repository.dart';
import '../data/local/item_timeline_dao.dart';
import '../domain/item_pack.dart';
import 'database_providers.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(appDatabaseProvider).itemTimelineDao);
});

final itemPacksProvider = StreamProvider<List<ItemPack>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPacks(includeArchived: true);
});

final activeItemPacksProvider = StreamProvider<List<ItemPack>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPacks();
});

final itemsProvider = StreamProvider<List<ItemBundle>>((ref) {
  return ref.watch(itemRepositoryProvider).watchItems();
});

final packManagementItemsProvider = StreamProvider<List<ItemBundle>>((ref) {
  return ref.watch(itemRepositoryProvider).watchPackManagementItems();
});

final itemProvider = FutureProvider.family<ItemBundle?, int>((ref, id) {
  return ref.watch(itemRepositoryProvider).getItemById(id);
});

final itemPackProvider = FutureProvider.family<ItemPack?, int>((ref, id) {
  return ref.watch(itemRepositoryProvider).getPackById(id);
});
