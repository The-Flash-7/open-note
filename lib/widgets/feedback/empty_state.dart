// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
    this.iconSize = DesignTokens.iconSizeXL,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize + DesignTokens.space8,
              height: iconSize + DesignTokens.space8,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.darkPrimary700.withValues(alpha: 0.2)
                    : DesignTokens.primary50,
                borderRadius: BorderRadius.circular(
                  (iconSize + DesignTokens.space8) / 2,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: isDark
                      ? DesignTokens.darkPrimary500.withValues(alpha: 0.5)
                      : DesignTokens.primary200,
                ),
              ),
            ),
            SizedBox(height: DesignTokens.space6),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: DesignTokens.space3),
              Text(
                description!,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              SizedBox(height: DesignTokens.space8),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary500,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space6,
                  ),
                ),
                child: Text(
                  actionText!,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyNotesState extends StatelessWidget {
  final VoidCallback? onCreateNew;

  const EmptyNotesState({super.key, this.onCreateNew});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.note_add,
      title: t.empty_noNotesTitle,
      description: t.empty_noNotesDesc,
      actionText: t.empty_createNote,
      onAction: onCreateNew,
    );
  }
}

class EmptySearchState extends StatelessWidget {
  final VoidCallback? onClearSearch;

  const EmptySearchState({super.key, this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search,
      title: t.empty_noSearchResultsTitle,
      description: t.empty_noSearchResultsDesc,
      actionText: t.empty_clearSearch,
      onAction: onClearSearch,
    );
  }
}

class EmptyTagsState extends StatelessWidget {
  const EmptyTagsState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.label_outline,
      title: t.empty_noTagsTitle,
      description: t.empty_noTagsDesc,
    );
  }
}

class EmptyFavoritesState extends StatelessWidget {
  final VoidCallback? onBrowseNotes;

  const EmptyFavoritesState({super.key, this.onBrowseNotes});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.star_border,
      title: t.empty_noFavoritesTitle,
      description: t.empty_noFavoritesDesc,
      actionText: t.empty_browseNotes,
      onAction: onBrowseNotes,
    );
  }
}

class ErrorState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    this.icon = Icons.error_outline,
    required this.title,
    this.description,
    this.actionText = '重试',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.space16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: DesignTokens.iconSizeXL + DesignTokens.space8,
              height: DesignTokens.iconSizeXL + DesignTokens.space8,
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.error.withValues(alpha: 0.2)
                    : Color(0xFFfee2e2),
                borderRadius: BorderRadius.circular(
                  (DesignTokens.iconSizeXL + DesignTokens.space8) / 2,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: DesignTokens.iconSizeXL,
                  color: DesignTokens.error,
                ),
              ),
            ),
            SizedBox(height: DesignTokens.space6),
            Text(
              title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            if (description != null) ...[
              SizedBox(height: DesignTokens.space3),
              Text(
                description!,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: DesignTokens.space8),
              OutlinedButton(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.error,
                  side: BorderSide(color: DesignTokens.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space6,
                  ),
                ),
                child: Text(
                  actionText!,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return ErrorState(
      icon: Icons.cloud_off,
      title: t.empty_networkErrorTitle,
      description: t.empty_networkErrorDesc,
      onRetry: onRetry,
    );
  }
}

class AIServiceErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const AIServiceErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return ErrorState(
      icon: Icons.smart_toy_outlined,
      title: t.empty_aiServiceErrorTitle,
      description: t.empty_aiServiceErrorDesc,
      onRetry: onRetry,
    );
  }
}
