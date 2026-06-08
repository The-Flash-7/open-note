// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.g.dart';
import '../../providers/settings_provider.dart';
import '../../theme/design_tokens.dart';

class OnboardingPageComplete extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onReturnToConfig;

  const OnboardingPageComplete({
    super.key,
    required this.onComplete,
    required this.onReturnToConfig,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();
    final hasActiveProvider = settingsProvider.hasActiveProvider;

    return Padding(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          Spacer(flex: 2),
          if (hasActiveProvider)
            _buildSuccessContent(isDark)
          else
            _buildWarningContent(isDark),
          Spacer(flex: 2),
          if (hasActiveProvider)
            _buildCompleteButton()
          else
            _buildReturnButton(),
          SizedBox(height: DesignTokens.space16),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(bool isDark) {
    return Column(
      children: [
        Icon(Icons.check_circle, size: 64, color: DesignTokens.success),
        SizedBox(height: DesignTokens.space16),
        Text(
          t.onboarding_configSuccess,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeH1,
            fontWeight: DesignTokens.fontWeightBold,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          t.onboarding_configSuccessSubtitle,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
        SizedBox(height: DesignTokens.space24),
        _buildNextStepsCard(isDark),
      ],
    );
  }

  Widget _buildWarningContent(bool isDark) {
    return Column(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 64,
          color: DesignTokens.warning,
        ),
        SizedBox(height: DesignTokens.space16),
        Text(
          t.onboarding_configIncomplete,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeH1,
            fontWeight: DesignTokens.fontWeightBold,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(height: DesignTokens.space8),
        Text(
          t.onboarding_configIncompleteSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
        SizedBox(height: DesignTokens.space24),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(DesignTokens.space12),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.darkWarningBackground
                : DesignTokens.warningBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            border: Border.all(
              color: DesignTokens.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: DesignTokens.warning,
                  ),
                  SizedBox(width: DesignTokens.space8),
                  Text(
                    t.onboarding_infoTip,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: DesignTokens.warning,
                    ),
                  ),
                ],
              ),
              SizedBox(height: DesignTokens.space8),
              Text(
                t.onboarding_swipedToCompleteWarning,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard(bool isDark) {
    final steps = [
      t.onboarding_nextStep1,
      t.onboarding_nextStep2,
      t.onboarding_nextStep3,
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        border: Border.all(color: DesignTokens.warning.withValues(alpha: 0.3)),
        boxShadow: isDark ? [] : DesignTokens.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.onboarding_nextStepTitle,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          SizedBox(height: DesignTokens.space12),
          ...steps.map(
            (step) => Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                      top: DesignTokens.space4,
                      right: DesignTokens.space8,
                    ),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DesignTokens.primary500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeBody,
                        color: isDark
                            ? DesignTokens.darkTextSecondary
                            : DesignTokens.gray700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary500,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: DesignTokens.space8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
        ),
        child: Text(t.onboarding_startUsing),
      ),
    );
  }

  Widget _buildReturnButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onReturnToConfig,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary500,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: DesignTokens.space8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
        ),
        child: Text(t.onboarding_returnToConfig),
      ),
    );
  }
}
