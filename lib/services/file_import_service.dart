// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:http/http.dart' as http;
import '../models/note.dart';

class ImportResult {
  final String title;
  final String content;
  final NoteFormat format;
  final String? language;

  ImportResult({
    required this.title,
    required this.content,
    required this.format,
    this.language,
  });
}

class FileImportService {
  static const String _pythonServiceUrl = 'http://127.0.0.1:8765';
  
  static const Map<String, String> _languageMap = {
    '.py': 'python',
    '.js': 'javascript',
    '.ts': 'typescript',
    '.jsx': 'javascript',
    '.tsx': 'typescript',
    '.java': 'java',
    '.kt': 'kotlin',
    '.kts': 'kotlin',
    '.go': 'go',
    '.rs': 'rust',
    '.c': 'c',
    '.cpp': 'cpp',
    '.cc': 'cpp',
    '.cxx': 'cpp',
    '.h': 'c',
    '.hpp': 'cpp',
    '.hxx': 'cpp',
    '.cs': 'csharp',
    '.swift': 'swift',
    '.rb': 'ruby',
    '.php': 'php',
    '.sql': 'sql',
    '.sh': 'bash',
    '.bash': 'bash',
    '.zsh': 'bash',
    '.json': 'json',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.xml': 'xml',
    '.html': 'html',
    '.htm': 'html',
    '.css': 'css',
    '.scss': 'scss',
    '.sass': 'sass',
    '.less': 'less',
    '.md': 'markdown',
    '.markdown': 'markdown',
    '.dart': 'dart',
    '.lua': 'lua',
    '.pl': 'perl',
    '.pm': 'perl',
    '.r': 'r',
    '.m': 'matlab',
    '.scala': 'scala',
    '.clj': 'clojure',
    '.ex': 'elixir',
    '.exs': 'elixir',
    '.erl': 'erlang',
    '.hrl': 'erlang',
    '.vim': 'vim',
    '.toml': 'toml',
    '.ini': 'ini',
    '.conf': 'conf',
    '.cfg': 'conf',
    '.gradle': 'gradle',
    '.groovy': 'groovy',
    '.asp': 'asp',
    '.aspx': 'asp',
    '.vue': 'vue',
    '.svelte': 'svelte',
  };

  Future<ImportResult?> importFromFile(File file) async {
    final filePath = file.path;
    final extension = _getFileExtension(filePath);

    if (extension.isEmpty) {
      return null;
    }

    final format = detectFormat(filePath);
    final title = _extractTitle(filePath);

    if (format == NoteFormat.plainText && 
        (extension.toLowerCase() == '.pdf' || 
         extension.toLowerCase() == '.docx' || 
         extension.toLowerCase() == '.pptx')) {
      return await _parseWithPythonService(file, title);
    }

    switch (format) {
      case NoteFormat.plainText:
        return await _importTxt(file, title);

      case NoteFormat.code:
        return await _importCodeFile(file, title, extension);

      case NoteFormat.richText:
        return await _importHtml(file, title);

      case NoteFormat.markdown:
        return await _importMarkdown(file, title);
    }
  }

  NoteFormat detectFormat(String filePath) {
    final extension = _getFileExtension(filePath).toLowerCase();

    if (extension == '.txt') {
      return NoteFormat.plainText;
    }

    if (extension == '.pdf' || extension == '.docx' || extension == '.pptx') {
      return NoteFormat.plainText;
    }

    if (extension == '.md' || extension == '.markdown') {
      return NoteFormat.markdown;
    }

    if (extension == '.html' || extension == '.htm') {
      return NoteFormat.richText;
    }

    if (_languageMap.containsKey(extension)) {
      return NoteFormat.plainText;
    }

    return NoteFormat.plainText;
  }

  String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot == -1 || lastDot == filePath.length - 1) {
      return '';
    }
    return filePath.substring(lastDot);
  }

  String _extractTitle(String filePath) {
    final lastSlash = filePath.lastIndexOf(Platform.pathSeparator);
    if (lastSlash == -1) {
      return filePath;
    }

    final fileName = filePath.substring(lastSlash + 1);
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1) {
      return fileName;
    }

    return fileName.substring(0, lastDot);
  }

  Future<ImportResult> _importTxt(File file, String title) async {
    final content = await file.readAsString();
    return ImportResult(
      title: title,
      content: content,
      format: NoteFormat.plainText,
    );
  }

  Future<ImportResult> _importCodeFile(
    File file,
    String title,
    String extension,
  ) async {
    final content = await file.readAsString();
    final language = _languageMap[extension.toLowerCase()] ?? 'plaintext';

    return ImportResult(
      title: title,
      content: content,
      format: NoteFormat.code,
      language: language,
    );
  }

  Future<ImportResult> _importHtml(File file, String title) async {
    final htmlContent = await file.readAsString();

    try {
      final document = html_parser.parse(htmlContent);
      final textContent = _extractTextFromHtml(document.body);

      return ImportResult(
        title: title,
        content: textContent,
        format: NoteFormat.plainText,
      );
    } catch (e) {
      debugPrint('HTML parsing failed: $e');
      return ImportResult(
        title: title,
        content: htmlContent,
        format: NoteFormat.plainText,
      );
    }
  }

  String _extractTextFromHtml(html_dom.Element? element) {
    if (element == null) return '';

    final buffer = StringBuffer();
    for (final node in element.nodes) {
      if (node is html_dom.Text) {
        buffer.write(node.text);
      } else if (node is html_dom.Element) {
        final tagName = node.localName?.toLowerCase();

        if (tagName == 'h1' ||
            tagName == 'h2' ||
            tagName == 'h3' ||
            tagName == 'h4' ||
            tagName == 'h5' ||
            tagName == 'h6') {
          buffer.write('\n${_extractTextFromHtml(node)}\n');
        } else if (tagName == 'p' || tagName == 'div') {
          buffer.write('\n${_extractTextFromHtml(node)}\n');
        } else if (tagName == 'br') {
          buffer.write('\n');
        } else if (tagName == 'li') {
          buffer.write('  ${_extractTextFromHtml(node)}\n');
        } else if (tagName == 'ul' || tagName == 'ol') {
          buffer.write('\n${_extractTextFromHtml(node)}');
        } else if (tagName == 'script' ||
            tagName == 'style' ||
            tagName == 'noscript') {
          continue;
        } else {
          buffer.write(_extractTextFromHtml(node));
        }
      }
    }

    return buffer.toString().trim();
  }

  Future<ImportResult> _importMarkdown(File file, String title) async {
    final content = await file.readAsString();
    return ImportResult(
      title: title,
      content: content,
      format: NoteFormat.markdown,
    );
  }

  Future<ImportResult?> _parseWithPythonService(File file, String title) async {
    try {
      final response = await http.post(
        Uri.parse('$_pythonServiceUrl/api/document/parse'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_path': file.path}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['text'] != null) {
          final text = data['text'] as String;
          
          if (text.isEmpty) {
            debugPrint('Document parsing returned empty text: ${file.path}');
            return null;
          }
          
          return ImportResult(
            title: title,
            content: text,
            format: NoteFormat.plainText,
          );
        } else {
          debugPrint('Document parsing failed: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('Python service returned ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to call Python service for document parsing: $e');
      return null;
    }
  }
}
