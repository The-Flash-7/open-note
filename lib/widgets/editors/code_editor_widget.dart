// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/highlight.dart';
import 'package:highlight/languages/javascript.dart' as js;
import 'package:highlight/languages/python.dart' as py;
import 'package:highlight/languages/java.dart' as java;
import 'package:highlight/languages/dart.dart' as dart;
import 'package:highlight/languages/go.dart' as go;
import 'package:highlight/languages/rust.dart' as rust;
import 'package:highlight/languages/cpp.dart' as cpp;
import 'package:highlight/languages/sql.dart' as sql;
import 'package:highlight/languages/json.dart' as json;
import 'package:highlight/languages/bash.dart' as bash;
import 'package:highlight/languages/yaml.dart' as yaml;
import 'package:highlight/languages/css.dart' as css;
import 'package:highlight/languages/markdown.dart' as md;
import 'package:highlight/languages/plaintext.dart' as plaintext;
import '../../theme/design_tokens.dart';

class CodeEditorWidget extends StatefulWidget {
  final String content;
  final String language;
  final Function(String) onChanged;
  final bool isDarkMode;

  const CodeEditorWidget({
    super.key,
    required this.content,
    required this.language,
    required this.onChanged,
    this.isDarkMode = false,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  late CodeController _controller;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    final languageMode = _getLanguageMode(widget.language);
    _controller = CodeController(text: widget.content, language: languageMode);
  }

  Mode _getLanguageMode(String language) {
    switch (language.toLowerCase()) {
      case 'javascript':
      case 'typescript':
      case 'jsx':
      case 'tsx':
        return js.javascript;
      case 'python':
        return py.python;
      case 'java':
        return java.java;
      case 'dart':
        return dart.dart;
      case 'go':
        return go.go;
      case 'rust':
        return rust.rust;
      case 'c':
      case 'cpp':
      case 'csharp':
        return cpp.cpp;
      case 'sql':
        return sql.sql;
      case 'json':
        return json.json;
      case 'bash':
      case 'shell':
        return bash.bash;
      case 'yaml':
        return yaml.yaml;
      case 'css':
        return css.css;
      case 'markdown':
      case 'md':
        return md.markdown;
      default:
        return plaintext.plaintext;
    }
  }

  @override
  void didUpdateWidget(CodeEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content &&
        _controller.text != widget.content) {
      _controller.text = widget.content;
    }
    if (oldWidget.language != widget.language) {
      final languageMode = _getLanguageMode(widget.language);
      _controller.language = languageMode;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CodeField(
      controller: _controller,
      onChanged: widget.onChanged,
      textStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontFamily: 'JetBrainsMono',
        color: widget.isDarkMode
            ? DesignTokens.darkTextPrimary
            : DesignTokens.gray700,
      ),
      gutterStyle: const GutterStyle(
        margin: 8,
        textStyle: TextStyle(fontSize: 12, color: DesignTokens.gray400),
      ),
      minLines: 10,
      maxLines: null,
      background: widget.isDarkMode
          ? DesignTokens.darkSurface
          : DesignTokens.gray50,
    );
  }
}
