// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';

class PlainTextEditorWidget extends StatefulWidget {
  final String content;
  final Function(String) onChanged;
  final bool isDarkMode;

  const PlainTextEditorWidget({
    super.key,
    required this.content,
    required this.onChanged,
    this.isDarkMode = false,
  });

  @override
  State<PlainTextEditorWidget> createState() => _PlainTextEditorWidgetState();
}

class _PlainTextEditorWidgetState extends State<PlainTextEditorWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
  }

  @override
  void didUpdateWidget(PlainTextEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content &&
        _controller.text != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      maxLines: null,
      minLines: 10,
      decoration: InputDecoration(
        hintText: t.editor_startWritingPlainText,
        hintStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          color: DesignTokens.gray400,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        fillColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      style: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontFamily: 'JetBrainsMono',
        color: widget.isDarkMode
            ? DesignTokens.darkTextPrimary
            : DesignTokens.gray700,
      ),
    );
  }
}
