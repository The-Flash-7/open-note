// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';

class OnboardingPageFeature extends StatelessWidget {
  final String imagePath;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingPageFeature({
    super.key,
    required this.imagePath,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          Spacer(flex: 1),
          Expanded(
            flex: 8,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? DesignTokens.darkSurface
                        : DesignTokens.gray100,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: isDark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray400,
                        ),
                        SizedBox(height: DesignTokens.space8),
                        Text(
                          t.onboarding_imageLoadError,
                          style: TextStyle(
                            color: isDark
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Spacer(flex: 1),
        ],
      ),
    );
  }
}
