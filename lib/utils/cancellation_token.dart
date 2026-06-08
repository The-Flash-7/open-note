// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';

class CancellationToken {
  bool _isCancelled = false;
  final List<VoidCallback> _onCancelCallbacks = [];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (!_isCancelled) {
      _isCancelled = true;
      for (final callback in List.from(_onCancelCallbacks)) {
        callback();
      }
    }
  }

  void onCancel(VoidCallback callback) {
    if (_isCancelled) {
      callback();
    } else {
      _onCancelCallbacks.add(callback);
    }
  }

  void reset() {
    _isCancelled = false;
    _onCancelCallbacks.clear();
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const OperationCancelledException('操作已被用户中断');
    }
  }
}

class OperationCancelledException implements Exception {
  final String message;
  const OperationCancelledException([this.message = '操作已被用户中断']);

  @override
  String toString() => message;
}
