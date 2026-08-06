import '../domain/shared_equality.dart';

final class PreviewInviteQuery extends SharedValue {
  PreviewInviteQuery({required this.userEnteredCode}) {
    if (userEnteredCode.trim().isEmpty) {
      throw ArgumentError.value(userEnteredCode, 'userEnteredCode', 'is empty');
    }
  }

  final String userEnteredCode;

  @override
  List<Object?> get equalityFields => [userEnteredCode];
}
