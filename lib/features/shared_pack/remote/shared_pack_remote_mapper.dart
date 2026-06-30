import 'shared_pack_remote_dto.dart';

class SharedPackRemoteMapper {
  const SharedPackRemoteMapper._();

  static String normalizeInviteCode(String value) {
    return value.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
  }

  static Map<String, dynamic> singleRow(
    Object? response, {
    required String requestId,
    required String operation,
  }) {
    if (response is List && response.length == 1) {
      final row = response.single;
      if (row is Map) {
        return row.cast<String, dynamic>();
      }
    }

    if (response is Map) {
      return response.cast<String, dynamic>();
    }

    throw SharedPackRemoteException(
      requestId: requestId,
      operation: operation,
      message: 'Unexpected RPC response shape.',
    );
  }

  static String requiredString(
    Map<String, dynamic> row,
    String field, {
    required String requestId,
    required String operation,
  }) {
    final value = row[field];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw _missingField(requestId, operation, field);
  }

  static String? optionalString(Map<String, dynamic> row, String field) {
    final value = row[field];
    return value is String && value.isNotEmpty ? value : null;
  }

  static bool requiredBool(
    Map<String, dynamic> row,
    String field, {
    required String requestId,
    required String operation,
  }) {
    final value = row[field];
    if (value is bool) {
      return value;
    }
    throw _missingField(requestId, operation, field);
  }

  static DateTime requiredDateTime(
    Map<String, dynamic> row,
    String field, {
    required String requestId,
    required String operation,
  }) {
    final parsed = optionalDateTime(row, field);
    if (parsed != null) {
      return parsed;
    }
    throw _missingField(requestId, operation, field);
  }

  static DateTime? optionalDateTime(Map<String, dynamic> row, String field) {
    final value = row[field];
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static List<SharedPackSnapshotItemRemoteDto> snapshotItems(
    Object? value, {
    required String requestId,
    required String operation,
  }) {
    if (value is! List) {
      throw _missingField(requestId, operation, 'items');
    }

    return value
        .map((item) {
          if (item is! Map) {
            throw _missingField(requestId, operation, 'items');
          }
          final row = item.cast<String, dynamic>();
          return SharedPackSnapshotItemRemoteDto(
            remoteItemId: requiredString(
              row,
              'id',
              requestId: requestId,
              operation: operation,
            ),
            title: requiredString(
              row,
              'title',
              requestId: requestId,
              operation: operation,
            ),
            notes: optionalString(row, 'notes'),
            schedulePayload: _optionalMap(row, 'schedule_payload'),
            state: requiredString(
              row,
              'state',
              requestId: requestId,
              operation: operation,
            ),
            lastCompletedAt: optionalDateTime(row, 'last_completed_at'),
            updatedByIdentityId: optionalString(row, 'updated_by_identity_id'),
            createdAt: requiredDateTime(
              row,
              'created_at',
              requestId: requestId,
              operation: operation,
            ),
            updatedAt: requiredDateTime(
              row,
              'updated_at',
              requestId: requestId,
              operation: operation,
            ),
            archivedAt: optionalDateTime(row, 'archived_at'),
          );
        })
        .toList(growable: false);
  }

  static Map<String, dynamic>? _optionalMap(
    Map<String, dynamic> row,
    String field,
  ) {
    final value = row[field];
    if (value == null) {
      return null;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  static SharedPackRemoteException _missingField(
    String requestId,
    String operation,
    String field,
  ) {
    return SharedPackRemoteException(
      requestId: requestId,
      operation: operation,
      message: 'Missing or invalid RPC response field: $field.',
    );
  }
}
