import 'dart:convert';

enum ItemActionType { done, skipped, deferred }

class ItemActionRecord {
  const ItemActionRecord({
    required this.id,
    required this.itemId,
    required this.actionType,
    required this.actionDate,
    this.remark,
    this.payload,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int itemId;
  final ItemActionType actionType;
  final DateTime actionDate;
  final String? remark;
  final Map<String, Object?>? payload;
  final DateTime createdAt;
  final DateTime updatedAt;

  static Map<String, Object?>? decodePayload(String? source) {
    if (source == null || source.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(source);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }

  static String? encodePayload(Map<String, Object?>? payload) {
    if (payload == null || payload.isEmpty) {
      return null;
    }
    return jsonEncode(payload);
  }
}
