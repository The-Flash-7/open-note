// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';

class SnackBarHelper {
  static const double _maxWidth = 400.0;
  static const double _minWidth = 100.0;
  static const double _padding = 32.0;

  static double _calculateWidth(BuildContext context, String message) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final contentWidth = textPainter.width + _padding;
    textPainter.dispose();

    return contentWidth.clamp(_minWidth, _maxWidth);
  }

  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        behavior: SnackBarBehavior.floating,
        width: _calculateWidth(context, message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showWithDuration(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Center(child: Text(message)),
        behavior: SnackBarBehavior.floating,
        width: _calculateWidth(context, message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
      ),
    );
  }
}
