// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class MarkdownToPdfConverter {
  final pw.Font? font;
  final pw.Font? emojiFont;
  final pw.Font? codeFont;

  MarkdownToPdfConverter({
    required this.font,
    required this.emojiFont,
    required this.codeFont,
  });

  List<pw.Widget> convert(String markdownContent) {
    try {
      debugPrint('=== Markdown to PDF Conversion ===');

      final document = md.Document(
        extensionSet: md.ExtensionSet.gitHubWeb,
      );

      final lines = LineSplitter().convert(markdownContent);
      final nodes = document.parseLines(lines);

      debugPrint('Parsed ${nodes.length} nodes from Markdown');

      final widgets = <pw.Widget>[];
      int nodeIndex = 0;

      for (final node in nodes) {
        nodeIndex++;
        if (node is md.Element) {
          debugPrint('Node[$nodeIndex]: Element <${node.tag}>');

          if (node.tag == 'ul' || node.tag == 'ol') {
            final listItems = _convertListItems(node);
            debugPrint('  → List expanded to ${listItems.length} independent widgets');
            widgets.addAll(listItems);
          } else if (node.tag == 'pre') {
            final codeChunks = _convertCodeBlockChunks(node);
            debugPrint('  → Code block expanded to ${codeChunks.length} independent widgets');
            widgets.addAll(codeChunks);
          } else {
            final widget = _convertNode(node);
            if (widget != null) {
              debugPrint('  → Created widget: ${widget.runtimeType}');
              widgets.add(widget);
            } else {
              debugPrint('  → Skipped (widget is null)');
            }
          }
        } else {
          debugPrint('Node[$nodeIndex]: ${node.runtimeType} (non-Element)');
        }
      }

      debugPrint('Total widgets created: ${widgets.length}');
      return widgets;
    } catch (e) {
      debugPrint('Markdown to PDF conversion failed: $e');
      return [pw.Text(markdownContent)];
    }
  }

  pw.Widget? _convertNode(md.Node node) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
          return _convertHeading(node, level: 1);
        case 'h2':
          return _convertHeading(node, level: 2);
        case 'h3':
          return _convertHeading(node, level: 3);
        case 'h4':
          return _convertHeading(node, level: 4);
        case 'h5':
          return _convertHeading(node, level: 5);
        case 'h6':
          return _convertHeading(node, level: 6);
        case 'p':
          return _convertParagraph(node);
        case 'blockquote':
          return _convertBlockquote(node);
        case 'hr':
          return _convertHorizontalRule();
        default:
          return null;
      }
    }
    return null;
  }

  List<pw.Widget> _convertListItems(md.Element element) {
    final items = <pw.Widget>[];
    final children = element.children ?? [];
    bool isOrdered = element.tag == 'ol';
    int index = 1;

    for (final child in children) {
      if (child is md.Element && child.tag == 'li') {
        final itemChildren = _convertInlineNodes(child.children);
        final prefix = isOrdered ? '$index. ' : '• ';

        final spans = <pw.InlineSpan>[
          pw.TextSpan(
            text: prefix,
            style: pw.TextStyle(
              fontSize: 12,
              font: font,
              fontFallback: _getFontFallback(),
            ),
          ),
          ...itemChildren,
        ];

        items.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
            child: pw.RichText(
              text: pw.TextSpan(
                children: spans,
                style: pw.TextStyle(
                  fontSize: 12,
                  font: font,
                  fontFallback: _getFontFallback(),
                ),
              ),
            ),
          ),
        );

        if (isOrdered) index++;
      }
    }

    return items;
  }

  List<pw.Widget> _convertCodeBlockChunks(md.Element element) {
    String code = '';
    final children = element.children ?? [];
    if (children.isNotEmpty) {
      final codeElement = children.first;
      if (codeElement is md.Element && codeElement.tag == 'code') {
        code = _extractText(codeElement);
      }
    }

    if (code.isEmpty) return [];

    final lines = code.split('\n');
    final linesCount = lines.length;

    debugPrint('    CodeBlock: ${code.length} chars, $linesCount lines');

    const chunkSize = 15;

    if (linesCount <= chunkSize) {
      debugPrint('      Using single chunk ($linesCount lines)');
      return [
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            code,
            style: pw.TextStyle(
              fontSize: 10,
              font: codeFont ?? font,
              fontFallback: _getFontFallback(),
              lineSpacing: 1.4,
            ),
          ),
        )
      ];
    }

    debugPrint('      Splitting into chunks ($chunkSize lines per chunk)');

    final widgets = <pw.Widget>[];
    int chunkIndex = 0;

    for (int i = 0; i < linesCount; i += chunkSize) {
      final end = (i + chunkSize < linesCount) ? i + chunkSize : linesCount;
      final chunkLines = lines.sublist(i, end);
      final chunkCode = chunkLines.join('\n');
      chunkIndex++;

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            chunkCode,
            style: pw.TextStyle(
              fontSize: 10,
              font: codeFont ?? font,
              fontFallback: _getFontFallback(),
              lineSpacing: 1.4,
            ),
          ),
        )
      );

      debugPrint('        Chunk $chunkIndex: ${chunkLines.length} lines');
    }

    return widgets;
  }

  pw.Widget _convertHeading(md.Element element, {required int level}) {
    final text = _extractText(element);
    if (text.isEmpty) return pw.SizedBox();

    debugPrint('    H$level heading: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}" (${text.length} chars)');

    final sizes = {
      1: 28.0,
      2: 24.0,
      3: 20.0,
      4: 18.0,
      5: 16.0,
      6: 14.0,
    };

    final fontSize = sizes[level] ?? 12.0;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
          font: font,
          fontFallback: _getFontFallback(),
        ),
      ),
    );
  }

  pw.Widget _convertParagraph(md.Element element) {
    final children = _convertInlineNodes(element.children);
    if (children.isEmpty) return pw.SizedBox();

    final text = _extractText(element);
    debugPrint('    Paragraph: "${text.length > 80 ? '${text.substring(0, 80)}...' : text}" (${text.length} chars)');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.RichText(
        text: pw.TextSpan(
          children: children,
          style: pw.TextStyle(
            fontSize: 12,
            font: font,
            fontFallback: _getFontFallback(),
            lineSpacing: 1.6,
          ),
        ),
      ),
    );
  }

  pw.Widget _convertBlockquote(md.Element element) {
    final children = _convertInlineNodes(element.children);
    final text = _extractText(element);
    debugPrint('    Blockquote: "${text.length > 80 ? '${text.substring(0, 80)}...' : text}" (${text.length} chars)');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(
            color: PdfColors.blue,
            width: 4,
          ),
        ),
        color: PdfColors.blue50,
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: children,
          style: pw.TextStyle(
            fontSize: 12,
            font: font,
            fontFallback: _getFontFallback(),
            color: PdfColors.grey800,
          ),
        ),
      ),
    );
  }

  pw.Widget _convertHorizontalRule() {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: 1,
          ),
        ),
      ),
    );
  }

  List<pw.InlineSpan> _convertInlineNodes(List<md.Node>? nodes) {
    if (nodes == null) return [];

    final spans = <pw.InlineSpan>[];

    for (final node in nodes) {
      if (node is md.Text) {
        spans.add(pw.TextSpan(text: node.text));
      } else if (node is md.Element) {
        final span = _convertInlineElement(node);
        if (span != null) {
          spans.add(span);
        }
      }
    }

    return spans;
  }

  pw.InlineSpan? _convertInlineElement(md.Element element) {
    final text = _extractText(element);
    if (text.isEmpty) return null;

    pw.TextStyle? style;

    switch (element.tag) {
      case 'strong':
        style = pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          font: font,
          fontFallback: _getFontFallback(),
        );
        break;
      case 'em':
        style = pw.TextStyle(
          fontStyle: pw.FontStyle.italic,
          font: font,
          fontFallback: _getFontFallback(),
        );
        break;
      case 'code':
        style = pw.TextStyle(
          font: codeFont ?? font,
          fontFallback: codeFont != null ? _getFontFallback() : [],
          background: pw.BoxDecoration(color: PdfColors.grey200),
        );
        break;
      case 'a':
        final href = element.attributes['href'];
        if (href != null) {
          return pw.TextSpan(
            text: text,
            style: pw.TextStyle(
              color: PdfColors.blue,
              decoration: pw.TextDecoration.underline,
              font: font,
              fontFallback: _getFontFallback(),
            ),
            annotation: pw.AnnotationLink(href),
          );
        }
        return pw.TextSpan(text: text);
      default:
        return pw.TextSpan(text: text);
    }

    return pw.TextSpan(text: text, style: style);
  }

  String _extractText(md.Node node) {
    if (node is md.Text) {
      return node.text;
    } else if (node is md.Element) {
      final buffer = StringBuffer();
      final children = node.children ?? [];
      for (final child in children) {
        buffer.write(_extractText(child));
      }
      return buffer.toString();
    }
    return '';
  }

  List<pw.Font> _getFontFallback() {
    final fallbacks = <pw.Font>[];
    
    if (font != null) {
      fallbacks.add(font!);
    }
    
    if (emojiFont != null) {
      fallbacks.add(emojiFont!);
    }
    
    if (codeFont != null) {
      fallbacks.add(codeFont!);
    }
    
    return fallbacks;
  }
}