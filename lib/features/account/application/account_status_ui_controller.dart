import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_identity.dart';
import 'account_identity_runtime.dart';

final accountIdentityRuntimeProvider = Provider<AccountIdentityRuntime>((ref) {
  return const DefaultUnboundAccountIdentityRuntime();
});

final accountStatusUiModelProvider = FutureProvider<AccountStatusUiModel>((
  ref,
) async {
  final runtime = ref.watch(accountIdentityRuntimeProvider);
  return AccountStatusUiController(runtime).currentStatus();
});

class AccountStatusUiController {
  const AccountStatusUiController(this._runtime);

  final AccountIdentityRuntime _runtime;

  Future<AccountStatusUiModel> currentStatus() async {
    final snapshot = await _runtime.currentSnapshot();
    return AccountStatusUiModel.fromSnapshot(snapshot);
  }
}

class AccountStatusUiModel {
  const AccountStatusUiModel({
    required this.status,
    required this.title,
    required this.body,
    required this.note,
    required this.isAccountProtected,
    required this.isPersonalCloudMigrationComplete,
    this.showProgress = false,
  });

  factory AccountStatusUiModel.fromSnapshot(AccountIdentitySnapshot snapshot) {
    switch (snapshot.status) {
      case AccountBindingStatus.unbound:
        return const AccountStatusUiModel(
          status: AccountBindingStatus.unbound,
          title: '帳號未綁定',
          body: '此裝置上的 Personal Pack 資料尚未受到帳號保護。',
          note: '綁定帳號後，日後可支援雲端備份與換機恢復。Shared Pack 功能亦會使用帳號保護成員身份。',
          isAccountProtected: false,
          isPersonalCloudMigrationComplete: false,
        );
      case AccountBindingStatus.binding:
        return const AccountStatusUiModel(
          status: AccountBindingStatus.binding,
          title: '正在綁定帳號',
          body: '正在準備帳號保護。',
          note: 'Personal Pack 雲端同步將於後續階段處理。',
          isAccountProtected: false,
          isPersonalCloudMigrationComplete: false,
          showProgress: true,
        );
      case AccountBindingStatus.bound:
        return const AccountStatusUiModel(
          status: AccountBindingStatus.bound,
          title: '帳號已綁定',
          body: '此裝置已有帳號保護身份。',
          note: 'Personal Pack 雲端同步將於後續階段處理。',
          isAccountProtected: true,
          isPersonalCloudMigrationComplete: false,
        );
      case AccountBindingStatus.bindingFailed:
        return const AccountStatusUiModel(
          status: AccountBindingStatus.bindingFailed,
          title: '帳號綁定未完成',
          body: '帳號綁定未能完成，請稍後再試。',
          note: 'Personal Pack 資料尚未完成帳號保護。',
          isAccountProtected: false,
          isPersonalCloudMigrationComplete: false,
        );
      case AccountBindingStatus.needsReauth:
        return const AccountStatusUiModel(
          status: AccountBindingStatus.needsReauth,
          title: '需要重新驗證帳號',
          body: '請重新驗證帳號，之後才能繼續使用帳號保護功能。',
          note: '完成驗證前，帳號保護功能會保持暫停。',
          isAccountProtected: false,
          isPersonalCloudMigrationComplete: false,
        );
    }
  }

  final AccountBindingStatus status;
  final String title;
  final String body;
  final String note;
  final bool isAccountProtected;
  final bool isPersonalCloudMigrationComplete;
  final bool showProgress;
}
