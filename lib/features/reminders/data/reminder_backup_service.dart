import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_models.dart';
import 'local/reminder_dao.dart';

class ReminderBackupService {
  const ReminderBackupService(this._dao);

  final ReminderDao _dao;

  Future<BackupPayload> exportPayload({DateTime? exportedAt}) async {
    final data = await _dao.exportBackupData();
    return BackupPayload(
      app: BackupPayload.appName,
      schemaVersion: BackupPayload.currentSchemaVersion,
      exportedAt: exportedAt ?? DateTime.now(),
      data: data,
    );
  }

  Future<String> exportJsonString({DateTime? exportedAt}) async {
    return (await exportPayload(exportedAt: exportedAt)).toPrettyJson();
  }

  Future<File> writeBackupFile({DateTime? exportedAt}) async {
    final timestamp = exportedAt ?? DateTime.now();
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, backupFileName(timestamp)));
    await file.writeAsString(await exportJsonString(exportedAt: timestamp));
    return file;
  }

  Future<File> backupAndShare({DateTime? exportedAt}) async {
    final file = await writeBackupFile(exportedAt: exportedAt);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Reminder App backup',
        files: [XFile(file.path, mimeType: 'application/json')],
      ),
    );
    return file;
  }

  Future<bool> pickAndImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return false;
    }
    final file = result.files.single;
    final bytes = file.bytes;
    final source = bytes != null
        ? utf8.decode(bytes)
        : await File(file.path!).readAsString();
    await importJsonString(source);
    return true;
  }

  Future<void> importJsonString(String source) async {
    final payload = BackupPayload.fromJsonString(source);
    await _dao.replaceUserDataFromBackup(payload.data);
  }

  Future<void> resetDatabase() {
    return _dao.resetUserData();
  }

  static String backupFileName(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return 'reminder_app_backup_$year$month${day}_$hour$minute.json';
  }
}
