/// Small framework-free value equality base used by Shared Pack contracts.
abstract class SharedValue {
  const SharedValue();

  List<Object?> get equalityFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is SharedValue &&
          _listEquals(equalityFields, other.equalityFields);

  @override
  int get hashCode => Object.hashAll(equalityFields.map(_deepHash));
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a is List && b is List) {
      if (!_listEquals(a.cast<Object?>(), b.cast<Object?>())) return false;
    } else if (a != b) {
      return false;
    }
  }
  return true;
}

int _deepHash(Object? value) =>
    value is List ? Object.hashAll(value.map(_deepHash)) : value.hashCode;
