import 'shared_equality.dart';

const int sharedSignedInt64Max = 9223372036854775807;
const int sharedMaximumThresholdMinutes = 5258880;

abstract class _PositiveVersion extends SharedValue {
  _PositiveVersion(this.value, String label) {
    if (value < 1 || value > sharedSignedInt64Max) {
      throw RangeError.range(value, 1, sharedSignedInt64Max, label);
    }
  }

  final int value;

  @override
  List<Object?> get equalityFields => [value];

  @override
  String toString() => '$value';
}

final class RemotePackVersion extends _PositiveVersion {
  RemotePackVersion(int value) : super(value, 'remotePackVersion');
}

final class RemoteItemVersion extends _PositiveVersion {
  RemoteItemVersion(int value) : super(value, 'remoteItemVersion');
}

/// Shared remote request/response contract major version.
final class RemoteApiContractVersion extends _PositiveVersion {
  RemoteApiContractVersion(int value)
    : super(value, 'remoteApiContractVersion');

  static final RemoteApiContractVersion v1 = RemoteApiContractVersion(1);
}

/// Full active snapshot schema version supported by the client.
final class RemoteSnapshotSchemaVersion extends _PositiveVersion {
  RemoteSnapshotSchemaVersion(int value)
    : super(value, 'remoteSnapshotSchemaVersion');

  static final RemoteSnapshotSchemaVersion v1 = RemoteSnapshotSchemaVersion(1);
}

/// A UTC instant. Device-local time is never accepted as business time.
final class UtcInstant extends SharedValue implements Comparable<UtcInstant> {
  UtcInstant(DateTime value) : value = _requireUtc(value);

  final DateTime value;

  static DateTime _requireUtc(DateTime value) {
    if (!value.isUtc) {
      throw ArgumentError.value(value, 'value', 'must be a UTC DateTime');
    }
    return value;
  }

  @override
  int compareTo(UtcInstant other) => value.compareTo(other.value);

  @override
  List<Object?> get equalityFields => [value.microsecondsSinceEpoch];

  @override
  String toString() => value.toIso8601String();
}

/// Lowercase hexadecimal fingerprint value without defining its algorithm.
final class SharedPayloadFingerprint extends SharedValue {
  SharedPayloadFingerprint(this.value) {
    if (!_valid.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'must be 32–128 lowercase hexadecimal characters of even length',
      );
    }
  }

  static final RegExp _valid = RegExp(r'^(?:[0-9a-f]{2}){16,64}$');

  final String value;

  @override
  List<Object?> get equalityFields => [value];
}
