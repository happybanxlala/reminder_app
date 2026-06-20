import 'dart:convert';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidBackupFormatException extends BackupException {
  const InvalidBackupFormatException() : super('檔案格式不正確');
}

class InvalidBackupAppException extends BackupException {
  const InvalidBackupAppException() : super('這不是 Reminder App 的備份檔');
}

class UnsupportedBackupVersionException extends BackupException {
  const UnsupportedBackupVersionException() : super('備份檔版本不支援');
}

class BackupPayload {
  const BackupPayload({
    required this.app,
    required this.schemaVersion,
    required this.exportedAt,
    required this.data,
  });

  static const appName = 'reminder_app';
  static const currentSchemaVersion = 3;

  final String app;
  final int schemaVersion;
  final DateTime exportedAt;
  final BackupData data;

  Map<String, Object?> toJson() {
    return {
      'app': app,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt.toIso8601String(),
      'data': data.toJson(),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  static BackupPayload fromJsonString(String source) {
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } catch (_) {
      throw const InvalidBackupFormatException();
    }
    if (decoded is! Map<String, Object?>) {
      throw const InvalidBackupFormatException();
    }
    return fromJson(decoded);
  }

  static BackupPayload fromJson(Map<String, Object?> json) {
    final app = json['app'];
    if (app is! String) {
      throw const InvalidBackupFormatException();
    }
    if (app != appName) {
      throw const InvalidBackupAppException();
    }

    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int) {
      throw const InvalidBackupFormatException();
    }
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw const UnsupportedBackupVersionException();
    }

    final exportedAtValue = json['exportedAt'];
    final exportedAt = exportedAtValue is String
        ? DateTime.tryParse(exportedAtValue)
        : null;
    final data = json['data'];
    if (exportedAt == null || data is! Map<String, Object?>) {
      throw const InvalidBackupFormatException();
    }

    return BackupPayload(
      app: app,
      schemaVersion: schemaVersion,
      exportedAt: exportedAt,
      data: BackupData.fromJson(data),
    );
  }
}

class BackupData {
  const BackupData({
    required this.packs,
    required this.items,
    required this.resources,
    required this.stages,
    required this.stageTrackers,
    required this.customTemplates,
    required this.relations,
    required this.activityLogs,
  });

  final List<Map<String, Object?>> packs;
  final List<Map<String, Object?>> items;
  final List<Map<String, Object?>> resources;
  final List<Map<String, Object?>> stages;
  final List<Map<String, Object?>> stageTrackers;
  final List<Map<String, Object?>> customTemplates;
  final List<Map<String, Object?>> relations;
  final List<Map<String, Object?>> activityLogs;

  Map<String, Object?> toJson() {
    return {
      'packs': packs,
      'items': items,
      'resources': resources,
      'stages': stages,
      'stageTrackers': stageTrackers,
      'customTemplates': customTemplates,
      'relations': relations,
      'activityLogs': activityLogs,
    };
  }

  static BackupData fromJson(Map<String, Object?> json) {
    return BackupData(
      packs: _listOfMaps(json, 'packs'),
      items: _listOfMaps(json, 'items'),
      resources: _listOfMaps(json, 'resources'),
      stages: _listOfMaps(json, 'stages'),
      stageTrackers: _listOfMaps(json, 'stageTrackers'),
      customTemplates: _listOfMaps(json, 'customTemplates'),
      relations: _listOfMaps(json, 'relations'),
      activityLogs: _listOfMaps(json, 'activityLogs'),
    );
  }

  static List<Map<String, Object?>> _listOfMaps(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is! List) {
      throw const InvalidBackupFormatException();
    }
    return [
      for (final entry in value)
        if (entry is Map<String, Object?>)
          Map<String, Object?>.from(entry)
        else
          throw const InvalidBackupFormatException(),
    ];
  }
}
