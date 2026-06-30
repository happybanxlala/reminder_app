class SharedPackApplicationResult<T> {
  const SharedPackApplicationResult._({this.value, this.error});

  factory SharedPackApplicationResult.success(T value) {
    return SharedPackApplicationResult._(value: value);
  }

  factory SharedPackApplicationResult.failure(
    SharedPackApplicationError error,
  ) {
    return SharedPackApplicationResult._(error: error);
  }

  final T? value;
  final SharedPackApplicationError? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  T get requireValue {
    final resultValue = value;
    if (resultValue == null || isFailure) {
      throw StateError('Shared Pack application result is not successful.');
    }
    return resultValue;
  }
}

class SharedPackApplicationError {
  const SharedPackApplicationError({
    required this.code,
    required this.message,
    this.requestId,
    this.cause,
  });

  final SharedPackApplicationErrorCode code;
  final String message;
  final String? requestId;
  final Object? cause;
}

enum SharedPackApplicationErrorCode {
  missingIdentity,
  missingPackMapping,
  missingItemMapping,
  remoteFailure,
  projectionFailure,
  invalidInput,
}
