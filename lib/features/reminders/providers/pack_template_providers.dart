import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pack_template_repository.dart';
import '../domain/pack_template.dart';
import 'database_providers.dart';

final packTemplateRepositoryProvider = Provider<PackTemplateRepository>((ref) {
  return PackTemplateRepository(ref.watch(appDatabaseProvider).reminderDao);
});

final customPackTemplatesProvider = StreamProvider<List<PackTemplate>>((ref) {
  return ref.watch(packTemplateRepositoryProvider).watchCustomTemplates();
});

final packTemplatesProvider = StreamProvider<List<PackTemplate>>((ref) {
  return ref.watch(packTemplateRepositoryProvider).watchPackTemplates();
});
