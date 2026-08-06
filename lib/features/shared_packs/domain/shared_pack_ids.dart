import 'shared_equality.dart';

abstract class _OpaqueSharedId extends SharedValue {
  _OpaqueSharedId(this.value, String label) {
    if (value.isEmpty || value.length > 128) {
      throw ArgumentError.value(value, label, 'must contain 1–128 characters');
    }
  }

  final String value;

  @override
  List<Object?> get equalityFields => [value];

  @override
  String toString() => value;
}

/// Opaque authoritative Shared Pack identity.
final class RemotePackId extends _OpaqueSharedId {
  RemotePackId(String value) : super(value, 'remotePackId');
}

/// Pack-scoped authoritative membership and actor identity.
final class RemoteMemberId extends _OpaqueSharedId {
  RemoteMemberId(String value) : super(value, 'remoteMemberId');
}

/// Pack-scoped authoritative Shared Item identity.
final class RemoteItemId extends _OpaqueSharedId {
  RemoteItemId(String value) : super(value, 'remoteItemId');
}

/// Opaque remote identity used only by the identity application port.
final class SharedIdentityId extends _OpaqueSharedId {
  SharedIdentityId(String value) : super(value, 'sharedIdentityId');
}

/// One logical mutation identity. Retries must reuse this exact value.
final class ClientRequestId extends SharedValue {
  ClientRequestId(this.value) {
    if (!_uuidV4.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'clientRequestId',
        'must be a canonical lowercase UUID v4',
      );
    }
  }

  static final RegExp _uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  final String value;

  @override
  List<Object?> get equalityFields => [value];

  @override
  String toString() => value;
}
