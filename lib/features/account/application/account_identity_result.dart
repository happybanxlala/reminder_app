import 'account_identity.dart';

class AccountIdentityUnavailableException implements Exception {
  const AccountIdentityUnavailableException({
    required this.status,
    required this.message,
  });

  final AccountBindingStatus status;
  final String message;

  @override
  String toString() {
    return 'AccountIdentityUnavailableException(status: $status, message: $message)';
  }
}
