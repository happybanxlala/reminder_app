import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shared_pack_cache_projection_service.dart';
import 'shared_pack_application_result.dart';
import 'shared_pack_application_service.dart';

final sharedPackUiControllerProvider = Provider<SharedPackUiController>((ref) {
  return const DisabledSharedPackUiController(
    reason: SharedPackUiAvailability.productionSetupRequiredReason,
  );
});

class SharedPackUiAvailability {
  const SharedPackUiAvailability._({
    required this.isEnabled,
    required this.reason,
  });

  const SharedPackUiAvailability.enabled()
    : this._(isEnabled: true, reason: '');

  const SharedPackUiAvailability.disabled(String reason)
    : this._(isEnabled: false, reason: reason);

  static const productionSetupRequiredReason = '需要先完成安全連線設定與身份來源，才能使用共享 Pack。';

  final bool isEnabled;
  final String reason;
}

abstract class SharedPackUiController {
  SharedPackUiAvailability get availability;

  Future<bool> canRefreshSharedPack({required int localPackId});

  Future<bool> canUpdateSharedItemState({required int localItemId});

  Future<SharedPackUiActionResult<SharedPackGeneratedInviteUiModel>>
  generateInvite({int? localPackId, String? remotePackId});

  Future<SharedPackUiActionResult<SharedPackInvitePreviewUiModel>>
  previewInvite({required String inviteCode});

  Future<SharedPackUiActionResult<SharedPackJoinedPackUiModel>> joinByInvite({
    required String inviteCode,
  });

  Future<SharedPackUiActionResult<SharedPackRefreshUiModel>> refreshSharedPack({
    int? localPackId,
    String? remotePackId,
  });

  Future<SharedPackUiActionResult<SharedPackItemStateUiModel>>
  updateSharedItemState({
    int? localItemId,
    String? remoteItemId,
    required String newState,
    DateTime? completedAt,
  });
}

class DisabledSharedPackUiController implements SharedPackUiController {
  const DisabledSharedPackUiController({required String reason})
    : _reason = reason;

  final String _reason;

  @override
  SharedPackUiAvailability get availability =>
      SharedPackUiAvailability.disabled(_reason);

  @override
  Future<bool> canRefreshSharedPack({required int localPackId}) async => false;

  @override
  Future<bool> canUpdateSharedItemState({required int localItemId}) async =>
      false;

  @override
  Future<SharedPackUiActionResult<SharedPackGeneratedInviteUiModel>>
  generateInvite({int? localPackId, String? remotePackId}) async {
    return _disabled();
  }

  @override
  Future<SharedPackUiActionResult<SharedPackInvitePreviewUiModel>>
  previewInvite({required String inviteCode}) async {
    return _disabled();
  }

  @override
  Future<SharedPackUiActionResult<SharedPackJoinedPackUiModel>> joinByInvite({
    required String inviteCode,
  }) async {
    return _disabled();
  }

  @override
  Future<SharedPackUiActionResult<SharedPackRefreshUiModel>> refreshSharedPack({
    int? localPackId,
    String? remotePackId,
  }) async {
    return _disabled();
  }

  @override
  Future<SharedPackUiActionResult<SharedPackItemStateUiModel>>
  updateSharedItemState({
    int? localItemId,
    String? remoteItemId,
    required String newState,
    DateTime? completedAt,
  }) async {
    return _disabled();
  }

  SharedPackUiActionResult<T> _disabled<T>() {
    return SharedPackUiActionResult.failure(
      message: _reason,
      code: SharedPackApplicationErrorCode.missingIdentity,
    );
  }
}

class SharedPackApplicationUiController implements SharedPackUiController {
  const SharedPackApplicationUiController({
    required SharedPackApplicationService service,
    Future<bool> Function(int localPackId)? canRefreshLocalPack,
    Future<bool> Function(int localItemId)? canUpdateLocalItem,
  }) : _service = service,
       _canRefreshLocalPack = canRefreshLocalPack,
       _canUpdateLocalItem = canUpdateLocalItem;

  final SharedPackApplicationService _service;
  final Future<bool> Function(int localPackId)? _canRefreshLocalPack;
  final Future<bool> Function(int localItemId)? _canUpdateLocalItem;

  @override
  SharedPackUiAvailability get availability =>
      const SharedPackUiAvailability.enabled();

  @override
  Future<bool> canRefreshSharedPack({required int localPackId}) {
    return _canRefreshLocalPack?.call(localPackId) ?? Future.value(false);
  }

  @override
  Future<bool> canUpdateSharedItemState({required int localItemId}) {
    return _canUpdateLocalItem?.call(localItemId) ?? Future.value(false);
  }

  @override
  Future<SharedPackUiActionResult<SharedPackGeneratedInviteUiModel>>
  generateInvite({int? localPackId, String? remotePackId}) async {
    final result = await _service.generateInvite(
      localPackId: localPackId,
      remotePackId: remotePackId,
    );
    return _fromApplication(result, (response) {
      return SharedPackGeneratedInviteUiModel(
        inviteCode: normalizeSharedPackInviteCode(response.inviteCode),
        expiresAt: response.expiresAt,
      );
    });
  }

  @override
  Future<SharedPackUiActionResult<SharedPackInvitePreviewUiModel>>
  previewInvite({required String inviteCode}) async {
    final result = await _service.previewInvite(
      inviteCode: normalizeSharedPackInviteCode(inviteCode),
    );
    return _fromApplication(result, (response) {
      return SharedPackInvitePreviewUiModel(
        remotePackId: response.remotePackId,
        packName: response.packName,
        isJoinable: response.isJoinable,
      );
    });
  }

  @override
  Future<SharedPackUiActionResult<SharedPackJoinedPackUiModel>> joinByInvite({
    required String inviteCode,
  }) async {
    final result = await _service.joinByInvite(
      inviteCode: normalizeSharedPackInviteCode(inviteCode),
    );
    return _fromApplication(result, (success) {
      return SharedPackJoinedPackUiModel(
        remotePackId: success.remoteResponse.remotePackId,
        packName: success.remoteResponse.packName,
        localPackId: success.projection.localPackId,
        refreshRecommended: success.refreshRecommended,
      );
    });
  }

  @override
  Future<SharedPackUiActionResult<SharedPackRefreshUiModel>> refreshSharedPack({
    int? localPackId,
    String? remotePackId,
  }) async {
    final result = await _service.refreshSharedPack(
      localPackId: localPackId,
      remotePackId: remotePackId,
    );
    return _fromApplication(result, (projection) {
      return SharedPackRefreshUiModel(
        localPackId: projection.localPackId,
        remotePackId: projection.remotePackId,
        createdItemsCount: projection.createdItemsCount,
        updatedItemsCount: projection.updatedItemsCount,
      );
    });
  }

  @override
  Future<SharedPackUiActionResult<SharedPackItemStateUiModel>>
  updateSharedItemState({
    int? localItemId,
    String? remoteItemId,
    required String newState,
    DateTime? completedAt,
  }) async {
    final result = await _service.updateSharedItemState(
      localItemId: localItemId,
      remoteItemId: remoteItemId,
      newState: newState,
      completedAt: completedAt,
    );
    return _fromApplication(result, (projection) {
      if (projection.status ==
          SharedPackItemStateProjectionStatus.missingMapping) {
        return SharedPackItemStateUiModel.missingMapping(
          remoteItemId: projection.remoteItemId,
          remotePackId: projection.remotePackId,
        );
      }
      return SharedPackItemStateUiModel.projected(
        localItemId: projection.localItemId!,
        localPackId: projection.localPackId!,
        remoteItemId: projection.remoteItemId,
        remotePackId: projection.remotePackId,
      );
    });
  }

  SharedPackUiActionResult<R> _fromApplication<T, R>(
    SharedPackApplicationResult<T> result,
    R Function(T value) map,
  ) {
    if (result.isSuccess) {
      return SharedPackUiActionResult.success(map(result.requireValue));
    }

    final error = result.error!;
    return SharedPackUiActionResult.failure(
      message: _messageFor(error),
      code: error.code,
      requestId: error.requestId,
    );
  }

  String _messageFor(SharedPackApplicationError error) {
    switch (error.code) {
      case SharedPackApplicationErrorCode.missingIdentity:
        return '需要先完成共享 Pack 身份設定。';
      case SharedPackApplicationErrorCode.missingPackMapping:
        return '這個 Pack 尚未準備好共享。';
      case SharedPackApplicationErrorCode.missingItemMapping:
        return '這個事項尚未準備好共享。';
      case SharedPackApplicationErrorCode.remoteFailure:
        return '共享 Pack 連線暫時無法完成。';
      case SharedPackApplicationErrorCode.projectionFailure:
        return '共享 Pack 已回應，但本機資料更新失敗。';
      case SharedPackApplicationErrorCode.invalidInput:
        return '請確認輸入內容。';
    }
  }
}

class SharedPackUiActionResult<T> {
  const SharedPackUiActionResult._({this.value, this.error});

  factory SharedPackUiActionResult.success(T value) {
    return SharedPackUiActionResult._(value: value);
  }

  factory SharedPackUiActionResult.failure({
    required String message,
    SharedPackApplicationErrorCode? code,
    String? requestId,
  }) {
    return SharedPackUiActionResult._(
      error: SharedPackUiError(
        message: message,
        code: code,
        requestId: requestId,
      ),
    );
  }

  final T? value;
  final SharedPackUiError? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  T get requireValue {
    final resultValue = value;
    if (resultValue == null || isFailure) {
      throw StateError('Shared Pack UI action did not succeed.');
    }
    return resultValue;
  }
}

class SharedPackUiError {
  const SharedPackUiError({required this.message, this.code, this.requestId});

  final String message;
  final SharedPackApplicationErrorCode? code;
  final String? requestId;
}

class SharedPackGeneratedInviteUiModel {
  SharedPackGeneratedInviteUiModel({
    required String inviteCode,
    required this.expiresAt,
  }) : inviteCode = normalizeSharedPackInviteCode(inviteCode);

  final String inviteCode;
  final DateTime? expiresAt;

  String get groupedInviteCode => groupSharedPackInviteCode(inviteCode);
}

class SharedPackInvitePreviewUiModel {
  const SharedPackInvitePreviewUiModel({
    required this.remotePackId,
    required this.packName,
    required this.isJoinable,
  });

  final String? remotePackId;
  final String? packName;
  final bool isJoinable;
}

class SharedPackJoinedPackUiModel {
  const SharedPackJoinedPackUiModel({
    required this.remotePackId,
    required this.packName,
    required this.localPackId,
    required this.refreshRecommended,
  });

  final String remotePackId;
  final String packName;
  final int localPackId;
  final bool refreshRecommended;
}

class SharedPackRefreshUiModel {
  const SharedPackRefreshUiModel({
    required this.localPackId,
    required this.remotePackId,
    required this.createdItemsCount,
    required this.updatedItemsCount,
  });

  final int localPackId;
  final String remotePackId;
  final int createdItemsCount;
  final int updatedItemsCount;
}

class SharedPackItemStateUiModel {
  const SharedPackItemStateUiModel._({
    required this.status,
    required this.remoteItemId,
    required this.remotePackId,
    this.localItemId,
    this.localPackId,
  });

  factory SharedPackItemStateUiModel.projected({
    required int localItemId,
    required int localPackId,
    required String remoteItemId,
    required String remotePackId,
  }) {
    return SharedPackItemStateUiModel._(
      status: SharedPackItemStateUiStatus.projected,
      localItemId: localItemId,
      localPackId: localPackId,
      remoteItemId: remoteItemId,
      remotePackId: remotePackId,
    );
  }

  factory SharedPackItemStateUiModel.missingMapping({
    required String remoteItemId,
    required String remotePackId,
  }) {
    return SharedPackItemStateUiModel._(
      status: SharedPackItemStateUiStatus.missingMapping,
      remoteItemId: remoteItemId,
      remotePackId: remotePackId,
    );
  }

  final SharedPackItemStateUiStatus status;
  final int? localItemId;
  final int? localPackId;
  final String remoteItemId;
  final String remotePackId;
}

enum SharedPackItemStateUiStatus { projected, missingMapping }

String normalizeSharedPackInviteCode(String value) {
  return value.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
}

String groupSharedPackInviteCode(String value) {
  final normalized = normalizeSharedPackInviteCode(value);
  if (normalized.length <= 3) {
    return normalized;
  }
  return '${normalized.substring(0, 3)} ${normalized.substring(3)}';
}
