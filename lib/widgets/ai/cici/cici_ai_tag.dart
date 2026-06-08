// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../../l10n/strings.g.dart';
import 'cici_design_tokens.dart';

class CiciAITag extends StatelessWidget {
  const CiciAITag({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CiciDesignTokens.spaceMd,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: CiciDesignTokens.getColor(
          context,
          CiciDesignTokens.tagBg,
          CiciDesignTokens.darkTagBg,
        ),
        borderRadius: BorderRadius.circular(CiciDesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: CiciDesignTokens.primary),
          const SizedBox(width: CiciDesignTokens.spaceXs),
          Text(
            t.ai_ciciGreeting,
            style: TextStyle(
              fontSize: CiciDesignTokens.fontSizeCaption,
              fontWeight: CiciDesignTokens.fontWeightMedium,
              color: CiciDesignTokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}
