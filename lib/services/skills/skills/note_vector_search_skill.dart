// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../models/note.dart';
import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../vector_store.dart';

class NoteVectorSearchSkill extends Skill {
  final VectorStore _vectorStore;

  NoteVectorSearchSkill({required VectorStore vectorStore})
    : _vectorStore = vectorStore,
      super(
        id: 'note_vector_search',
        name: '向量搜索笔记',
        description: '基于语义向量相似度搜索相关笔记，支持模糊查询和意图匹配',
        parameters: [
          const SkillParameter(
            name: 'query',
            type: 'string',
            description: '搜索关键词（用于语义匹配）',
            required: true,
          ),
          const SkillParameter(
            name: 'limit',
            type: 'number',
            description: '返回数量限制',
            required: false,
            defaultValue: 5,
          ),
        ],
        category: SkillCategory.query,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      final query = args['query'] as String? ?? '';
      final limit = (args['limit'] as num?)?.toInt() ?? 5;

      if (query.isEmpty) {
        return SkillResult.error('搜索关键词不能为空');
      }

      final vectorResults = await _vectorStore.search(query, topK: limit);

      if (vectorResults.isEmpty) {
        return SkillResult.ok(
          message: '没有找到与"$query"语义相关的笔记',
          data: [],
          metadata: {'searchMode': 'vector', 'query': query},
        );
      }

      // // 阈值过滤
      // final threshold = KnowledgeConfig.instance.searchThreshold;
      // final filteredResults = vectorResults
      //     .where((r) => r.score > threshold)
      //     .toList();

      // debugPrint(
      //   '向量搜索结果: 原始 ${vectorResults.length} 条, 阈值 $threshold, 过滤后 ${filteredResults.length} 条',
      // );

      // if (filteredResults.isEmpty) {
      //   return SkillResult.ok(
      //     message: '没有找到与"$query"语义相关的笔记（低于阈值 $threshold）',
      //     data: [],
      //     metadata: {'searchMode': 'vector', 'query': query},
      //   );
      // }

      // 按 noteId 去重，记录每篇笔记的最高向量匹配度
      final noteIds = <String>{};
      final noteScoreMap = <String, double>{};
      for (final r in vectorResults) {
        if (!noteIds.contains(r.noteId) || noteScoreMap[r.noteId]! < r.score) {
          noteScoreMap[r.noteId] = r.score;
        }
        noteIds.add(r.noteId);
      }

      // 获取完整 Note 对象
      final notes = <Note>[];
      for (final noteId in noteIds) {
        final note = await OpenNoteTools.getNoteById(noteId);
        if (note != null) {
          notes.add(note);
        }
      }

      final finalNotes = notes.take(limit).toList();

      if (finalNotes.isEmpty) {
        return SkillResult.ok(
          message: '没有找到与"$query"语义相关的笔记',
          data: [],
          metadata: {'searchMode': 'vector', 'query': query},
        );
      }

      // 构建最终笔记的 score 映射
      final finalNoteScores = <String, double>{};
      for (final note in finalNotes) {
        if (noteScoreMap.containsKey(note.id)) {
          finalNoteScores[note.id] = noteScoreMap[note.id]!;
        }
      }

      return SkillResult.ok(
        message: '找到 ${finalNotes.length} 条语义相关笔记',
        data: finalNotes,
        referencedNotes: finalNotes,
        metadata: {
          'searchMode': 'vector',
          'query': query,
          'count': finalNotes.length,
          'noteScores': finalNoteScores,
        },
      );
    } catch (e) {
      return SkillResult.error('向量搜索失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_vector_search", "args": {"query": "如何制定工作目标", "limit": 5}}';
  }
}
