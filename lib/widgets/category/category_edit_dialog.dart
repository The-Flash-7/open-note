// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../models/category.dart';
import '../../theme/design_tokens.dart';

class CategoryEditDialog extends StatefulWidget {
  final Category category;
  final Function(String) onSave;

  const CategoryEditDialog({
    super.key,
    required this.category,
    required this.onSave,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.category.name;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? DesignTokens.darkSurface : Colors.white,
      title: Text(
        t.category_renameTitle,
        style: TextStyle(
          color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            onSubmitted: (_) => _handleSave(),
            decoration: InputDecoration(
              hintText: t.category_newNameHint,
              hintStyle: TextStyle(
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
              errorText: _error,
              counterText: '${_controller.text.length}/20',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: BorderSide(
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.gray300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                borderSide: const BorderSide(color: DesignTokens.primary500),
              ),
            ),
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.common_cancel,
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primary500,
            foregroundColor: Colors.white,
          ),
          child: Text(t.common_save),
        ),
      ],
    );
  }

  void _handleSave() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() => _error = t.category_nameEmptyError);
      return;
    }

    if (name.length > 20) {
      setState(() => _error = t.category_nameTooLongError);
      return;
    }

    if (name.contains('-')) {
      setState(() => _error = t.category_nameDashError);
      return;
    }

    widget.onSave(name);
  }
}
