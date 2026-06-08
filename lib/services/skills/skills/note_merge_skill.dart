// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown_quill/markdown_quill.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';
import '../../../models/note.dart';

class NoteMergeSkill extends Skill {
  final AIService? aiService;

  NoteMergeSkill({this.aiService})
    : super(
        id: 'note_merge',
        name: '合并笔记',
        description: '将多篇笔记合并成一篇新笔记（支持不同格式）',
        parameters: [
          const SkillParameter(
            name: 'note_ids',
            type: 'array',
            description: '要合并的笔记 ID 列表（至少2篇）',
            required: true,
          ),
          const SkillParameter(
            name: 'title',
            type: 'string',
            description: '新笔记标题（可选，不指定则由AI生成）',
            required: false,
          ),
          const SkillParameter(
            name: 'merge_style',
            type: 'string',
            description: '合并方式：concat（顺序拼接）/summarize（摘要提炼）/rewrite（重写组织）',
            required: false,
            defaultValue: 'summarize',
            enumValues: ['concat', 'summarize', 'rewrite'],
          ),
        ],
        category: SkillCategory.write,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (aiService == null || !aiService!.hasConfig()) {
        return SkillResult.error('AI 服务未配置，无法合并笔记');
      }

      final noteIds = (args['note_ids'] as List?)?.cast<String>();
      if (noteIds == null || noteIds.isEmpty) {
        return SkillResult.error('笔记 ID 列表不能为空');
      }

      final customTitle = args['title'] as String?;
      final mergeStyle = args['merge_style'] as String? ?? 'summarize';

      final notes = <Note>[];
      for (final id in noteIds) {
        final note = await OpenNoteTools.getNoteById(id);
        if (note != null) {
          notes.add(note);
        }
      }

      if (notes.length < 2) {
        return SkillResult.error('至少需要 2 篇笔记才能合并');
      }

      // 组装笔记上下文（统一转换为 Markdown）
      final notesContext = _buildNotesContext(notes);

      // 调用 AI 合并
      debugPrint('[NoteMerge] 调用 AI 合并笔记，风格: $mergeStyle');
      final aiResult = await _mergeWithAI(
        notesContext,
        mergeStyle,
        cancellationToken,
      );

      // 提取 AI 输出
      final title = customTitle ?? (aiResult['title'] as String? ?? '合并笔记');
      final content = aiResult['content'] as String? ?? '';
      final tags =
          (aiResult['tags'] as List?)?.cast<String>() ?? _mergeTags(notes);

      if (content.isEmpty) {
        return SkillResult.error('合并失败，未生成有效内容');
      }

      // 创建新笔记（Markdown 格式）
      final noteId = await OpenNoteTools.createNote(
        title: title,
        content: content,
        category: notes.first.category,
        tags: tags,
        autoGenerateSummary: true,
      );

      if (noteId == null) {
        return SkillResult.error('创建合并笔记失败');
      }

      final mergedNote = await OpenNoteTools.getNoteById(noteId);
      return SkillResult.ok(
        message: '已将 ${notes.length} 篇笔记合并为新笔记"$title"',
        referencedNotes: mergedNote != null ? [mergedNote] : [],
        metadata: {
          'mergedNoteId': '$noteId（供内部使用，不展示给用户）',
          'mergedNoteTitle': title,
          'mergedNoteCategoryId': '${notes.first.category}（供内部使用，不展示给用户）',
          'mergedNoteTags': tags,
          'sourceNotesId': notes.map((n) => n.id).toList(),
          'mergeStyle': mergeStyle,
        },
      );
    } catch (e) {
      return SkillResult.error('合并笔记失败: $e');
    }
  }

  /// 组装笔记上下文（只转换富文本为 Markdown）
  String _buildNotesContext(List<Note> notes) {
    final buffer = StringBuffer();
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];

      // 只转换富文本为 Markdown，其他格式保持原样
      String content;
      if (note.format == NoteFormat.richText) {
        content = _convertRichTextToMarkdown(note.content);
      } else {
        content = note.content;
      }

      buffer.writeln('标题：${note.title}');
      buffer.writeln('标签：${note.tags.isEmpty ? '' : note.tags.join(',')}');
      buffer.writeln('内容：$content');

      if (i < notes.length - 1) {
        buffer.writeln('--------------------------------');
      }
    }
    return buffer.toString();
  }

  /// 使用 markdown_quill 将富文本 Delta 转换为 Markdown
  String _convertRichTextToMarkdown(String jsonContent) {
    if (jsonContent.isEmpty) return '';

    // 检测是否是 JSON 格式（Quill Delta 以 [ 开头）
    final trimmed = jsonContent.trim();
    if (!trimmed.startsWith('[') && !trimmed.startsWith('{')) {
      // 不是 JSON 格式，直接返回原文
      debugPrint('[NoteMerge] 富文本内容不是 JSON 格式，直接返回原文');
      return jsonContent;
    }

    try {
      // 将 JSON List 转换为 Delta 对象
      final deltaList = jsonDecode(jsonContent) as List;
      final delta = Delta.fromJson(deltaList);

      // 使用 markdown_quill 库转换 Delta 到 Markdown
      final markdown = DeltaToMarkdown().convert(delta);
      debugPrint(
        '[NoteMerge] Delta 转 Markdown 成功，原文长度: ${jsonContent.length}, Markdown长度: ${markdown.length}',
      );
      return markdown;
    } catch (e) {
      debugPrint('[NoteMerge] Delta 转 Markdown 失败: $e');
      debugPrint(
        '[NoteMerge] 内容前 200 字符: ${jsonContent.substring(0, jsonContent.length > 200 ? 200 : jsonContent.length)}',
      );
      // 降级：简单提取纯文本
      return _simpleExtractFromDelta(jsonContent);
    }
  }

  /// 简单提取：直接从 Delta JSON 中提取所有 insert 字符串（降级方案）
  String _simpleExtractFromDelta(String jsonContent) {
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
      debugPrint('[NoteMerge] 简单提取也失败: $e');
      return jsonContent;
    }
  }

  /// 调用 AI 合并笔记
  Future<Map<String, dynamic>> _mergeWithAI(
    String notesContext,
    String mergeStyle,
    CancellationToken? cancellationToken,
  ) async {
    // 合并风格说明
    String styleInstruction;
    switch (mergeStyle) {
      case 'concat':
        styleInstruction = '按顺序拼接各笔记内容，保持段落结构清晰和信息完整性';
        break;
      case 'summarize':
        styleInstruction = '提炼各笔记核心内容，生成简洁的摘要式合并，保留关键信息';
        break;
      case 'rewrite':
        styleInstruction = '重新组织各笔记内容，生成连贯流畅的新文章，可适当调整段落结构';
        break;
      default:
        styleInstruction = '按顺序拼接各笔记内容，保持段落结构清晰和信息完整性';
    }

    final prompt =
        '''
你是一个专业的笔记合并助手。请将以下笔记合并为一篇新笔记。

## 合并要求
- 合并方式：$styleInstruction
- 保持内容的完整性和准确性
- 输出为 Markdown 格式
- 标签应合并所有源笔记的标签，去重后返回

## 待合并的笔记
$notesContext

## 输出格式
请严格按照以下 JSON 格式输出：
{
  "title": "新笔记标题",
  "content": "合并后的 Markdown 内容",
  "tags": ["标签1", "标签2"]
}
''';

    final response = await aiService!.callAI(
      prompt,
      cancellationToken: cancellationToken,
    );
    debugPrint('[NoteMerge] AI 原始响应长度: ${response.length}');

    // 解析 JSON 响应
    final result = _parseAIResponse(response);
    if (result != null) {
      return result;
    }

    // 解析失败
    debugPrint(
      '[NoteMerge] JSON 解析失败，响应前 300 字符: ${response.substring(0, response.length > 300 ? 300 : response.length)}',
    );
    throw Exception('AI 返回的响应格式不正确，无法解析为有效的 JSON');
  }

  /// 解析 AI 响应中的 JSON
  Map<String, dynamic>? _parseAIResponse(String response) {
    String cleaned = response.trim();

    // 移除 markdown 代码块
    if (cleaned.startsWith('```')) {
      final firstBacktick = cleaned.indexOf('```');
      var secondBacktick = cleaned.indexOf('```', firstBacktick + 3);
      if (secondBacktick == -1) {
        secondBacktick = cleaned.lastIndexOf('```');
      }
      if (secondBacktick > firstBacktick + 3) {
        cleaned = cleaned.substring(firstBacktick + 3, secondBacktick).trim();
        if (cleaned.startsWith('json')) {
          cleaned = cleaned.substring(4).trim();
        }
      }
    }

    // 提取最外层 { ... }
    final firstBrace = cleaned.indexOf('{');
    final lastBrace = cleaned.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace > firstBrace) {
      final extracted = cleaned.substring(firstBrace, lastBrace + 1);
      try {
        return jsonDecode(extracted) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('[NoteMerge] 提取 JSON 失败: $e');
      }
    }

    return null;
  }

  List<String> _mergeTags(List<Note> notes) {
    final allTags = <String>{};
    for (final note in notes) {
      allTags.addAll(note.tags);
    }
    return allTags.toList();
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_merge", "args": {"note_ids": ["abc123", "def456"], "merge_style": "summarize"}}';
  }
}
