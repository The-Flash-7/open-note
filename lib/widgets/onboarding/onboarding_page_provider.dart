// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';
import '../../utils/ai_provider_templates.dart';
import '../../models/ai_provider_config.dart';

class OnboardingPageProvider extends StatelessWidget {
  final void Function(AIProviderTemplate template) onSelectProvider;
  final VoidCallback onSkip;

  const OnboardingPageProvider({
    super.key,
    required this.onSelectProvider,
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
          SizedBox(height: DesignTokens.space24),
          Text(
            t.onboarding_selectProviderTitle,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeH1,
              fontWeight: DesignTokens.fontWeightBold,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          SizedBox(height: DesignTokens.space8),
          Text(
            t.onboarding_selectProviderSubtitle,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: DesignTokens.space24),
          Expanded(child: _buildProviderGrid(isDark)),
        ],
      ),
    );
  }

  Widget _buildProviderGrid(bool isDark) {
    final templates = AIProviderTemplates.templates;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: DesignTokens.space8,
        mainAxisSpacing: DesignTokens.space8,
        childAspectRatio: 1.2,
      ),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        return _buildProviderCard(templates[index], isDark);
      },
    );
  }

  Widget _buildProviderCard(AIProviderTemplate template, bool isDark) {
    return _ProviderCard(
      template: template,
      onTap: () => onSelectProvider(template),
      isDark: isDark,
    );
  }
}

class _ProviderCard extends StatefulWidget {
  final AIProviderTemplate template;
  final VoidCallback onTap;
  final bool isDark;

  const _ProviderCard({
    required this.template,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _isHovered = false;

  String _getProviderIconPath(String name) {
    switch (name) {
      case 'OpenAI':
        return 'assets/images/providers/openai_logo.png';
      case '阿里云百炼Token Plan':
        return 'assets/images/providers/alibaba_bailian_logo.png';
      case '阿里云百炼Coding Plan':
        return 'assets/images/providers/alibaba_bailian_logo.png';
      case '腾讯混元':
        return 'assets/images/providers/tencent_hunyuan_logo.png';
      case '火山方舟Coding Plan':
        return 'assets/images/providers/volcengine_fangzhou_logo.png';
      case '火山豆包':
        return 'assets/images/providers/volcengine_doubao_logo.png';
      case '智谱GLM Coding Plan':
        return 'assets/images/providers/zhipu_glm_logo.png';
      case '智谱GLM':
        return 'assets/images/providers/zhipu_glm_logo.png';
      case '百度千帆':
        return 'assets/images/providers/baidu_qianfan_logo.png';
      case 'Moonshot':
        return 'assets/images/providers/moonshot_logo.png';
      case 'DeepSeek':
        return 'assets/images/providers/deepseek_logo.png';
      case 'Claude':
        return 'assets/images/providers/anthropic_logo.png';
      case 'Ollama本地':
        return 'assets/images/providers/ollama_logo.png';
      case '自定义':
        return 'assets/images/providers/custom_logo.png';
      default:
        return 'assets/images/providers/custom_logo.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.all(DesignTokens.space8),
          decoration: BoxDecoration(
            color: _isHovered
                ? (widget.isDark
                      ? DesignTokens.darkSurface.withValues(alpha: 0.8)
                      : DesignTokens.primary50)
                : (widget.isDark ? DesignTokens.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            border: Border.all(
              color: _isHovered
                  ? DesignTokens.primary500
                  : (widget.isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.gray200),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: DesignTokens.primary500.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : (widget.isDark ? [] : DesignTokens.shadowSM),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? (widget.isDark
                            ? DesignTokens.darkSurface.withValues(alpha: 0.8)
                            : DesignTokens.primary50)
                      : (widget.isDark
                            ? DesignTokens.darkSurface
                            : Colors.white),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
                child: Image.asset(
                  _getProviderIconPath(widget.template.name),
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.settings,
                      size: 32,
                      color: _isHovered
                          ? DesignTokens.primary700
                          : (widget.isDark
                                ? DesignTokens.darkPrimary500
                                : DesignTokens.primary500),
                    );
                  },
                ),
              ),
              SizedBox(height: DesignTokens.space6),
              Text(
                widget.template.displayName,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSmall,
                  fontWeight: DesignTokens.fontWeightMedium,
                  color: _isHovered
                      ? DesignTokens.primary700
                      : (widget.isDark
                            ? DesignTokens.darkTextPrimary
                            : DesignTokens.gray900),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
