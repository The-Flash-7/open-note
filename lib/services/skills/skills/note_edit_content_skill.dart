// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../../models/note.dart';

class NoteEditContentSkill extends Skill {
  NoteEditContentSkill()
    : super(
        id: 'note_edit_content',
        name: '编辑笔记内容',
        description: '支持多种方式编辑笔记内容：追加、前置、替换、查找替换、按标题插入/删除/替换章节等，不支持编辑富文本笔记',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '要编辑的笔记 ID',
            required: true,
          ),
          const SkillParameter(
            name: 'mode',
            type: 'string',
            description:
                '编辑模式：append（追加到末尾）/prepend（插入到开头）/replace_all（替换全部内容）/find_replace（查找并替换）/insert_after_heading（在指定标题后插入）/insert_before_heading（在指定标题前插入）/delete_section（删除指定标题下的内容）/replace_section（替换指定标题下的内容）/insert_at_line（在指定行号处插入）/delete_lines（删除指定行范围）/replace_lines（替换指定行范围）/replace_line（替换单行内容）',
            required: true,
            enumValues: [
              'append',
              'prepend',
              'replace_all',
              'find_replace',
              'insert_after_heading',
              'insert_before_heading',
              'delete_section',
              'replace_section',
              'insert_at_line',
              'delete_lines',
              'replace_lines',
              'replace_line',
            ],
          ),
          const SkillParameter(
            name: 'content',
            type: 'string',
            description: '要操作的内容（delete_section 模式不需要此参数）',
            required: false,
          ),
          const SkillParameter(
            name: 'search_text',
            type: 'string',
            description: '查找替换时的搜索文本（仅 find_replace 模式需要）',
            required: false,
          ),
          const SkillParameter(
            name: 'target_heading',
            type: 'string',
            description:
                '指定标题名称（精确匹配，用于 insert_after_heading/insert_before_heading/delete_section/replace_section 模式）',
            required: false,
          ),
          const SkillParameter(
            name: 'preview',
            type: 'boolean',
            description: '预览模式（true=只返回修改后的内容预览，不实际保存；false=实际保存，默认false）',
            required: false,
            defaultValue: false,
          ),
          const SkillParameter(
            name: 'line_number',
            type: 'number',
            description: '指定行号（从1开始，用于 insert_at_line/replace_line 模式）',
            required: false,
          ),
          const SkillParameter(
            name: 'line_start',
            type: 'number',
            description: '起始行号（从1开始，用于 delete_lines/replace_lines 模式）',
            required: false,
          ),
          const SkillParameter(
            name: 'line_end',
            type: 'number',
            description: '结束行号（包含，用于 delete_lines/replace_lines 模式，自动截断到最后一行）',
            required: false,
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
      final noteId = args['note_id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        return SkillResult.error('笔记 ID 不能为空');
      }

      final mode = args['mode'] as String?;
      if (mode == null || !_validModes.contains(mode)) {
        return SkillResult.error('不支持的编辑模式: $mode');
      }

      final existingNote = await OpenNoteTools.getNoteById(noteId);
      if (existingNote == null) {
        return SkillResult.error('未找到 ID 为 $noteId 的笔记');
      }

      // 格式检查：暂不支持编辑富文本笔记
      if (existingNote.format == NoteFormat.richText) {
        return SkillResult.error('暂不支持编辑富文本笔记！');
      }

      final content = args['content'] as String?;
      final searchText = args['search_text'] as String?;
      final targetHeading = args['target_heading'] as String?;
      final preview = args['preview'] as bool? ?? false;
      final lineNumber = args['line_number'] as int?;
      final lineStart = args['line_start'] as int?;
      final lineEnd = args['line_end'] as int?;

      // 检查必需参数
      if (!_noContentModes.contains(mode) &&
          (content == null || content.isEmpty)) {
        return SkillResult.error('内容不能为空');
      }

      if ((mode == 'find_replace') &&
          (searchText == null || searchText.isEmpty)) {
        return SkillResult.error('查找替换模式需要 search_text 参数');
      }

      if (_headingModes.contains(mode) &&
          (targetHeading == null || targetHeading.isEmpty)) {
        return SkillResult.error('$mode 模式需要 target_heading 参数');
      }

      if (_lineNumberModes.contains(mode) && lineNumber == null) {
        return SkillResult.error('$mode 模式需要 line_number 参数');
      }

      if (_lineRangeModes.contains(mode)) {
        if (lineStart == null || lineEnd == null) {
          return SkillResult.error('$mode 模式需要 line_start 和 line_end 参数');
        }
        if (lineStart > lineEnd) {
          return SkillResult.error('line_start 不能大于 line_end');
        }
      }

      // 执行编辑操作
      final originalContent = existingNote.content;
      String? newContent;
      String? errorMessage;

      switch (mode) {
        case 'append':
          newContent = _appendContent(originalContent, content!);
          break;
        case 'prepend':
          newContent = _prependContent(originalContent, content!);
          break;
        case 'replace_all':
          newContent = content!;
          break;
        case 'find_replace':
          final result = _findReplace(originalContent, searchText!, content!);
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'insert_after_heading':
          final result = _insertAfterHeading(
            originalContent,
            targetHeading!,
            content!,
          );
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'insert_before_heading':
          final result = _insertBeforeHeading(
            originalContent,
            targetHeading!,
            content!,
          );
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'delete_section':
          final result = _deleteSection(originalContent, targetHeading!);
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'replace_section':
          final result = _replaceSection(
            originalContent,
            targetHeading!,
            content!,
          );
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'insert_at_line':
          final result = _insertAtLine(originalContent, lineNumber!, content!);
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'delete_lines':
          final result = _deleteLines(originalContent, lineStart!, lineEnd!);
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'replace_lines':
          final result = _replaceLines(
            originalContent,
            lineStart!,
            lineEnd!,
            content!,
          );
          newContent = result['content'];
          errorMessage = result['error'];
          break;
        case 'replace_line':
          final result = _replaceLine(originalContent, lineNumber!, content!);
          newContent = result['content'];
          errorMessage = result['error'];
          break;
      }

      if (errorMessage != null) {
        return SkillResult.error(errorMessage);
      }

      if (newContent == null) {
        return SkillResult.error('内容处理失败');
      }

      // 预览模式：不实际保存
      if (preview) {
        return SkillResult.ok(
          message: '预览模式 - 内容未保存',
          metadata: {
            'noteId': noteId,
            'mode': mode,
            'originalLength': originalContent.length,
            'newLength': newContent.length,
            'preview': true,
            'previewContent': newContent,
          },
        );
      }

      // 实际保存
      final success = await OpenNoteTools.updateNote(
        noteId: noteId,
        content: newContent,
      );

      if (!success) {
        return SkillResult.error('笔记更新失败');
      }

      final updatedNote = await OpenNoteTools.getNoteById(noteId);
      return SkillResult.ok(
        message: '笔记内容已更新（${_modeDescriptions[mode] ?? mode}模式）',
        data: {'id': noteId},
        referencedNotes: updatedNote != null ? [updatedNote] : [],
        metadata: {
          'noteId': noteId,
          'mode': mode,
          'originalLength': originalContent.length,
          'newLength': newContent.length,
          'preview': false,
        },
      );
    } catch (e) {
      debugPrint('[NoteEditContent] 异常: $e');
      return SkillResult.error('编辑笔记内容失败: $e');
    }
  }

  // 有效的编辑模式
  static const List<String> _validModes = [
    'append',
    'prepend',
    'replace_all',
    'find_replace',
    'insert_after_heading',
    'insert_before_heading',
    'delete_section',
    'replace_section',
    'insert_at_line',
    'delete_lines',
    'replace_lines',
    'replace_line',
  ];

  // 需要标题的模式
  static const List<String> _headingModes = [
    'insert_after_heading',
    'insert_before_heading',
    'delete_section',
    'replace_section',
  ];

  // 不需要 content 参数的模式
  static const List<String> _noContentModes = [
    'delete_section',
    'delete_lines',
  ];

  // 需要 line_number 参数的模式
  static const List<String> _lineNumberModes = [
    'insert_at_line',
    'replace_line',
  ];

  // 需要 line_start 和 line_end 参数的模式
  static const List<String> _lineRangeModes = ['delete_lines', 'replace_lines'];

  // 模式描述
  static const Map<String, String> _modeDescriptions = {
    'append': '追加',
    'prepend': '前置',
    'replace_all': '替换全部',
    'find_replace': '查找替换',
    'insert_after_heading': '标题后插入',
    'insert_before_heading': '标题前插入',
    'delete_section': '删除章节',
    'replace_section': '替换章节',
    'insert_at_line': '指定行插入',
    'delete_lines': '删除行',
    'replace_lines': '替换行范围',
    'replace_line': '替换单行',
  };

  // 追加到末尾
  String _appendContent(String original, String newContent) {
    if (original.isEmpty) return newContent;
    return '$original\n\n$newContent';
  }

  // 插入到开头
  String _prependContent(String original, String newContent) {
    if (original.isEmpty) return newContent;
    return '$newContent\n\n$original';
  }

  // 查找替换
  Map<String, String?> _findReplace(
    String original,
    String searchText,
    String replaceText,
  ) {
    if (!original.contains(searchText)) {
      return {'content': null, 'error': '未找到"$searchText"，未进行替换'};
    }
    return {
      'content': original.replaceAll(searchText, replaceText),
      'error': null,
    };
  }

  // 查找标题行索引（精确匹配）
  int _findHeadingIndex(String content, String heading) {
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      // 精确匹配 Markdown 标题：# 标题、## 标题 等
      for (int level = 1; level <= 6; level++) {
        final prefix = '#' * level;
        if (line == '$prefix $heading') {
          return i;
        }
      }
    }
    return -1;
  }

  // 查找下一个标题的行索引
  int _findNextHeadingIndex(String content, int startIndex) {
    final lines = content.split('\n');
    for (int i = startIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      // 匹配任何 Markdown 标题
      if (line.startsWith('# ') ||
          line.startsWith('## ') ||
          line.startsWith('### ') ||
          line.startsWith('#### ') ||
          line.startsWith('##### ') ||
          line.startsWith('###### ')) {
        return i;
      }
    }
    return -1; // 没有下一个标题
  }

  // 在指定标题后插入
  Map<String, String?> _insertAfterHeading(
    String original,
    String heading,
    String newContent,
  ) {
    final headingIndex = _findHeadingIndex(original, heading);
    if (headingIndex == -1) {
      return {'content': null, 'error': '未找到标题"$heading"'};
    }

    final lines = original.split('\n');
    final nextHeadingIndex = _findNextHeadingIndex(original, headingIndex);

    if (nextHeadingIndex == -1) {
      // 没有下一个标题，插入到末尾
      lines.add('');
      lines.add(newContent);
    } else {
      // 在下一个标题前插入
      lines.insert(nextHeadingIndex, '');
      lines.insert(nextHeadingIndex, newContent);
    }

    return {'content': lines.join('\n'), 'error': null};
  }

  // 在指定标题前插入
  Map<String, String?> _insertBeforeHeading(
    String original,
    String heading,
    String newContent,
  ) {
    final headingIndex = _findHeadingIndex(original, heading);
    if (headingIndex == -1) {
      return {'content': null, 'error': '未找到标题"$heading"'};
    }

    final lines = original.split('\n');
    lines.insert(headingIndex, newContent);
    lines.insert(headingIndex, '');

    return {'content': lines.join('\n'), 'error': null};
  }

  // 删除指定标题下的内容
  Map<String, String?> _deleteSection(String original, String heading) {
    final headingIndex = _findHeadingIndex(original, heading);
    if (headingIndex == -1) {
      return {'content': null, 'error': '未找到标题"$heading"'};
    }

    final lines = original.split('\n');
    final nextHeadingIndex = _findNextHeadingIndex(original, headingIndex);

    if (nextHeadingIndex == -1) {
      // 没有下一个标题，删除标题及其后的所有内容
      lines.removeRange(headingIndex, lines.length);
    } else {
      // 删除标题到下一个标题之间的内容（包括标题行）
      lines.removeRange(headingIndex, nextHeadingIndex);
    }

    // 清理多余空行
    return {'content': _cleanEmptyLines(lines.join('\n')), 'error': null};
  }

  // 替换指定标题下的内容
  Map<String, String?> _replaceSection(
    String original,
    String heading,
    String newContent,
  ) {
    final headingIndex = _findHeadingIndex(original, heading);
    if (headingIndex == -1) {
      return {'content': null, 'error': '未找到标题"$heading"'};
    }

    final lines = original.split('\n');
    final nextHeadingIndex = _findNextHeadingIndex(original, headingIndex);

    if (nextHeadingIndex == -1) {
      // 没有下一个标题，替换标题后的所有内容
      lines.removeRange(headingIndex + 1, lines.length);
      lines.add('');
      lines.add(newContent);
    } else {
      // 替换标题到下一个标题之间的内容（保留标题行）
      lines.removeRange(headingIndex + 1, nextHeadingIndex);
      lines.insert(headingIndex + 1, '');
      lines.insert(headingIndex + 1, newContent);
    }

    return {'content': lines.join('\n'), 'error': null};
  }

  // 清理连续的空行（最多保留2个空行）
  String _cleanEmptyLines(String content) {
    return content.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  // 在指定行号处插入内容（行号从1开始）
  Map<String, String?> _insertAtLine(
    String original,
    int lineNumber,
    String newContent,
  ) {
    final lines = original.split('\n');
    final totalLines = lines.length;

    // 行号从1开始，转换为索引
    int index = lineNumber - 1;

    // 越界处理：如果行号超过总行数，插入到末尾
    if (index >= totalLines) {
      index = totalLines;
    } else if (index < 0) {
      index = 0;
    }

    lines.insert(index, newContent);
    return {'content': lines.join('\n'), 'error': null};
  }

  // 删除指定行号范围（行号从1开始，自动截断到最后一行）
  Map<String, String?> _deleteLines(
    String original,
    int lineStart,
    int lineEnd,
  ) {
    final lines = original.split('\n');
    final totalLines = lines.length;

    // 行号从1开始，转换为索引
    int startIndex = lineStart - 1;
    int endIndex = lineEnd - 1;

    // 自动截断到有效范围
    startIndex = startIndex.clamp(0, totalLines - 1);
    endIndex = endIndex.clamp(startIndex, totalLines - 1);

    // 删除范围（endIndex + 1 因为 removeRange 是开区间）
    lines.removeRange(startIndex, endIndex + 1);
    return {'content': _cleanEmptyLines(lines.join('\n')), 'error': null};
  }

  // 替换指定行号范围（行号从1开始，自动截断到最后一行）
  Map<String, String?> _replaceLines(
    String original,
    int lineStart,
    int lineEnd,
    String newContent,
  ) {
    final lines = original.split('\n');
    final totalLines = lines.length;

    // 行号从1开始，转换为索引
    int startIndex = lineStart - 1;
    int endIndex = lineEnd - 1;

    // 自动截断到有效范围
    startIndex = startIndex.clamp(0, totalLines - 1);
    endIndex = endIndex.clamp(startIndex, totalLines - 1);

    // 删除旧内容
    lines.removeRange(startIndex, endIndex + 1);
    // 插入新内容
    lines.insertAll(startIndex, newContent.split('\n'));
    return {'content': lines.join('\n'), 'error': null};
  }

  // 替换单行内容（行号从1开始）
  Map<String, String?> _replaceLine(
    String original,
    int lineNumber,
    String newContent,
  ) {
    final lines = original.split('\n');
    final totalLines = lines.length;

    // 行号从1开始，转换为索引
    int index = lineNumber - 1;

    // 越界检查
    if (index < 0 || index >= totalLines) {
      return {'content': null, 'error': '行号 $lineNumber 超出范围（共$totalLines行）'};
    }

    lines[index] = newContent;
    return {'content': lines.join('\n'), 'error': null};
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_edit_content", "args": {"note_id": "abc123", "mode": "insert_at_line", "line_number": 10, "content": "## 新增章节\\n新内容..."}}';
  }
}
