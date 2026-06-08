// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';
import '../common/tag_chip.dart';
import '../common/ai_floating_icon.dart';

class AISummaryPanel extends StatefulWidget {
  final String summary;
  final List<String> keywords;
  final bool isGenerating;
  final VoidCallback? onRegenerate;
  final VoidCallback? onGenerate;
  final VoidCallback? onTap;
  final bool initiallyExpanded;
  final VoidCallback? onNavigateToSettings;

  const AISummaryPanel({
    super.key,
    required this.summary,
    this.keywords = const [],
    this.isGenerating = false,
    this.onRegenerate,
    this.onGenerate,
    this.onTap,
    this.initiallyExpanded = false,
    this.onNavigateToSettings,
  });

  @override
  State<AISummaryPanel> createState() => _AISummaryPanelState();
}

class _AISummaryPanelState extends State<AISummaryPanel> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(AISummaryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGenerating && !oldWidget.isGenerating) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(DesignTokens.space6),
        decoration: BoxDecoration(
          gradient: isDark
              ? DesignTokens.gradientDarkAI
              : DesignTokens.gradientAI,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
          border: Border.all(
            color: isDark
                ? DesignTokens.darkPrimary700.withValues(alpha: 0.5)
                : DesignTokens.primary200,
            width: 1,
          ),
          boxShadow: isDark
              ? DesignTokens.shadowDarkPrimary
              : DesignTokens.shadowSM,
        ),
        child: AnimatedSize(
          duration: DesignTokens.durationNormal,
          curve: DesignTokens.curveStandard,
          alignment: Alignment.topCenter,
          child: RepaintBoundary(
            child: _isExpanded
                ? _buildExpandedContent(context, isDark)
                : _buildCollapsedHeader(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        AIFloatingIcon(size: 20, isAnimating: widget.isGenerating),
        SizedBox(width: DesignTokens.space3),
        Text(
          t.ai_summaryTitle,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(width: DesignTokens.space4),
        Expanded(
          child: Text(
            t.ai_clickToExpand,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSmall,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.expand_more),
          iconSize: 20,
          color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.gray500,
          onPressed: () => setState(() => _isExpanded = true),
          tooltip: t.common_expand,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AIFloatingIcon(size: 20, isAnimating: widget.isGenerating),
            SizedBox(width: DesignTokens.space3),
            Text(
              t.ai_summaryTitle,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            Spacer(),
            if (widget.summary.isEmpty &&
                widget.onGenerate != null &&
                !widget.isGenerating)
              TextButton(
                onPressed: widget.onGenerate,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space4,
                    vertical: DesignTokens.space2,
                  ),
                  minimumSize: Size(60, 28),
                  foregroundColor: isDark
                      ? DesignTokens.darkPrimary500
                      : DesignTokens.primary500,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14),
                    SizedBox(width: DesignTokens.space1),
                    Text(
                      t.ai_generateSummary,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSmall,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.summary.isNotEmpty &&
                widget.onRegenerate != null &&
                !widget.isGenerating)
              TextButton(
                onPressed: widget.onRegenerate,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space4,
                    vertical: DesignTokens.space2,
                  ),
                  minimumSize: Size(60, 28),
                  foregroundColor: isDark
                      ? DesignTokens.darkPrimary500
                      : DesignTokens.primary500,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 14),
                    SizedBox(width: DesignTokens.space1),
                    Text(
                      t.ai_regenerate,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSmall,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: Icon(Icons.expand_less),
              iconSize: 20,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
              onPressed: () => setState(() => _isExpanded = false),
              tooltip: t.common_collapse,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.space4),
        if (widget.isGenerating)
          _buildGeneratingIndicator(context, isDark)
        else if (widget.summary.isNotEmpty)
          _buildContent(context, isDark)
        else if (widget.onGenerate != null)
          SizedBox.shrink()
        else
          _buildEmptyState(context, isDark),
        if (widget.keywords.isNotEmpty && !widget.isGenerating) ...[
          SizedBox(height: DesignTokens.space4),
          _buildKeywords(context, isDark),
        ],
      ],
    );
  }

  Widget _buildGeneratingIndicator(BuildContext context, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? DesignTokens.darkPrimary500 : DesignTokens.primary500,
            ),
          ),
        ),
        SizedBox(width: DesignTokens.space3),
        Text(
          t.ai_generatingSummary,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Text(
      widget.summary,
      style: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray700,
        height: 22 / DesignTokens.fontSizeBody,
      ),
    );
  }

  Widget _buildKeywords(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.ai_keywordsLabel,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeSmall,
            fontWeight: DesignTokens.fontWeightMedium,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
        SizedBox(width: DesignTokens.space2),
        Expanded(
          child: TagChipList(
            tags: widget.keywords,
            spacing: DesignTokens.space2,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
            SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Text(
                t.ai_noAiConfig,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: DesignTokens.space4),
        if (widget.onNavigateToSettings != null)
          TextButton(
            onPressed: widget.onNavigateToSettings,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: DesignTokens.space4,
                vertical: DesignTokens.space2,
              ),
              minimumSize: Size(80, 28),
              foregroundColor: isDark
                  ? DesignTokens.darkPrimary500
                  : DesignTokens.primary500,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, size: 14),
                SizedBox(width: DesignTokens.space1),
                Text(
                  t.ai_goToSettings,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeSmall,
                    fontWeight: DesignTokens.fontWeightMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AISummaryCompact extends StatelessWidget {
  final String summary;
  final bool isGenerating;
  final VoidCallback? onTap;

  const AISummaryCompact({
    super.key,
    required this.summary,
    this.isGenerating = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space6,
          vertical: DesignTokens.space3,
        ),
        decoration: BoxDecoration(
          gradient: isDark
              ? DesignTokens.gradientDarkAI
              : DesignTokens.gradientAI,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        child: Row(
          children: [
            AIFloatingIcon(size: 16, isAnimating: isGenerating),
            SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Text(
                isGenerating
                    ? t.ai_generating
                    : (summary.isNotEmpty ? summary : t.ai_clickToGenerate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSmall,
                  color: isDark
                      ? DesignTokens.darkTextPrimary
                      : DesignTokens.gray700,
                ),
              ),
            ),
            if (!isGenerating)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
          ],
        ),
      ),
    );
  }
}
