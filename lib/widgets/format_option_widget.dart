// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../l10n/strings.g.dart';
import '../models/note.dart';
import '../theme/design_tokens.dart';

class FormatOptionWidget extends StatelessWidget {
  final NoteFormat format;
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDarkMode;
  final bool enabled;

  const FormatOptionWidget({
    super.key,
    required this.format,
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.isDarkMode,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final disabledColor = isDarkMode
        ? DesignTokens.gray500
        : DesignTokens.gray400;
    final disabledBorderColor = isDarkMode
        ? DesignTokens.darkBorder.withValues(alpha: 0.2)
        : DesignTokens.gray100;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.space3),
        decoration: BoxDecoration(
          color: isSelected && enabled
              ? (isDarkMode
                    ? DesignTokens.darkPrimary700.withValues(alpha: 0.2)
                    : DesignTokens.primary50)
              : Colors.transparent,
          border: Border.all(
            color: !enabled
                ? disabledBorderColor
                : (isSelected
                      ? (isDarkMode
                            ? DesignTokens.darkPrimary500
                            : DesignTokens.primary500)
                      : (isDarkMode
                            ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                            : DesignTokens.gray200)),
            width: isSelected && enabled ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: !enabled
                  ? disabledColor
                  : (isSelected
                        ? (isDarkMode
                              ? DesignTokens.darkPrimary500
                              : DesignTokens.primary500)
                        : (isDarkMode
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray500)),
            ),
            SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: isSelected && enabled
                          ? DesignTokens.fontWeightMedium
                          : DesignTokens.fontWeightRegular,
                      color: !enabled
                          ? disabledColor
                          : (isSelected
                                ? (isDarkMode
                                      ? DesignTokens.darkPrimary500
                                      : DesignTokens.primary500)
                                : (isDarkMode
                                      ? DesignTokens.darkTextPrimary
                                      : DesignTokens.gray900)),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: !enabled
                          ? disabledColor
                          : (isDarkMode
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.gray500),
                    ),
                  ),
                ],
              ),
            ),
            if (!enabled)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                      : DesignTokens.gray200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  t.format_unavailable,
                  style: TextStyle(fontSize: 10, color: disabledColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
