// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/note.dart';
import '../utils/markdown_to_pdf.dart';

enum ExportFormat {
  txt,
  md,
  pdf,
}

class ExportService {
  static List<ExportFormat> getSupportedFormats(NoteFormat noteFormat) {
    switch (noteFormat) {
      case NoteFormat.plainText:
        return [ExportFormat.txt];
      case NoteFormat.markdown:
        return [ExportFormat.txt, ExportFormat.md, ExportFormat.pdf];
      case NoteFormat.richText:
        return [ExportFormat.txt, ExportFormat.md, ExportFormat.pdf];
      case NoteFormat.code:
        return [];
    }
  }

  static Future<bool> exportNote(
    Note note,
    ExportFormat format,
    String filePath,
  ) async {
    try {
      String content = note.content;

      if (note.format == NoteFormat.richText) {
        switch (format) {
          case ExportFormat.txt:
            content = _richTextToPlainText(content);
            break;
          case ExportFormat.md:
            content = _richTextToMarkdown(content);
            break;
          case ExportFormat.pdf:
            content = _richTextToMarkdown(content);
            break;
        }
      }

      switch (format) {
        case ExportFormat.txt:
          return await _exportAsTxt(content, filePath);
        case ExportFormat.md:
          return await _exportAsMarkdown(content, filePath);
        case ExportFormat.pdf:
          return await _exportAsPdf(content, filePath, note.title);
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      return false;
    }
  }

  static Future<bool> _exportAsTxt(String content, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('TXT export failed: $e');
      return false;
    }
  }

  static Future<bool> _exportAsMarkdown(String content, String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(content);
      return true;
    } catch (e) {
      debugPrint('Markdown export failed: $e');
      return false;
    }
  }

  static Future<bool> _exportAsPdf(
    String content,
    String filePath,
    String title,
  ) async {
    try {
      debugPrint('=== PDF Export Debug ===');
      debugPrint('Title: "$title"');
      debugPrint('Content preview: "${content.length > 100 ? content.substring(0, 100) : content}..."');
      debugPrint('Content length: ${content.length} chars');

      final pdf = pw.Document();

      ByteData fontData;
      pw.Font font;

      try {
        fontData = await rootBundle.load('assets/fonts/NotoSansSC-Regular.ttf');
        font = pw.Font.ttf(fontData);
        debugPrint('Successfully loaded Chinese font for PDF');
      } catch (e) {
        debugPrint('Failed to load Chinese font: $e');
        throw Exception('Failed to load Chinese font: $e');
      }

      ByteData? emojiFontData;
      pw.Font? emojiFont;

      try {
        emojiFontData = await rootBundle.load('assets/fonts/NotoEmoji-Regular.ttf');
        emojiFont = pw.Font.ttf(emojiFontData);
        debugPrint('Successfully loaded Emoji font for PDF');
      } catch (e) {
        debugPrint('Failed to load Emoji font: $e');
      }

      ByteData? codeFontData;
      pw.Font? codeFont;

      try {
        codeFontData = await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf');
        codeFont = pw.Font.ttf(codeFontData);
        debugPrint('Successfully loaded Code font for PDF');
      } catch (e) {
        debugPrint('Failed to load Code font: $e');
      }

      final converter = MarkdownToPdfConverter(
        font: font,
        emojiFont: emojiFont,
        codeFont: codeFont,
      );

      final markdownWidgets = converter.convert(content);

      debugPrint('Markdown widgets count: ${markdownWidgets.length}');

      final widgets = <pw.Widget>[
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
          child: pw.Text(
            title.isNotEmpty ? title : 'Note',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              font: font,
              fontFallback: emojiFont != null ? [emojiFont] : [],
            ),
          ),
        ),
        pw.SizedBox(height: 16),
      ];

      widgets.addAll(markdownWidgets);

      debugPrint('Total widgets count: ${widgets.length}');
      for (int i = 0; i < widgets.length && i < 15; i++) {
        debugPrint('  Widget[$i]: ${widgets[i].runtimeType}');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return widgets;
          },
        ),
      );

      final bytes = await pdf.save();
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      debugPrint('PDF export failed: $e');
      return false;
    }
  }

  static String _richTextToMarkdown(String jsonContent) {
    if (jsonContent.isEmpty) return '';

    final trimmed = jsonContent.trim();
    if (!trimmed.startsWith('[') && !trimmed.startsWith('{')) {
      return jsonContent;
    }

    try {
      final deltaList = jsonDecode(jsonContent) as List;
      final delta = Delta.fromJson(deltaList);
      final markdown = DeltaToMarkdown().convert(delta);
      return markdown;
    } catch (e) {
      debugPrint('Delta to Markdown failed: $e');
      return _simpleExtractFromDelta(jsonContent);
    }
  }

  static String _richTextToPlainText(String jsonContent) {
    if (jsonContent.isEmpty) return '';

    final trimmed = jsonContent.trim();
    if (!trimmed.startsWith('[') && !trimmed.startsWith('{')) {
      return jsonContent;
    }

    return _simpleExtractFromDelta(jsonContent);
  }

  static String _simpleExtractFromDelta(String jsonContent) {
    try {
      final delta = jsonDecode(jsonContent) as List;
      final buffer = StringBuffer();
      for (final item in delta) {
        if (item is Map && item['insert'] is String) {
          buffer.write(item['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('Simple delta extract failed: $e');
      return jsonContent;
    }
  }
}