// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'cici_design_tokens.dart';

class CiciSystemMessage extends StatelessWidget {
  final String message;

  const CiciSystemMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? CiciDesignTokens.darkGray
        : CiciDesignTokens.gray;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: textColor, height: 1.4),
        ),
      ),
    );
  }
}
