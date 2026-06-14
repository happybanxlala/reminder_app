import 'dart:io';

import 'package:flutter/services.dart';

import 'home_widget_pending_action.dart';

class HomeWidgetNativeBridge {
  const HomeWidgetNativeBridge({
    MethodChannel channel = const MethodChannel('reminder_app/home_widget'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<Directory?> appGroupContainerDirectory() async {
    if (!Platform.isIOS) {
      return null;
    }
    final path = await _channel.invokeMethod<String>('appGroupContainerPath');
    if (path == null || path.isEmpty) {
      return null;
    }
    return Directory(path);
  }

  Future<void> reloadHomeWidgets() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return;
    }
    await _channel.invokeMethod<void>('reloadHomeWidgets');
  }

  Future<HomeWidgetPendingAction?> readAndClearPendingAction() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return null;
    }
    final result = await _channel.invokeMapMethod<Object?, Object?>(
      'readAndClearPendingAction',
    );
    if (result == null) {
      return null;
    }
    return HomeWidgetPendingAction.fromJson(result);
  }

  void setPendingActionAvailableHandler(Future<void> Function()? handler) {
    if (handler == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'homeWidgetPendingActionAvailable') {
        await handler();
        return null;
      }
      throw MissingPluginException(
        'No implementation found for method ${call.method}',
      );
    });
  }
}
