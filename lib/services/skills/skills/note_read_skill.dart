// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteReadSkill extends Skill {
  NoteReadSkill()
    : super(
        id: 'note_read',
        name: '读取笔记',
        description: '读取指定笔记的内容，支持搜索、行范围、全文等多种读取方式',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '要读取的笔记 ID',
            required: true,
          ),
          const SkillParameter(
            name: 'full_content',
            type: 'boolean',
            description: '是否返回笔记完整内容（可选，默认不返回，建议只有在必须查询全文内容时才传true）',
            required: false,
            defaultValue: false,
          ),
          const SkillParameter(
            name: 'line_start',
            type: 'number',
            description: '起始行号（从1开始），与 line_end 配合使用，读取指定行范围',
            required: false,
          ),
          const SkillParameter(
            name: 'line_end',
            type: 'number',
            description: '结束行号（包含），与 line_start 配合使用',
            required: false,
          ),
          const SkillParameter(
            name: 'search_text',
            type: 'string',
            description: '搜索文本，返回匹配行及其上下文',
            required: false,
          ),
          const SkillParameter(
            name: 'context_lines',
            type: 'number',
            description: '搜索时返回匹配行前后各多少行上下文（默认3行）',
            required: false,
            defaultValue: 3,
          ),
        ],
        category: SkillCategory.read,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      final noteId = args['note_id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        return SkillResult.error('笔记 ID 不能为空');
      }

      final note = await OpenNoteTools.getNoteById(noteId);
      if (note == null) {
        return SkillResult.error('未找到 ID 为 $noteId 的笔记');
      }

      final fullContent = args['full_content'] as bool? ?? false;
      final lineStart = args['line_start'] as int?;
      final lineEnd = args['line_end'] as int?;
      final searchText = args['search_text'] as String?;
      final contextLines = args['context_lines'] as int? ?? 3;

      String readContent = '';
      String message = '已读取笔记"${note.title}"';

      // 优先级：search_text > line_range > full_content
      if (searchText != null && searchText.isNotEmpty) {
        // 搜索模式
        final result = _searchContent(note.content, searchText, contextLines);
        readContent = result['content'] ?? '';
        final matchCount = result['matchCount'] ?? 0;
        message = '已读取笔记"${note.title}"，找到 $matchCount 处匹配';
      } else if (lineStart != null || lineEnd != null) {
        // 行范围模式
        final result = _readLineRange(note.content, lineStart, lineEnd);
        readContent = result['content'] ?? '';
        final actualStart = result['actualStart'] ?? 0;
        final actualEnd = result['actualEnd'] ?? 0;
        message = '已读取笔记"${note.title}"第 $actualStart-$actualEnd 行';
      } else if (fullContent) {
        // 完整内容模式
        readContent = _addLineNumbers(note.content);
        final totalLines = note.content.split('\n').length;
        message = '已读取笔记"${note.title}"完整内容（共$totalLines行）';
      }

      return SkillResult.ok(
        message: message,
        data: note,
        referencedNotes: [note],
        metadata: {'noteId': noteId, 'readContent': readContent},
      );
    } catch (e) {
      debugPrint('[NoteRead] 异常: $e');
      return SkillResult.error('读取笔记失败: $e');
    }
  }

  /// 添加行号前缀
  String _addLineNumbers(String content) {
    final lines = content.split('\n');
    final buffer = StringBuffer();
    for (int i = 0; i < lines.length; i++) {
      buffer.writeln('${i + 1}: ${lines[i]}');
    }
    return buffer.toString().trim();
  }

  /// 读取指定行范围（行号从1开始）
  Map<String, dynamic> _readLineRange(
    String content,
    int? lineStart,
    int? lineEnd,
  ) {
    final lines = content.split('\n');
    final totalLines = lines.length;

    // 处理默认值和越界
    int actualStart = lineStart ?? 1;
    int actualEnd = lineEnd ?? totalLines;

    // 自动截断到有效范围
    actualStart = actualStart.clamp(1, totalLines);
    actualEnd = actualEnd.clamp(actualStart, totalLines);

    // 提取行（注意行号从1开始，数组索引从0开始）
    final selectedLines = lines.sublist(actualStart - 1, actualEnd);
    final contentWithNumbers = selectedLines
        .asMap()
        .entries
        .map((e) => '${actualStart + e.key}: ${e.value}')
        .join('\n');

    return {
      'content': contentWithNumbers,
      'actualStart': actualStart,
      'actualEnd': actualEnd,
    };
  }

  /// 搜索文本并返回匹配行及上下文
  Map<String, dynamic> _searchContent(
    String content,
    String searchText,
    int contextLines,
  ) {
    final lines = content.split('\n');
    final matches = <Map<String, dynamic>>[];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(searchText)) {
        // 计算上下文范围
        final ctxStart = (i - contextLines).clamp(0, lines.length - 1);
        final ctxEnd = (i + contextLines).clamp(0, lines.length - 1);

        final contextLinesList = lines.sublist(ctxStart, ctxEnd + 1);
        final contextContent = contextLinesList
            .asMap()
            .entries
            .map((e) => '${ctxStart + e.key + 1}: ${e.value}')
            .join('\n');

        matches.add({
          'lineNumber': i + 1,
          'lineContent': lines[i],
          'context': contextContent,
        });
      }
    }

    if (matches.isEmpty) {
      return {'content': '', 'matchCount': 0};
    }

    // 将所有匹配的上下文合并返回
    final allContent = matches
        .map((m) => m['context'] as String)
        .join('\n\n---\n\n');

    return {
      'content': allContent,
      'matchCount': matches.length,
      'matches': matches,
    };
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_read", "args": {"note_id": "abc123", "line_start": 10, "line_end": 20}}';
  }
}
