// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';

class OnboardingPageWelcome extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingPageWelcome({
    super.key,
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
          const Spacer(flex: 2),
          Image.asset(
            'assets/images/app_icon@200h.png',
            width: 120,
            height: 120,
          ),
          SizedBox(height: DesignTokens.space16),
          Text(
            t.onboarding_welcomeTitle,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeDisplay,
              fontWeight: DesignTokens.fontWeightBold,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            t.onboarding_welcomeSubtitle,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightRegular,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
          const Spacer(flex: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                ),
                child: Text(t.onboarding_startConfig),
              ),
              SizedBox(width: DesignTokens.space4),
              TextButton(
                onPressed: onSkip,
                child: Text(
                  t.onboarding_configLater,
                  style: TextStyle(
                    color: isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space16),
        ],
      ),
    );
  }
}
