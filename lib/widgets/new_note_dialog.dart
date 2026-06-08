// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.g.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/snackbar_helper.dart';
import 'format_option_widget.dart';

class NewNoteDialog extends StatefulWidget {
  final Function(NoteFormat format)? onBlankNoteCreated;
  final Function()? onFileNoteCreated;

  const NewNoteDialog({
    super.key,
    this.onBlankNoteCreated,
    this.onFileNoteCreated,
  });

  @override
  State<NewNoteDialog> createState() => _NewNoteDialogState();
}

class _NewNoteDialogState extends State<NewNoteDialog> {
  NoteFormat _selectedFormat = NoteFormat.markdown;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      backgroundColor: isDarkMode ? DesignTokens.darkSurface : Colors.white,
      child: Container(
        width: 400,
        padding: EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.dialog_newNote,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDarkMode
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            SizedBox(height: DesignTokens.space6),

            _buildOptionCard(
              context,
              icon: Icons.edit_note,
              title: t.dialog_blankNote,
              subtitle: t.dialog_createBlankNote,
              onTap: () => _showFormatSelector(context),
              isDarkMode: isDarkMode,
            ),

            SizedBox(height: DesignTokens.space4),

            _buildOptionCard(
              context,
              icon: Icons.upload_file,
              title: t.dialog_importFromFile,
              subtitle: t.dialog_importFromFileSubtitle,
              onTap: () => _importFromFile(context),
              isDarkMode: isDarkMode,
            ),

            SizedBox(height: DesignTokens.space6),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? DesignTokens.darkPrimary700.withValues(alpha: 0.2)
                    : DesignTokens.primary50,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDarkMode
                    ? DesignTokens.darkPrimary500
                    : DesignTokens.primary500,
              ),
            ),
            SizedBox(width: DesignTokens.space4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeBody,
                      fontWeight: DesignTokens.fontWeightMedium,
                      color: isDarkMode
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  SizedBox(height: DesignTokens.space1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: isDarkMode
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
          ],
        ),
      ),
    );
  }

  void _showFormatSelector(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            ),
            backgroundColor: isDarkMode
                ? DesignTokens.darkSurface
                : Colors.white,
            child: Container(
              width: 350,
              padding: EdgeInsets.all(DesignTokens.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.dialog_selectNoteFormat,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH3,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: isDarkMode
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  SizedBox(height: DesignTokens.space6),

                  FormatOptionWidget(
                    format: NoteFormat.markdown,
                    icon: Icons.text_fields,
                    title: t.dialog_markdown,
                    description: t.dialog_markdownDescription,
                    isSelected: _selectedFormat == NoteFormat.markdown,
                    onTap: () =>
                        setState(() => _selectedFormat = NoteFormat.markdown),
                    isDarkMode: isDarkMode,
                  ),

                  SizedBox(height: DesignTokens.space3),

                  FormatOptionWidget(
                    format: NoteFormat.plainText,
                    icon: Icons.note,
                    title: t.dialog_plainText,
                    description: t.dialog_plainTextDescription,
                    isSelected: _selectedFormat == NoteFormat.plainText,
                    onTap: () =>
                        setState(() => _selectedFormat = NoteFormat.plainText),
                    isDarkMode: isDarkMode,
                  ),

                  SizedBox(height: DesignTokens.space3),

                  FormatOptionWidget(
                    format: NoteFormat.richText,
                    icon: Icons.text_fields,
                    title: t.dialog_richText,
                    description: t.dialog_richTextDescription,
                    isSelected: _selectedFormat == NoteFormat.richText,
                    onTap: () =>
                        setState(() => _selectedFormat = NoteFormat.richText),
                    isDarkMode: isDarkMode,
                  ),

                  SizedBox(height: DesignTokens.space3),

                  FormatOptionWidget(
                    format: NoteFormat.code,
                    icon: Icons.code,
                    title: t.dialog_code,
                    description: t.dialog_codeDescription,
                    isSelected: _selectedFormat == NoteFormat.code,
                    onTap: () =>
                        setState(() => _selectedFormat = NoteFormat.code),
                    isDarkMode: isDarkMode,
                    enabled: false,
                  ),

                  SizedBox(height: DesignTokens.space6),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context);
                          widget.onBlankNoteCreated?.call(_selectedFormat);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSM,
                            ),
                          ),
                        ),
                        child: Text(t.common_create),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _importFromFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'txt',
          'md',
          'markdown',
          'html',
          'htm',
          'py',
          'js',
          'ts',
          'java',
          'dart',
          'go',
          'rs',
          'c',
          'cpp',
          'h',
          'hpp',
          'cs',
          'swift',
          'rb',
          'php',
          'sql',
          'sh',
          'bash',
          'json',
          'yaml',
          'yml',
          'xml',
          'css',
          'scss',
          'sass',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        if (!context.mounted) return;
        final notesProvider = context.read<NotesProvider>();

        Navigator.pop(context);

        final noteId = await notesProvider.importNoteFromFile(file);

        if (noteId != null) {
          if (!context.mounted) return;
          SnackBarHelper.showWithDuration(
            context,
            t.dialog_noteImportSuccess,
            duration: const Duration(seconds: 2),
          );
          widget.onFileNoteCreated?.call();
        } else {
          if (!context.mounted) return;
          SnackBarHelper.showWithDuration(
            context,
            t.dialog_importFailedUnsupported,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      debugPrint('File import error: $e');
      if (!context.mounted) return;
      SnackBarHelper.showWithDuration(
        context,
        t.dialog_importFailed(error: e),
        duration: const Duration(seconds: 2),
      );
    }
  }
}
