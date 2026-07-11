// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';

import '../l10n/strings.g.dart';
import '../models/note.dart';
import '../services/export_service.dart';
import '../theme/design_tokens.dart';

class ExportDialog extends StatefulWidget {
  final Note note;

  const ExportDialog({
    super.key,
    required this.note,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat? _selectedFormat;

  @override
  void initState() {
    super.initState();
    final supportedFormats = ExportService.getSupportedFormats(widget.note.format);
    if (supportedFormats.isNotEmpty) {
      _selectedFormat = supportedFormats.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final supportedFormats = ExportService.getSupportedFormats(widget.note.format);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      backgroundColor: isDarkMode ? DesignTokens.darkSurface : Colors.white,
      child: Container(
        width: 350,
        padding: EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.export_select_format,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDarkMode
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            SizedBox(height: DesignTokens.space6),

            ...supportedFormats.map((format) => _buildFormatOption(
                  context,
                  format: format,
                  isSelected: _selectedFormat == format,
                  onTap: () => setState(() => _selectedFormat = format),
                  isDarkMode: isDarkMode,
                )),

            SizedBox(height: DesignTokens.space6),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    t.common_cancel,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      color: isDarkMode
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ),
                SizedBox(width: DesignTokens.space2),
                ElevatedButton(
                  onPressed: _selectedFormat != null
                      ? () => Navigator.pop(context, _selectedFormat)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primary500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                    ),
                  ),
                  child: Text(t.export_title),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context, {
    required ExportFormat format,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final t = Translations.of(context);
    String title;
    IconData icon;

    switch (format) {
      case ExportFormat.txt:
        title = t.export_format_txt;
        icon = Icons.note;
        break;
      case ExportFormat.md:
        title = t.export_format_md;
        icon = Icons.text_fields;
        break;
      case ExportFormat.pdf:
        title = t.export_format_pdf;
        icon = Icons.picture_as_pdf;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.space3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
        child: Container(
          padding: EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode
                    ? DesignTokens.primary500.withValues(alpha: 0.1)
                    : DesignTokens.primary50)
                : (isDarkMode
                    ? DesignTokens.darkBackground
                    : DesignTokens.gray50),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
            border: Border.all(
              color: isSelected
                  ? DesignTokens.primary500
                  : (isDarkMode
                      ? DesignTokens.darkBorder
                      : DesignTokens.gray200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? DesignTokens.primary500
                    : (isDarkMode
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500),
                size: 24,
              ),
              SizedBox(width: DesignTokens.space3),
              Text(
                title,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  fontWeight: isSelected
                      ? DesignTokens.fontWeightMedium
                      : DesignTokens.fontWeightRegular,
                  color: isSelected
                      ? DesignTokens.primary500
                      : (isDarkMode
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}