// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/react_result.dart';
import '../models/agent_memory.dart';
import '../l10n/strings.g.dart';
import 'ai_service.dart';
import 'skills/skill_registry.dart';
import 'skills/skill_executor.dart' as skill_executor_pkg;
import 'skills/models/tool_call.dart' as skill_models;
import 'skills/models/skill_result.dart';
import 'vector_store.dart';
import 'prompts/react_prompt.dart';
import 'open_note_tools.dart';
import '../utils/cancellation_token.dart';
import 'memory_persistence_service.dart';
import '../providers/memory_settings_provider.dart';

class ReActEngine {
  final AIService _aiService;
  final SkillRegistry _skillRegistry;
  final skill_executor_pkg.SkillExecutor _skillExecutor;
  final VectorStore _vectorStore;
  final MemorySettingsProvider _memorySettings;
  AppLocale _userLanguage;
  static const int maxSteps = 10;
  static const int maxRetries = 2;

  ReActEngine({
    required AIService aiService,
    required SkillRegistry skillRegistry,
    required skill_executor_pkg.SkillExecutor skillExecutor,
    required VectorStore vectorStore,
    required MemorySettingsProvider memorySettings,
    required AppLocale userLanguage,
  }) : _aiService = aiService,
       _skillRegistry = skillRegistry,
       _skillExecutor = skillExecutor,
       _vectorStore = vectorStore,
       _memorySettings = memorySettings,
       _userLanguage = userLanguage;

  set userLanguage(AppLocale locale) => _userLanguage = locale;

  Future<ReActResult> run(
    String userMessage,
    List<Map<String, dynamic>> history, {
    Note? currentNote,
    CancellationToken? cancellationToken,
    required void Function(String thinking) onThinking,
    required void Function(
      String step,
      String toolName,
      String status, {
      Map<String, dynamic> args,
      Map<String, dynamic>? resultData,
    })
    onStepUpdate,
  }) async {
    final steps = <ReActStep>[];
    List<Note> relevantNotes = []; // 相关参考笔记（累积）
    final discardSet = <String>{}; // 丢弃的笔记ID集合（黑名单）
    final allToolCalls = <ToolCall>[];

    try {
      // 初始化 relevantNotes 为向量预检索结果
      final initialResults = await _vectorStore.search(userMessage, topK: 3);
      for (final r in initialResults) {
        final note = await OpenNoteTools.getNoteById(r.noteId);
        if (note != null) relevantNotes.add(note);
      }
      // 给AI参考的笔记上下文（动态更新）
      String relevantNotesContext = _buildRelevantNotesContext(relevantNotes);

      // 构建当前打开的笔记上下文
      String currentNoteContext = _buildCurrentNoteContext(currentNote);

      String? replyLanguage;

      for (int i = 0; i < maxSteps; i++) {
        // 检查取消
        cancellationToken?.throwIfCancelled();

        onStepUpdate('thinking', '', '第 ${i + 1} 步推理中...');

        // 1. Reasoning：AI 决定下一步
        final thought = await _generateThought(
          userMessage,
          steps,
          history,
          relevantNotesContext,
          currentNoteContext,
          onThinking,
          cancellationToken,
        );

        // AI 思考完成后再次检查取消
        cancellationToken?.throwIfCancelled();

        if (thought == null) {
          continue;
        }
        // 记录回复语言要求
        replyLanguage = thought['reply_language'];

        // 2. 如果是 done，返回最终答案
        if (thought['action'] == 'done') {
          final finalAnswer =
              thought['final_answer'] as String? ?? '抱歉，我未能完成您的需求。';
          final replyLanguage = thought['reply_language'] as String?;
          return ReActResult(
            steps: steps,
            finalAnswer: finalAnswer,
            referencedNotes: finalCitationNote(
              relevantNotes,
              thought['citation_note_ids'],
            ),
            toolCalls: allToolCalls,
            replyLanguage: replyLanguage,
          );
        }

        // 3. 执行工具
        final toolName = thought['tool'] as String?;
        final toolArgs =
            (thought['args'] as Map?)?.cast<String, dynamic>() ?? {};

        if (toolName == null || toolName.isEmpty) {
          continue;
        }

        onStepUpdate('tool_call', toolName, '正在调用...', args: toolArgs);

        final toolCall = ToolCall(tool: toolName, args: toolArgs);
        allToolCalls.add(toolCall);

        SkillResult? result;
        bool success = false;

        // 重试机制
        for (int attempt = 0; attempt <= maxRetries; attempt++) {
          // 重试前检查取消
          cancellationToken?.throwIfCancelled();

          try {
            final skillToolCalls = [
              skill_models.ToolCall(tool: toolCall.tool, args: toolCall.args),
            ];
            final results = await _skillExecutor.executeChain(
              skillToolCalls,
              cancellationToken: cancellationToken,
            );
            if (results.isNotEmpty) {
              result = results.last;
              success = result.success;
            }
          } catch (e) {
            debugPrint('工具 $toolName 执行异常 (尝试 ${attempt + 1}/$maxRetries): $e');
          }

          if (success) {
            break;
          }

          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }

        // 工具执行完成后检查取消，丢弃结果
        cancellationToken?.throwIfCancelled();

        // 记录步骤
        final step = ReActStep(
          thought: thought['thought'] as String? ?? '',
          tool: toolName,
          args: toolArgs,
          observation: result,
        );
        steps.add(step);

        // AI 评价过滤逻辑
        final aiRelevantIds =
            (thought['relevant_note_ids'] as List?)?.cast<String>() ?? [];

        if (result?.referencedNotes.isNotEmpty == true) {
          // 1. 过滤 existing relevantNotes：AI 没选的加入 discardSet
          final retainedNotes = <Note>[];
          for (final note in relevantNotes) {
            if (aiRelevantIds.contains(note.id)) {
              retainedNotes.add(note);
            } else {
              discardSet.add(note.id);
            }
          }

          // 2. 过滤新笔记：在 discardSet 中的丢弃
          final filteredNewNotes = <Note>[];
          for (final note in result!.referencedNotes) {
            if (!discardSet.contains(note.id)) {
              filteredNewNotes.add(note);
            }
          }

          // 3. 合并去重
          final existingIds = retainedNotes.map((n) => n.id).toSet();
          for (final note in filteredNewNotes) {
            if (!existingIds.contains(note.id)) {
              retainedNotes.add(note);
            }
          }

          relevantNotes = retainedNotes;
        }

        // 下轮开始前：动态更新参考笔记上下文
        relevantNotesContext = _buildRelevantNotesContext(relevantNotes);

        onStepUpdate(
          'tool_result',
          toolName,
          success ? '成功' : '失败: ${result?.message ?? "未知错误"}',
          args: toolArgs,
          resultData: success ? result?.toJson() : null,
        );

        if (toolName == 'note_open' && success) {
          return ReActResult(
            steps: steps,
            finalAnswer: result?.message ?? '',
            referencedNotes: relevantNotes,
            toolCalls: allToolCalls,
          );
        }

        // 如果失败且还有步数，继续让 AI 推理
        if (!success && i < maxSteps - 1) {
          continue;
        }
      }

      // 超出最大步数，让 AI 生成最终回答
      // 注意：此时没有从 AI 获取 replyLanguage，使用 null 让 _generateFinalAnswer 回退到系统设置
      final finalAnswer = await _generateFinalAnswer(
        userMessage,
        steps,
        relevantNotes,
        replyLanguage,
        cancellationToken,
      );

      return ReActResult(
        steps: steps,
        finalAnswer: finalAnswer,
        referencedNotes: relevantNotes,
        toolCalls: allToolCalls,
        replyLanguage: null,
      );
    } on OperationCancelledException {
      return ReActResult(
        steps: steps,
        finalAnswer: '操作已被用户中断',
        referencedNotes: relevantNotes,
        toolCalls: allToolCalls,
      );
    } catch (e) {
      debugPrint('ReAct 引擎异常: $e');
      return ReActResult(
        steps: steps,
        finalAnswer: '抱歉，我未能完成您的需求，请您再试一下。',
        referencedNotes: relevantNotes,
        toolCalls: allToolCalls,
        error: e.toString(),
      );
    }
  }

  List<Note> finalCitationNote(List<Note> notes, dynamic citationDynamic) {
    final citationNoteIds = (citationDynamic as List?)?.cast<String>() ?? [];
    if (citationNoteIds.isEmpty) {
      return []; // 或者 return notes..clear(); 取决于业务需求
    }
    // 1. 原地过滤：只保留 id 在 citationNoteIds 中的 Note
    notes.retainWhere((note) => citationNoteIds.contains(note.id));

    // 2. 基于 id 去重（保留首次出现的顺序）
    final seenIds = <String>{};
    return notes.where((note) => seenIds.add(note.id)).toList();
  }

  String _buildRelevantNotesContext(List<Note> notes) {
    if (notes.isEmpty) return '无相关参考笔记';

    final buffer = StringBuffer();
    for (final note in notes) {
      buffer.writeln('笔记ID: ${note.id}');
      buffer.writeln('标题: ${note.title}');
      final summary =
          note.summary ??
          (note.content.length > 500
              ? '${note.content.substring(0, 500)}...'
              : note.content);
      buffer.writeln('摘要: $summary');
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  String _buildCurrentNoteContext(Note? note) {
    if (note == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('用户当前正在查看的笔记：');
    buffer.writeln('笔记ID: ${note.id}');
    buffer.writeln('标题: ${note.title}');
    buffer.writeln('格式: ${note.format.name}');
    buffer.writeln('是否收藏: ${note.isFavorite ? '已收藏' : '未收藏'}');
    if (note.category != null) {
      buffer.writeln('分类ID: ${note.category}');
    }
    if (note.tags.isNotEmpty) {
      buffer.writeln('标签: ${note.tags.join(', ')}');
    }
    buffer.writeln(
      '摘要: ${note.summary ?? (note.content.length > 500 ? '${note.content.substring(0, 500)}...' : note.content)}',
    );
    return buffer.toString().trim();
  }

  Future<Map<String, dynamic>?> _generateThought(
    String userMessage,
    List<ReActStep> steps,
    List<Map<String, dynamic>> history,
    String relevantNotesContext,
    String currentNoteContext,
    void Function(String) onThinking,
    CancellationToken? cancellationToken,
  ) async {
    final toolDefinitions = _skillRegistry.generateToolDefinitionsPrompt();

    int stepIndex = 0;
    final previousSteps = steps
        .map((s) {
          stepIndex += 1;
          final buffer = StringBuffer();
          buffer.writeln('【步骤$stepIndex】思考: ${s.thought}');
          if (s.tool != null) {
            buffer.writeln('行动: 调用工具 ${s.tool}，参数: ${jsonEncode(s.args)}');
            buffer.writeln('观察: ${s.observation?.message ?? '无结果'}');

            // 增强：添加搜索结果的详细信息
            if (s.observation?.referencedNotes.isNotEmpty == true) {
              buffer.writeln('--- 找到的笔记 ---');
              for (int i = 0; i < s.observation!.referencedNotes.length; i++) {
                final note = s.observation!.referencedNotes[i];
                buffer.writeln(
                  '[${i + 1}] ID: ${note.id} | 标题: ${note.title} | 分类ID: ${note.category ?? '无'} | 标签: ${note.tags.isEmpty ? '无' : note.tags.join(', ')} | 收藏: ${note.isFavorite ? '是' : '否'} | 格式: ${note.format.name} | 更新: ${note.updatedAt.toString().split('.').first}',
                );
                if (s.tool == 'note_read') {
                  buffer.writeln(
                    '[${i + 1}] 读取到的内容: \n${s.observation!.metadata?['readContent']}',
                  );
                }
                if (i < s.observation!.referencedNotes.length - 1) {
                  buffer.writeln('[${i + 1}] --------------间隔线--------------');
                }
              }
              buffer.writeln('--- 笔记列表结束 ---');
            }
          }
          return buffer.toString();
        })
        .join('\n\n');

    final context = history
        .map((m) {
          return '${m['role']}: ${m['content']}';
        })
        .join('\n');

    final now = DateTime.now();
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final currentDatetime =
        '${now.year}年${now.month}月${now.day}日 '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${weekdays[now.weekday - 1]}';

    final memoryService = MemoryPersistenceService();

    String userMemoriesText = '无';
    String experienceTipsText = '无';

    if (_memorySettings.memorySystemEnabled) {
      final keywords = _extractKeywords(userMessage);

      List<AgentMemory> profileMemories = [];
      List<AgentMemory> factMemories = [];
      List<AgentMemory> experienceMemories = [];

      if (_memorySettings.profileInjectionEnabled) {
        profileMemories = await memoryService.getProfileMemories();
      }

      if (_memorySettings.factInjectionEnabled) {
        final relevantMemories = await memoryService.getMemoriesByTags(
          keywords,
        );
        factMemories = relevantMemories
            .where(
              (m) =>
                  m.type != MemoryType.profile &&
                  m.type != MemoryType.experience,
            )
            .toList();
      }

      if (_memorySettings.experienceInjectionEnabled) {
        experienceMemories = await memoryService.getExperienceMemories();
      }

      final allFactMemories = <AgentMemory>[
        ...profileMemories,
        ...factMemories.where(
          (m) => !profileMemories.any((pm) => pm.id == m.id),
        ),
      ];

      userMemoriesText = MemoryPersistenceService.formatMemoriesForPrompt(
        allFactMemories,
      );
      experienceTipsText = MemoryPersistenceService.formatMemoriesForPrompt(
        experienceMemories,
      );
    }

    final prompt = ReactPrompt.buildThoughtPrompt(
      toolDefinitions: toolDefinitions,
      userQuery: userMessage,
      currentDatetime: currentDatetime,
      userLanguageInstruction: _getUserLanguageInstruction(),
      userMemories: userMemoriesText,
      experienceTips: experienceTipsText,
      context: context,
      relevantNotesContext: relevantNotesContext,
      currentNoteContext: currentNoteContext,
      previousSteps: previousSteps,
    );

    try {
      // 使用流式调用以获取 thinking 内容
      String thinkingContent = '';
      String responseBuffer = '';

      await for (final chunk in _aiService.callAIStream(
        prompt,
        cancellationToken: cancellationToken,
      )) {
        if (chunk.thinking != null) {
          thinkingContent += chunk.thinking!;
          onThinking(thinkingContent);
        }
        if (chunk.content != null) {
          responseBuffer += chunk.content!;
        }
      }

      // 解析 JSON 响应
      final decision = _parseThoughtResponse(responseBuffer);
      return decision;
    } catch (e) {
      debugPrint('生成思考失败: $e');
      return null;
    }
  }

  Map<String, dynamic>? _parseThoughtResponse(String response) {
    try {
      String cleaned = response.trim();
      if (cleaned.contains('```json')) {
        final start = cleaned.indexOf('```json') + 7;
        final end = cleaned.indexOf('```', start);
        cleaned = cleaned.substring(start, end).trim();
      } else if (cleaned.contains('```')) {
        final start = cleaned.indexOf('```') + 3;
        final end = cleaned.indexOf('```', start);
        cleaned = cleaned.substring(start, end).trim();
      }

      // 预处理：修复 JSON 字符串值内部未转义的引号
      cleaned = _fixUnescapedQuotes(cleaned);

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('解析思考响应失败: $e, 原始响应: $response');
      // 如果解析失败，返回 done 并解释
      return {'thought': '解析响应失败', 'action': 'done', 'final_answer': response};
    }
  }

  /// 修复 JSON 字符串值内部未转义的引号
  String _fixUnescapedQuotes(String json) {
    final buffer = StringBuffer();
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < json.length; i++) {
      final char = json[i];

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        buffer.write(char);
        continue;
      }

      if (char == '"') {
        if (!inString) {
          inString = true;
        } else {
          // 检查是否是有效的字符串结束
          final nextNonWhitespace = _findNextNonWhitespace(json, i + 1);
          if (nextNonWhitespace == null || ':,]}'.contains(nextNonWhitespace)) {
            inString = false;
          } else {
            // 这是未转义的引号，转义它
            buffer.write('\\');
          }
        }
      }

      buffer.write(char);
    }

    return buffer.toString();
  }

  /// 查找下一个非空白字符
  String? _findNextNonWhitespace(String json, int startIndex) {
    for (int i = startIndex; i < json.length; i++) {
      final char = json[i];
      if (char != ' ' && char != '\n' && char != '\r' && char != '\t') {
        return char;
      }
    }
    return null;
  }

  Future<String> _generateFinalAnswer(
    String userMessage,
    List<ReActStep> steps,
    List<Note> referencedNotes,
    String? replyLanguage,
    CancellationToken? cancellationToken,
  ) async {
    final notesContext = referencedNotes.isNotEmpty
        ? referencedNotes
              .map(
                (note) =>
                    '笔记标题：${note.title}\n笔记内容：${note.content.length > 500 ? '${note.content.substring(0, 500)}...' : note.content}',
              )
              .join('\n\n')
        : '';

    final now = DateTime.now();
    const weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final currentDatetime =
        '${now.year}年${now.month}月${now.day}日 '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} '
        '${weekdays[now.weekday - 1]}';

    final prompt =
        '''
你是OpenNote智能笔记软件的一个智能笔记助手 Cici，你的中文名字叫茜茜。

## 语言要求
${_getLanguagePromptFor(replyLanguage)}

## 当前时间
$currentDatetime

## 用户需求
$userMessage

## 执行过程
${steps.map((s) => '${s.thought}\n${s.tool != null ? '调用工具: ${s.tool} (${s.observation?.message ?? "无结果"})' : ''}').join('\n\n')}

## 相关笔记
$notesContext

请用简洁、专业、自然的语气回复用户。如果引用了笔记内容，请在回复中适当引用原文片段。如果找不到相关信息，请坦诚告知用户。
''';

    try {
      String response = '';
      await for (final chunk in _aiService.callAIStream(
        prompt,
        cancellationToken: cancellationToken,
      )) {
        cancellationToken?.throwIfCancelled();
        if (chunk.content != null) {
          response += chunk.content!;
        }
      }
      return response;
    } on OperationCancelledException {
      debugPrint('[ReAct] 最终回答生成被取消');
      return '操作已被用户中断';
    } catch (e) {
      debugPrint('生成最终回答失败: $e');
      return '抱歉，处理您的请求时发生了错误。';
    }
  }

  List<String> _extractKeywords(String userMessage) {
    final keywords = <String>[];
    final words = userMessage.split(
      RegExp(
        r'[\s,，。！？、；：""'
        '()（）[]【】]+',
      ),
    );
    for (final word in words) {
      if (word.length >= 2 && word.length <= 10) {
        keywords.add(word);
      }
    }
    return keywords.take(5).toList();
  }

  String _getUserLanguageInstruction() {
    switch (_userLanguage) {
      case AppLocale.zh:
        return '请始终使用简体中文与用户交流。';
      case AppLocale.zhTw:
        return '請始終使用繁體中文與用戶交流。';
      case AppLocale.en:
        return 'Always communicate with the user in English.';
      case AppLocale.ru:
        return 'Всегда общайтесь с пользователем на русском языке.';
    }
  }

  /// Get language prompt based on AI-determined reply language (from first layer)
  /// Falls back to system setting if replyLanguage is null
  String _getLanguagePromptFor(String? replyLanguage) {
    return replyLanguage ?? _getUserLanguageInstruction();
  }
}
