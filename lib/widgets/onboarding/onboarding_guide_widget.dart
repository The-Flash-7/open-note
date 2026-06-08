// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../models/ai_provider_config.dart';
import '../../theme/design_tokens.dart';
import 'onboarding_page_welcome.dart';
import 'onboarding_page_feature.dart';
import 'onboarding_page_provider.dart';
import 'onboarding_page_config.dart';
import 'onboarding_page_complete.dart';

class OnboardingGuideWidget extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingGuideWidget({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<OnboardingGuideWidget> createState() => _OnboardingGuideWidgetState();
}

class _OnboardingGuideWidgetState extends State<OnboardingGuideWidget> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  AIProviderTemplate? _selectedTemplate;

  void _nextPage() {
    if (_currentPage < 8) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _selectProvider(AIProviderTemplate template) {
    setState(() => _selectedTemplate = template);
    _nextPage();
  }

  void _completeConfig() {
    _nextPage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? DesignTokens.darkBackground : Colors.white,
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: 52 + topPadding,
              bottom: 80 + bottomPadding,
            ),
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              children: [
                OnboardingPageWelcome(onNext: _nextPage, onSkip: widget.onSkip),
                OnboardingPageFeature(
                  imagePath: 'assets/images/welcome/url_extraction.png',
                  onNext: _nextPage,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageFeature(
                  imagePath: 'assets/images/welcome/ai_summary.png',
                  onNext: _nextPage,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageFeature(
                  imagePath: 'assets/images/welcome/ai_suggestions.png',
                  onNext: _nextPage,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageFeature(
                  imagePath: 'assets/images/welcome/ai_assistant.png',
                  onNext: _nextPage,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageFeature(
                  imagePath: 'assets/images/welcome/ai_providers.png',
                  onNext: _nextPage,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageProvider(
                  onSelectProvider: _selectProvider,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageConfig(
                  template: _selectedTemplate,
                  onComplete: _completeConfig,
                  onSkip: widget.onSkip,
                ),
                OnboardingPageComplete(
                  onComplete: widget.onComplete,
                  onReturnToConfig: () {
                    _pageController.jumpToPage(7);
                  },
                ),
              ],
            ),
          ),
          Positioned(
            top: 16 + topPadding,
            right: 16,
            child: TextButton(
              onPressed: widget.onSkip,
              child: Text(
                t.onboarding_skip,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32 + bottomPadding,
            left: 0,
            right: 0,
            child: _buildBottomBar(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          if (_currentPage > 0 && _currentPage < 8)
            TextButton(
              onPressed: _previousPage,
              child: Text(
                t.onboarding_previous,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
              ),
            )
          else
            SizedBox(width: 80),
          Spacer(),
          _buildProgressIndicator(isDark),
          Spacer(),
          if (_currentPage == 0)
            SizedBox(width: 80)
          else if (_currentPage >= 1 && _currentPage <= 5)
            TextButton(
              onPressed: _nextPage,
              child: Text(
                t.onboarding_next,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: DesignTokens.primary500,
                ),
              ),
            )
          else if (_currentPage == 8)
            SizedBox(width: 80)
          else
            SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(9, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage
                ? DesignTokens.primary500
                : (isDark ? DesignTokens.darkBorder : DesignTokens.gray300),
          ),
        );
      }),
    );
  }
}
