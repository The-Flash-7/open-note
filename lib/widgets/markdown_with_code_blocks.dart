// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
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
import 'package:highlight/languages/markdown.dart' as md_lang;
import 'package:highlight/languages/plaintext.dart' as plaintext;
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../theme/design_tokens.dart';

class MarkdownWithCodeBlocks extends StatelessWidget {
  final String data;
  final bool selectable;
  final bool isDarkMode;

  const MarkdownWithCodeBlocks({
    super.key,
    required this.data,
    this.selectable = true,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final segments = _parseMarkdown(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        if (segment.isCodeBlock) {
          return SelectionContainer.disabled(
            child: _ReadOnlyCodeBlock(
              code: segment.content,
              language: segment.language,
              isDarkMode: isDarkMode,
            ),
          );
        } else {
          return MarkdownBody(
            data: segment.content,
            styleSheet: _buildStyleSheet(context),
            extensionSet: md.ExtensionSet.gitHubWeb,
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.parse(href);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }
            },
          );
        }
      }).toList(),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final baseTextStyle = TextStyle(
      fontSize: 15,
      height: 1.6,
      color: isDarkMode ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
    );

    return MarkdownStyleSheet(
      p: baseTextStyle,
      h1: baseTextStyle.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ),
      h2: baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        height: 1.35,
      ),
      h3: baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 1.4,
      ),
      h4: baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        height: 1.45,
      ),
      h5: baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      h6: baseTextStyle.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
      strong: baseTextStyle.copyWith(fontWeight: FontWeight.bold),
      em: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
      code: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        backgroundColor: isDarkMode
            ? const Color(0xFF282C34)
            : const Color(0xFFF6F8FA),
        color: isDarkMode ? const Color(0xFF98C379) : const Color(0xFFD73A49),
      ),
      codeblockPadding: const EdgeInsets.all(0),
      blockquote: baseTextStyle.copyWith(
        color: isDarkMode ? const Color(0xFF5C6370) : const Color(0xFF6A737D),
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C313A) : const Color(0xFFF6F8FA),
      ),
      blockquotePadding: const EdgeInsets.all(16),
      listBullet: baseTextStyle,
      tableHead: baseTextStyle.copyWith(fontWeight: FontWeight.bold),
      tableBody: baseTextStyle,
      tableBorder: TableBorder.all(
        color: isDarkMode ? DesignTokens.darkBorder : DesignTokens.gray200,
        width: 1,
      ),
    );
  }

  List<_Segment> _parseMarkdown(String markdown) {
    final regex = RegExp(r'```(\w*)\s*\n([\s\S]*?)\n?```', multiLine: true);

    final segments = <_Segment>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(markdown)) {
      if (match.start > lastEnd) {
        final textBefore = markdown.substring(lastEnd, match.start);
        if (textBefore.trim().isNotEmpty) {
          segments.add(_Segment(content: textBefore, isCodeBlock: false));
        }
      }

      final language = match.group(1) ?? '';
      final code = match.group(2) ?? '';
      segments.add(
        _Segment(
          content: code.trimRight(),
          language: language,
          isCodeBlock: true,
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < markdown.length) {
      final textAfter = markdown.substring(lastEnd);
      if (textAfter.trim().isNotEmpty) {
        segments.add(_Segment(content: textAfter, isCodeBlock: false));
      }
    }

    return segments.isEmpty
        ? [_Segment(content: markdown, isCodeBlock: false)]
        : segments;
  }
}

class _Segment {
  final String content;
  final String language;
  final bool isCodeBlock;

  _Segment({
    required this.content,
    this.language = '',
    required this.isCodeBlock,
  });
}

class _ReadOnlyCodeBlock extends StatelessWidget {
  final String code;
  final String language;
  final bool isDarkMode;

  const _ReadOnlyCodeBlock({
    required this.code,
    required this.language,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? atomOneDarkTheme : githubTheme;
    final bgColor = isDarkMode
        ? const Color(0xFF282C34)
        : const Color(0xFFF6F8FA);
    final borderColor = isDarkMode
        ? const Color(0xFF3E4451)
        : const Color(0xFFE1E4E8);
    final headerBgColor = isDarkMode
        ? const Color(0xFF21252B)
        : const Color(0xFFEFF1F3);
    final textColor = isDarkMode
        ? const Color(0xFFABB2BF)
        : const Color(0xFF6E7781);
    final lineNumberColor = isDarkMode
        ? const Color(0xFF4B5363)
        : const Color(0xFFBCC2CC);

    final lines = code.split('\n');
    final lineCount = lines.length;
    final displayLanguage = _getDisplayLanguage(language);
    final langMode = _getLanguageMode(language);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5F56),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBD2E),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF27C93F),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    displayLanguage,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$lineCount 行',
                  style: TextStyle(fontSize: 12, color: textColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(0),
            child: CodeTheme(
              data: CodeThemeData(styles: theme),
              child: CodeField(
                controller: CodeController(text: code, language: langMode),
                readOnly: true,
                gutterStyle: GutterStyle(
                  showLineNumbers: lineCount > 1,
                  showErrors: false,
                  showFoldingHandles: false,
                  textStyle: TextStyle(
                    color: lineNumberColor,
                    fontFamily: 'JetBrainsMono',
                    fontSize: 14,
                  ),
                  width: 60,
                ),
                textStyle: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayLanguage(String lang) {
    if (lang.isEmpty) return 'plaintext';

    final map = {
      'javascript': 'JavaScript',
      'js': 'JavaScript',
      'typescript': 'TypeScript',
      'ts': 'TypeScript',
      'python': 'Python',
      'py': 'Python',
      'java': 'Java',
      'go': 'Go',
      'rust': 'Rust',
      'cpp': 'C++',
      'c': 'C',
      'csharp': 'C#',
      'cs': 'C#',
      'php': 'PHP',
      'ruby': 'Ruby',
      'swift': 'Swift',
      'kotlin': 'Kotlin',
      'dart': 'Dart',
      'sql': 'SQL',
      'html': 'HTML',
      'css': 'CSS',
      'bash': 'Shell',
      'sh': 'Shell',
      'shell': 'Shell',
      'json': 'JSON',
      'yaml': 'YAML',
      'yml': 'YAML',
      'markdown': 'Markdown',
      'md': 'Markdown',
      'plaintext': 'plaintext',
    };

    return map[lang.toLowerCase()] ?? lang;
  }

  dynamic _getLanguageMode(String lang) {
    if (lang.isEmpty) return plaintext.plaintext;

    final langMap = {
      'javascript': js.javascript,
      'js': js.javascript,
      'typescript': js.javascript,
      'ts': js.javascript,
      'python': py.python,
      'py': py.python,
      'java': java.java,
      'go': go.go,
      'rust': rust.rust,
      'cpp': cpp.cpp,
      'c': cpp.cpp,
      'csharp': cpp.cpp,
      'cs': cpp.cpp,
      'php': plaintext.plaintext,
      'ruby': plaintext.plaintext,
      'swift': plaintext.plaintext,
      'kotlin': plaintext.plaintext,
      'dart': dart.dart,
      'sql': sql.sql,
      'html': plaintext.plaintext,
      'css': css.css,
      'bash': bash.bash,
      'shell': bash.bash,
      'sh': bash.bash,
      'json': json.json,
      'yaml': yaml.yaml,
      'yml': yaml.yaml,
      'markdown': md_lang.markdown,
      'md': md_lang.markdown,
      'plaintext': plaintext.plaintext,
    };

    return langMap[lang.toLowerCase()] ?? plaintext.plaintext;
  }
}
