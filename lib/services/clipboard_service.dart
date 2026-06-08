// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  final RegExp _urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

  final RegExp _codePattern = RegExp(
    r'(function|class|import|def|if|for|while|return|const|let|var)\s+',
    caseSensitive: false,
  );

  String? _lastContent;

  Future<String?> getClipboardContent() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text?.trim();
    } catch (e) {
      return null;
    }
  }

  bool isUrl(String text) {
    if (text.isEmpty) return false;
    final match = _urlPattern.firstMatch(text);
    return match != null && match.group(0) == text.trim();
  }

  bool isCodeSnippet(String text) {
    if (text.isEmpty || text.length < 20) return false;
    return _codePattern.hasMatch(text);
  }

  bool isNewContent(String? content) {
    if (content == null || content.isEmpty) return false;
    return content != _lastContent;
  }

  void updateLastContent(String content) {
    _lastContent = content;
  }

  void clearLastContent() {
    _lastContent = null;
  }
}
