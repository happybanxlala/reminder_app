import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/responsibility_timeline_dao.dart';
import '../data/responsibility_repository.dart';
import '../domain/responsibility_pack.dart';
import 'database_providers.dart';

final responsibilityRepositoryProvider = Provider<ResponsibilityRepository>((
  ref,
) {
  return ResponsibilityRepository(
    ref.watch(appDatabaseProvider).responsibilityTimelineDao,
  );
});

final responsibilityPacksProvider = StreamProvider<List<ResponsibilityPack>>((
  ref,
) {
  return ref.watch(responsibilityRepositoryProvider).watchPacks();
});

final activeResponsibilityPacksProvider =
    StreamProvider<List<ResponsibilityPack>>((ref) {
      return ref.watch(responsibilityRepositoryProvider).watchPacks();
    });

final responsibilityItemsProvider =
    StreamProvider<List<ResponsibilityItemBundle>>((ref) {
      return ref.watch(responsibilityRepositoryProvider).watchItems();
    });

final responsibilityItemProvider =
    FutureProvider.family<ResponsibilityItemBundle?, int>((ref, id) {
      return ref.watch(responsibilityRepositoryProvider).getItemById(id);
    });

final responsibilityPackProvider =
    FutureProvider.family<ResponsibilityPack?, int>((ref, id) {
      return ref.watch(responsibilityRepositoryProvider).getPackById(id);
    });
