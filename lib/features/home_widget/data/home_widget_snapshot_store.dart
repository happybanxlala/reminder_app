import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'home_widget_snapshot.dart';

abstract class HomeWidgetSnapshotStore {
  Future<HomeWidgetSnapshot?> readSnapshot();

  Future<void> writeSnapshot(HomeWidgetSnapshot snapshot);
}

class FileHomeWidgetSnapshotStore implements HomeWidgetSnapshotStore {
  const FileHomeWidgetSnapshotStore({
    this.fileName = 'home_widget_snapshot.json',
    this.directoryProvider,
  });

  final String fileName;
  final Future<Directory?> Function()? directoryProvider;

  @override
  Future<HomeWidgetSnapshot?> readSnapshot() async {
    final file = await _snapshotFile();
    if (!await file.exists()) {
      return null;
    }
    final source = await file.readAsString();
    return HomeWidgetSnapshot.fromJsonString(source);
  }

  @override
  Future<void> writeSnapshot(HomeWidgetSnapshot snapshot) async {
    final file = await _snapshotFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(snapshot.toJsonString());
  }

  Future<File> _snapshotFile() async {
    final directory =
        await directoryProvider?.call() ??
        await getApplicationSupportDirectory();
    return File(p.join(directory.path, fileName));
  }
}
