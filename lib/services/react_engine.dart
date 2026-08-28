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
import 'skills/parameter_dependency_graph.dart';
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
  final ParameterDependencyGraph _dependencyGraph = ParameterDependencyGraph();
  AppLocale _userLanguage;
  static const int maxSteps = 10;
  static const int maxRetries = 2;

  // 系统提示（静态规则）
  late final String _systemPrompt;

  // Token 统计
  int _totalPromptTokens = 0;
  int _totalCompletionTokens = 0;
  int _totalTokens = 0;

  // 快速决策缓存（问候/闲聊）
  static final Map<String, String> _greetingCache = {};
  static const int _maxCacheSize = 20;

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
       _userLanguage = userLanguage {
    _systemPrompt = ReactPrompt.systemPrompt;
  }

  set userLanguage(AppLocale locale) => _userLanguage = locale;

  /// 调用 AI 流式接口并统计 token
  Future<({String response, int? promptTokens, int? completionTokens, int? totalTokens})>
      _callAIWithTokenTracking(
    String prompt, {
    String? systemPrompt,
    void Function(String thinking)? onThinking,
    CancellationToken? cancellationToken,
  }) async {
    String response = '';
    String thinkingBuffer = '';
    int? promptTokens;
    int? completionTokens;
    int? totalTokens;

    await for (final chunk in _aiService.callAIStream(
      prompt,
      systemPrompt: systemPrompt,
      cancellationToken: cancellationToken,
    )) {
      cancellationToken?.throwIfCancelled();
      if (chunk.thinking != null) {
        thinkingBuffer += chunk.thinking!;
        if (onThinking != null && thinkingBuffer.length >= 12) {
          onThinking(thinkingBuffer);
        }
      }
      if (chunk.content != null) {
        response += chunk.content!;
      }
      if (chunk.totalTokens != null) {
        promptTokens = chunk.promptTokens;
        completionTokens = chunk.completionTokens;
        totalTokens = chunk.totalTokens;
      }
    }

    return (
      response: response,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
    );
  }

  /// 判断是否需要执行预处理
  bool _shouldPreprocess({required String originalHistoryContext}) {
    // 对话上下文长度 ≥ 2500 → 执行预处理
    if (originalHistoryContext.length >= 2500) {
      debugPrint('【预处理判断】对话上下文长度 ${originalHistoryContext.length} ≥ 2500，需要预处理');
      return true;
    }

    debugPrint('【预处理判断】对话上下文长度 ${originalHistoryContext.length} < 2500，跳过预处理');
    return false;
  }

  /// 预处理对话上下文：仅对早期对话进行AI压缩，近期对话（最近2轮）原样保留
  Future<String> _preprocessContext(
    String userMessage,
    String earlyContext,
    String recentContext,
    void Function(String thinking) onThinking,
    CancellationToken? cancellationToken,
  ) async {
    // 无早期对话 → 无需压缩，直接返回近期对话
    if (earlyContext.isEmpty || earlyContext == '无') {
      debugPrint('【预处理】无早期对话，跳过AI压缩，直接返回近期对话');
      return recentContext;
    }

    final preprocessStartTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('【预处理】开始压缩早期对话上下文');
    debugPrint('════════════════════════════════════════════════════════════');

    // 在界面上显示预处理开始
    onThinking('正在分析对话历史，提取关键信息...');

    final prompt = ReactPrompt.buildContextPreprocessPrompt(
      userQuery: userMessage,
      originalContext: earlyContext,
    );

    try {
      final result = await _callAIWithTokenTracking(
        prompt,
        onThinking: onThinking,
        cancellationToken: cancellationToken,
      );
      final compressedEarly = result.response;

      final preprocessEndTime = DateTime.now().millisecondsSinceEpoch;
      final preprocessDuration = preprocessEndTime - preprocessStartTime;

      final pTok = result.promptTokens;
      final cTok = result.completionTokens;
      final tTok = result.totalTokens;
      if (tTok != null) {
        _totalPromptTokens += pTok ?? 0;
        _totalCompletionTokens += cTok ?? 0;
        _totalTokens += tTok;
      }

      final earlyLength = earlyContext.length;
      final compressedLength = compressedEarly.length;
      final compressionRatio = earlyLength > 0
          ? ((earlyLength - compressedLength) / earlyLength * 100).toStringAsFixed(1)
          : '0.0';

      debugPrint('【预处理】完成，耗时: ${preprocessDuration}ms');
      debugPrint('【预处理】Token: prompt=${pTok ?? "N/A"}, completion=${cTok ?? "N/A"}, total=${tTok ?? "N/A"}');
      debugPrint('【预处理】压缩效果: 早期$earlyLength字符 → 压缩后$compressedLength字符 (压缩$compressionRatio%) + 近期${recentContext.length}字符');
      debugPrint('════════════════════════════════════════════════════════════');

      // 拼接压缩后的早期对话与近期对话，作为最终预处理结果
      if (recentContext.isEmpty) {
        return compressedEarly;
      }
      return '$compressedEarly\n$recentContext';
    } catch (e) {
      debugPrint('【预处理】失败: $e，使用原始上下文（早期原文 + 近期原文）');
      if (recentContext.isEmpty) {
        return earlyContext;
      }
      return '$earlyContext\n$recentContext';
    }
  }

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

    String processedHistoryContext = '';

    // 重置 token 统计
    _totalPromptTokens = 0;
    _totalCompletionTokens = 0;
    _totalTokens = 0;

    int totalStartTime = 0;
    try {
      totalStartTime = DateTime.now().millisecondsSinceEpoch;
      debugPrint('════════════════════════════════════════════════════════════');
      debugPrint('【ReAct 引擎启动】时间: ${DateTime.now().toString().split('.').first}');
      debugPrint('════════════════════════════════════════════════════════════');

      // 构建原始对话上下文（用于预处理）
      final originalHistoryContext = history
          .map((m) {
            return '${m['role']}: ${m['content']}';
          })
          .join('\n');

      // 拆分历史对话：近期 = 最近1轮（2条记录），早期 = 其余更早记录
      // （提前拆分：供快速决策复用 recentContext，预处理复用 earlyContext/recentContext）
      final splitIndex = history.length > 2 ? history.length - 2 : 0;
      final earlyHistory = history.sublist(0, splitIndex);
      final recentHistory = history.sublist(splitIndex);
      final earlyContext = earlyHistory
          .map((m) {
            return '${m['role']}: ${m['content']}';
          })
          .join('\n');
      final recentContext = recentHistory
          .map((m) {
            return '${m['role']}: ${m['content']}';
          })
          .join('\n');

      // ========== 快速决策：识别简单闲聊 ==========
      final quickDecision = await _quickDecision(
        userMessage,
        recentContext,
        cancellationToken,
      );

      if (quickDecision != null) {
        final type = quickDecision.type;

        // 类型1：直接回复
        if (type == 1 && quickDecision.result != null) {
          final totalEndTime = DateTime.now().millisecondsSinceEpoch;
          final totalDuration = totalEndTime - totalStartTime;

          debugPrint('════════════════════════════════════════════════════════════');
          debugPrint('【ReAct 引擎结束】快速决策路径（类型1），总耗时: ${totalDuration}ms');
          debugPrint('════════════════════════════════════════════════════════════');

          return quickDecision.result!;
        }

        // 类型2：跳过向量检索
        if (type == 2) {
          debugPrint('【快速决策】类型2：跳过向量检索，直接进入预处理');
          // 不执行向量检索，relevantNotes 保持为空列表
        }

        // 类型3：需要向量检索
        if (type == 3) {
          debugPrint('【快速决策】类型3：执行向量检索');
          // 执行向量检索
          final vectorStartTime = DateTime.now().millisecondsSinceEpoch;
          final initialResults = await _vectorStore.search(userMessage, topK: 3);
          final vectorEndTime = DateTime.now().millisecondsSinceEpoch;
          final vectorDuration = vectorEndTime - vectorStartTime;
          debugPrint('【向量搜索】耗时: ${vectorDuration}ms, 结果数: ${initialResults.length}');
          
          for (final r in initialResults) {
            final note = await OpenNoteTools.getNoteById(r.noteId);
            if (note != null) relevantNotes.add(note);
          }
        }
      } else {
        // 快速决策失败，执行默认的向量检索
        debugPrint('【快速决策】失败，执行默认向量检索');
        final vectorStartTime = DateTime.now().millisecondsSinceEpoch;
        final initialResults = await _vectorStore.search(userMessage, topK: 3);
        final vectorEndTime = DateTime.now().millisecondsSinceEpoch;
        final vectorDuration = vectorEndTime - vectorStartTime;
        debugPrint('【向量搜索】耗时: ${vectorDuration}ms, 结果数: ${initialResults.length}');
        
        for (final r in initialResults) {
          final note = await OpenNoteTools.getNoteById(r.noteId);
          if (note != null) relevantNotes.add(note);
        }
      }
      // ========== 快速决策结束 ==========

      // 给AI参考的笔记上下文（动态更新）
      String relevantNotesContext = _buildRelevantNotesContext(relevantNotes);

      // 构建当前打开的笔记上下文
      String currentNoteContext = _buildCurrentNoteContext(currentNote);

      // 初始化处理后的上下文为原始上下文（预处理可能按需执行）
      processedHistoryContext = originalHistoryContext;

      // 预处理对话上下文（在循环之前，只执行一次，按长度条件判断）
      // 复用前面已拆分好的 earlyContext / recentContext
      if (_shouldPreprocess(originalHistoryContext: originalHistoryContext)) {
        debugPrint('【预处理】开始执行预处理（长度条件触发）');
        try {
          processedHistoryContext = await _preprocessContext(
            userMessage,
            earlyContext,
            recentContext,
            onThinking,
            cancellationToken,
          );
        } catch (e) {
          debugPrint('【预处理】执行失败: $e，使用原始上下文');
          processedHistoryContext = originalHistoryContext;
        }
      } else {
        debugPrint('【预处理】跳过预处理（对话历史较短）');
      }

      String? replyLanguage;

      for (int i = 0; i < maxSteps; i++) {
        cancellationToken?.throwIfCancelled();

        final loopStartTime = DateTime.now().millisecondsSinceEpoch;
        debugPrint('════════════════════════════════════════════════════════════');
        debugPrint('【循环 $i 开始】时间: ${DateTime.now().toString().split('.').first}');
        debugPrint('════════════════════════════════════════════════════════════');

        onStepUpdate('thinking', '', '第 ${i + 1} 步推理中...');

        // 阶段1：工具选择
        final stage1StartTime = DateTime.now().millisecondsSinceEpoch;
        final toolSelection = await _selectTool(
          userMessage,
          processedHistoryContext,
          steps,
          onThinking,
          cancellationToken,
        );
        final stage1EndTime = DateTime.now().millisecondsSinceEpoch;
        final stage1Duration = stage1EndTime - stage1StartTime;

        cancellationToken?.throwIfCancelled();

        if (toolSelection == null) {
          debugPrint('【循环 $i 结束】阶段1返回null，耗时: ${stage1Duration}ms');
          continue;
        }

        final selectedTool = toolSelection['selected_tool'] as String? ?? '';
        debugPrint('【阶段1 完成】工具选择: ${selectedTool.isEmpty ? "无" : selectedTool}, 耗时: ${stage1Duration}ms');

        // 不判断 selectedTool 是否为空，直接进入阶段2
        // 阶段2：推理 + 参数填充 + 判断是否结束
        final stage2StartTime = DateTime.now().millisecondsSinceEpoch;
        final thoughtWhenSelected = toolSelection['thought'] as String? ?? '';
        final decision = await _fillToolArgsAndDecide(
          selectedTool,
          thoughtWhenSelected,
          userMessage,
          processedHistoryContext,
          steps,
          relevantNotesContext,
          currentNoteContext,
          onThinking,
          cancellationToken,
        );
        final stage2EndTime = DateTime.now().millisecondsSinceEpoch;
        final stage2Duration = stage2EndTime - stage2StartTime;

        cancellationToken?.throwIfCancelled();

        debugPrint('【阶段2 完成】推理+参数填充, 耗时: ${stage2Duration}ms');

        // 判断阶段2的输出
        if (decision['action'] == 'parse_error') {
          // JSON 解析失败，继续下一轮循环
          debugPrint('【循环 $i 结束】阶段2 JSON解析失败，耗时: ${stage2Duration}ms');
          continue;
        }
        
        if (decision['action'] == 'done') {
          // AI 判断任务完成（可能是纯聊天，也可能是已完成所有工具调用）
          final finalAnswer = decision['final_answer'] as String? ?? '抱歉，我未能完成您的需求。';
          final replyLanguage = decision['reply_language'] as String?;
          final citationNoteIds = (decision['citation_note_ids'] as List?)?.cast<String>() ?? [];
          
          final loopEndTime = DateTime.now().millisecondsSinceEpoch;
          final loopDuration = loopEndTime - loopStartTime;
          final totalEndTime = DateTime.now().millisecondsSinceEpoch;
          final totalDuration = totalEndTime - totalStartTime;
          debugPrint('════════════════════════════════════════════════════════════');
          debugPrint('【循环 $i 结束】任务完成，总耗时: ${loopDuration}ms');
          debugPrint('  - 阶段1耗时: ${stage1Duration}ms');
          debugPrint('  - 阶段2耗时: ${stage2Duration}ms');
          debugPrint('════════════════════════════════════════════════════════════');
          debugPrint('【ReAct 引擎结束】总耗时: ${totalDuration}ms');
          debugPrint('╔══════════════════════════════════════════════════════════╗');
          debugPrint('║  Token 汇总');
          debugPrint('║  - Prompt tokens:     $_totalPromptTokens');
          debugPrint('║  - Completion tokens: $_totalCompletionTokens');
          debugPrint('║  - Total tokens:      $_totalTokens');
          debugPrint('║  - AI 调用次数:       ${steps.length * 2} (阶段1+阶段2 per loop)');
          debugPrint('╚══════════════════════════════════════════════════════════╝');
          debugPrint('════════════════════════════════════════════════════════════');

          return ReActResult(
            steps: steps,
            finalAnswer: finalAnswer,
            referencedNotes: finalCitationNote(relevantNotes, citationNoteIds),
            toolCalls: allToolCalls,
            replyLanguage: replyLanguage,
          );
        }

        // action == "tool_call"，执行工具
        final args = (decision['args'] as Map?)?.cast<String, dynamic>() ?? {};
        final relevantNoteIds = (decision['relevant_note_ids'] as List?)?.cast<String>() ?? [];
        
        onStepUpdate('tool_call', selectedTool, '正在调用...', args: args);

        final toolCall = ToolCall(tool: selectedTool, args: args);
        allToolCalls.add(toolCall);

        SkillResult? result;
        bool success = false;

        final toolStartTime = DateTime.now().millisecondsSinceEpoch;
        for (int attempt = 0; attempt <= maxRetries; attempt++) {
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
            debugPrint('工具 $selectedTool 执行异常 (尝试 ${attempt + 1}/$maxRetries): $e');
          }

          if (success) {
            break;
          }

          if (attempt < maxRetries) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
        final toolEndTime = DateTime.now().millisecondsSinceEpoch;
        final toolDuration = toolEndTime - toolStartTime;

        debugPrint('【工具执行完成】$selectedTool, 成功: $success, 耗时: ${toolDuration}ms');

        cancellationToken?.throwIfCancelled();

        final step = ReActStep(
          thought: decision['thought'] as String? ?? '',
          tool: selectedTool,
          args: args,
          observation: result,
        );
        steps.add(step);

        if (result?.referencedNotes.isNotEmpty == true) {
          final retainedNotes = <Note>[];
          for (final note in relevantNotes) {
            if (relevantNoteIds.contains(note.id)) {
              retainedNotes.add(note);
            } else {
              discardSet.add(note.id);
            }
          }

          final filteredNewNotes = <Note>[];
          for (final note in result!.referencedNotes) {
            if (!discardSet.contains(note.id)) {
              filteredNewNotes.add(note);
            }
          }

          final existingIds = retainedNotes.map((n) => n.id).toSet();
          for (final note in filteredNewNotes) {
            if (!existingIds.contains(note.id)) {
              retainedNotes.add(note);
            }
          }

          relevantNotes = retainedNotes;
        }

        relevantNotesContext = _buildRelevantNotesContext(relevantNotes);

        onStepUpdate(
          'tool_result',
          selectedTool,
          success ? '成功' : '失败: ${result?.message ?? "未知错误"}',
          args: args,
          resultData: success ? result?.toJson() : null,
        );

        if (selectedTool == 'note_open' && success) {
          return ReActResult(
            steps: steps,
            finalAnswer: result?.message ?? '',
            referencedNotes: relevantNotes,
            toolCalls: allToolCalls,
          );
        }

        if (!success && i < maxSteps - 1) {
          continue;
        }
      }

      // 超出最大步数，让 AI 生成最终回答
      // 注意：此时没有从 AI 获取 replyLanguage，使用 null 让 _generateFinalAnswer 回退到系统设置
      final totalEndTime = DateTime.now().millisecondsSinceEpoch;
      final totalDuration = totalEndTime - totalStartTime;
      debugPrint('════════════════════════════════════════════════════════════');
      debugPrint('【ReAct 引擎结束】超出最大步数，总耗时: ${totalDuration}ms');
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║  Token 汇总');
      debugPrint('║  - Prompt tokens:     $_totalPromptTokens');
      debugPrint('║  - Completion tokens: $_totalCompletionTokens');
      debugPrint('║  - Total tokens:      $_totalTokens');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('════════════════════════════════════════════════════════════');
      
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
      final totalEndTime = DateTime.now().millisecondsSinceEpoch;
      final totalDuration = totalEndTime - totalStartTime;
      debugPrint('════════════════════════════════════════════════════════════');
      debugPrint('【ReAct 引擎结束】用户中断，总耗时: ${totalDuration}ms');
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║  Token 汇总');
      debugPrint('║  - Prompt tokens:     $_totalPromptTokens');
      debugPrint('║  - Completion tokens: $_totalCompletionTokens');
      debugPrint('║  - Total tokens:      $_totalTokens');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('════════════════════════════════════════════════════════════');
      return ReActResult(
        steps: steps,
        finalAnswer: '操作已被用户中断',
        referencedNotes: relevantNotes,
        toolCalls: allToolCalls,
      );
    } catch (e) {
      final totalEndTime = DateTime.now().millisecondsSinceEpoch;
      final totalDuration = totalEndTime - totalStartTime;
      debugPrint('════════════════════════════════════════════════════════════');
      debugPrint('【ReAct 引擎异常】总耗时: ${totalDuration}ms, 错误: $e');
      debugPrint('╔══════════════════════════════════════════════════════════╗');
      debugPrint('║  Token 汇总');
      debugPrint('║  - Prompt tokens:     $_totalPromptTokens');
      debugPrint('║  - Completion tokens: $_totalCompletionTokens');
      debugPrint('║  - Total tokens:      $_totalTokens');
      debugPrint('╚══════════════════════════════════════════════════════════╝');
      debugPrint('════════════════════════════════════════════════════════════');
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

  Future<Map<String, dynamic>?> _selectTool(
    String userMessage,
    String processedContext,
    List<ReActStep> steps,
    void Function(String thinking) onThinking,
    CancellationToken? cancellationToken,
  ) async {
    final toolSummaries = _skillRegistry.generateToolSummariesPrompt();
    final toolRequirements = _skillRegistry.generateToolRequirementsPrompt();
    final knownParams = _extractKnownParameters(steps);
    final dependencyTable = _dependencyGraph.generateDependencyTable(steps);

    debugPrint('──────────────────────────────────────────────────────────');
    debugPrint('【阶段1 准备】已知参数：${_formatKnownParameters(knownParams)}');
    debugPrint('【阶段1 准备】依赖关系表：$dependencyTable');
    debugPrint('──────────────────────────────────────────────────────────');

    int stepIndex = 0;
    final previousSteps = steps
        .map((s) {
          stepIndex += 1;
          final buffer = StringBuffer();
          buffer.writeln('【步骤$stepIndex】');
          buffer.writeln('工具: ${s.tool}');
          buffer.writeln('参数: ${jsonEncode(s.args)}');
          buffer.writeln('结果: ${s.observation?.message ?? "无结果"}');
          return buffer.toString();
        })
        .join('\n');

    final prompt = ReactPrompt.buildToolSelectionPrompt(
      userQuery: userMessage,
      knownParameters: _formatKnownParameters(knownParams),
      dependencyTable: dependencyTable,
      toolSummaries: toolSummaries,
      toolRequirements: toolRequirements,
      previousSteps: previousSteps,
      context: processedContext,
    );

    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('【阶段1：工具选择】提示词');
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint(prompt);
    debugPrint('════════════════════════════════════════════════════════════');

    try {
      final aiStartTime = DateTime.now().millisecondsSinceEpoch;

      final result = await _callAIWithTokenTracking(
        prompt,
        onThinking: onThinking,
        cancellationToken: cancellationToken,
      );
      final responseBuffer = result.response;

      final aiEndTime = DateTime.now().millisecondsSinceEpoch;
      final aiDuration = aiEndTime - aiStartTime;

      final decision = _parseThoughtResponse(responseBuffer);

      // 累计 token
      final pTok = result.promptTokens;
      final cTok = result.completionTokens;
      final tTok = result.totalTokens;
      if (tTok != null) {
        _totalPromptTokens += pTok ?? 0;
        _totalCompletionTokens += cTok ?? 0;
        _totalTokens += tTok;
      }

      debugPrint('【阶段1：工具选择】AI 响应耗时: ${aiDuration}ms, '
          'prompt_tokens: ${pTok ?? "N/A"}, '
          'completion_tokens: ${cTok ?? "N/A"}, '
          'total_tokens: ${tTok ?? "N/A"}');
      debugPrint('【阶段1：工具选择】AI 响应：$responseBuffer');
      debugPrint('【阶段1：工具选择】解析结果：$decision');

      return decision;
    } catch (e) {
      debugPrint('工具选择失败: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _fillToolArgsAndDecide(
    String selectedTool,
    String thoughtWhenSelected,
    String userMessage,
    String processedContext,
    List<ReActStep> steps,
    String relevantNotesContext,
    String currentNoteContext,
    void Function(String thinking) onThinking,
    CancellationToken? cancellationToken,
  ) async {
    final toolDefinition = selectedTool.isEmpty 
        ? null 
        : _skillRegistry.getSkill(selectedTool)!.toToolDefinition();
    final knownParams = _extractKnownParameters(steps);
    final candidateValues = _extractCandidateValues(selectedTool, steps);

    debugPrint('──────────────────────────────────────────────────────────');
    debugPrint('【阶段2 准备】工具：${selectedTool.isEmpty ? "无" : selectedTool}');
    debugPrint('【阶段2 准备】已知参数：${_formatKnownParameters(knownParams)}');
    debugPrint('【阶段2 准备】候选参数值：${_formatCandidateValues(candidateValues)}');
    debugPrint('──────────────────────────────────────────────────────────');

    int stepIndex = 0;
    final previousSteps = steps
        .map((s) {
          stepIndex += 1;
          final buffer = StringBuffer();
          buffer.writeln('【步骤$stepIndex】');
          buffer.writeln('工具: ${s.tool}');
          buffer.writeln('参数: ${jsonEncode(s.args)}');
          buffer.writeln('结果: ${s.observation?.message ?? "无结果"}');
          return buffer.toString();
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

    final prompt = ReactPrompt.buildArgFillingPrompt(
      selectedTool: selectedTool,
      thoughtWhenSelected: thoughtWhenSelected,
      toolDefinition: toolDefinition != null ? jsonEncode(toolDefinition) : null,
      userQuery: userMessage,
      currentDatetime: currentDatetime,
      userLanguageInstruction: _getUserLanguageInstruction(),
      userMemories: userMemoriesText,
      experienceTips: experienceTipsText,
      context: processedContext,
      relevantNotesContext: relevantNotesContext,
      currentNoteContext: currentNoteContext,
      previousSteps: previousSteps,
      knownParameters: _formatKnownParameters(knownParams),
      candidateValues: _formatCandidateValues(candidateValues),
    );

    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('【阶段2：推理+参数填充】提示词');
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint(prompt);
    debugPrint('════════════════════════════════════════════════════════════');

    try {
      final aiStartTime = DateTime.now().millisecondsSinceEpoch;

      final result = await _callAIWithTokenTracking(
        prompt,
        systemPrompt: _systemPrompt,
        onThinking: onThinking,
        cancellationToken: cancellationToken,
      );
      final response = result.response;

      final aiEndTime = DateTime.now().millisecondsSinceEpoch;
      final aiDuration = aiEndTime - aiStartTime;

      final parsed = _parseThoughtResponse(response);

      // 累计 token
      final pTok = result.promptTokens;
      final cTok = result.completionTokens;
      final tTok = result.totalTokens;
      if (tTok != null) {
        _totalPromptTokens += pTok ?? 0;
        _totalCompletionTokens += cTok ?? 0;
        _totalTokens += tTok;
      }

      debugPrint('【阶段2：推理+参数填充】AI 响应耗时: ${aiDuration}ms, '
          'prompt_tokens: ${pTok ?? "N/A"}, '
          'completion_tokens: ${cTok ?? "N/A"}, '
          'total_tokens: ${tTok ?? "N/A"}');
      debugPrint('【阶段2：推理+参数填充】AI 响应：$response');
      debugPrint('【阶段2：推理+参数填充】解析结果：$parsed');

      return parsed ?? {};
    } catch (e) {
      debugPrint('参数填充失败: $e');
      return {};
    }
  }

  Map<String, dynamic> _extractKnownParameters(List<ReActStep> steps) {
    final knownParams = <String, dynamic>{};

    for (final step in steps) {
      if (step.observation?.referencedNotes.isNotEmpty == true) {
        final noteIds = step.observation!.referencedNotes.map((n) => n.id).toList();
        if (knownParams.containsKey('note_id')) {
          final existing = knownParams['note_id'] as List;
          for (final id in noteIds) {
            if (!existing.contains(id)) {
              existing.add(id);
            }
          }
        } else {
          knownParams['note_id'] = noteIds;
        }
      }

      if (step.observation?.metadata?['categories'] != null) {
        final categories = step.observation!.metadata!['categories'] as List;
        if (knownParams.containsKey('category_id')) {
          final existing = knownParams['category_id'] as List;
          for (final cat in categories) {
            if (!existing.contains(cat)) {
              existing.add(cat);
            }
          }
        } else {
          knownParams['category_id'] = categories;
        }
      }
    }

    return knownParams;
  }

  Map<String, List<String>> _extractCandidateValues(
    String toolName,
    List<ReActStep> steps,
  ) {
    final candidates = <String, List<String>>{};
    final skill = _skillRegistry.getSkill(toolName);

    if (skill == null) return candidates;

    for (final param in skill.parameters) {
      if (!param.required) continue;

      if (param.name == 'note_id') {
        final noteIds = <String>[];
        for (final step in steps) {
          if (step.observation?.referencedNotes.isNotEmpty == true) {
            noteIds.addAll(step.observation!.referencedNotes.map((n) => n.id));
          }
        }
        if (noteIds.isNotEmpty) {
          candidates['note_id'] = noteIds;
        }
      }

      if (param.name == 'category_id') {
        final categoryIds = <String>[];
        for (final step in steps) {
          if (step.observation?.metadata?['categories'] != null) {
            final categories = step.observation!.metadata!['categories'] as List;
            for (final cat in categories) {
              if (cat is Map && cat.containsKey('id')) {
                categoryIds.add(cat['id'] as String);
              }
            }
          }
        }
        if (categoryIds.isNotEmpty) {
          candidates['category_id'] = categoryIds;
        }
      }
    }

    return candidates;
  }

  String _formatKnownParameters(Map<String, dynamic> knownParams) {
    if (knownParams.isEmpty) return '（无）';

    final buffer = StringBuffer();
    for (final entry in knownParams.entries) {
      if (entry.value is List) {
        buffer.writeln('- ${entry.key}: ${(entry.value as List).join(", ")}');
      } else {
        buffer.writeln('- ${entry.key}: ${entry.value}');
      }
    }
    return buffer.toString().trim();
  }

  String _formatCandidateValues(Map<String, List<String>> candidates) {
    if (candidates.isEmpty) return '（无）';

    final buffer = StringBuffer();
    for (final entry in candidates.entries) {
      buffer.writeln('- ${entry.key} 可选值：');
      for (final value in entry.value) {
        buffer.writeln('  * $value');
      }
    }
    return buffer.toString().trim();
  }

  Map<String, dynamic>? _parseThoughtResponse(String response) {
    try {
      String cleaned = response.trim();
      
      // 尝试提取 JSON 片段（处理 AI 在 JSON 前后添加文本的情况）
      if (!cleaned.startsWith('{')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end > start) {
          cleaned = cleaned.substring(start, end + 1);
        }
      }
      
      // 原有的清理逻辑
      if (cleaned.contains('```json')) {
        final start = cleaned.indexOf('```json') + 7;
        final end = cleaned.indexOf('```', start);
        cleaned = cleaned.substring(start, end).trim();
      } else if (cleaned.contains('```')) {
        final start = cleaned.indexOf('```') + 3;
        final end = cleaned.indexOf('```', start);
        cleaned = cleaned.substring(start, end).trim();
      }

      // 预处理：修复 JSON 字符串值内部未转义的引号和反引号
      cleaned = _fixUnescapedQuotes(cleaned);

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('解析思考响应失败: $e, 原始响应: $response');
      // 如果解析失败，返回 parse_error 状态
      return {
        'thought': 'JSON 解析失败',
        'action': 'parse_error',
        'raw_response': response,
        'error': e.toString(),
      };
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

  /// 快速决策：判断用户意图类型
  /// 返回 null 表示解析失败，继续原有流程
  /// 返回 (type, result) 表示决策成功：
  ///   - type=1: 直接回复（闲聊），result 包含回复内容
  ///   - type=2: 跳过向量检索，进入ReAct
  ///   - type=3: 需要向量检索，然后进入ReAct
  Future<({int type, ReActResult? result})?> _quickDecision(
    String userMessage,
    String recentContext,
    CancellationToken? cancellationToken,
  ) async {
    final decisionStartTime = DateTime.now().millisecondsSinceEpoch;

    // 1. 检查缓存
    final normalizedMessage = userMessage.trim().toLowerCase();
    if (_greetingCache.containsKey(normalizedMessage)) {
      final cachedReply = _greetingCache[normalizedMessage]!;
      final decisionEndTime = DateTime.now().millisecondsSinceEpoch;

      debugPrint('【快速决策】命中缓存，耗时: ${decisionEndTime - decisionStartTime}ms');

      return (
        type: 1,
        result: ReActResult(
          steps: [
            ReActStep(thought: '快速决策：命中缓存，直接回复'),
          ],
          finalAnswer: cachedReply,
          replyLanguage: _detectReplyLanguage(cachedReply),
        ),
      );
    }

    // 2. 构建快速决策prompt（带最近对话上下文，截断保护：最多取尾部1500字符）
    final recentForDecision = recentContext.length > 1500
        ? recentContext.substring(recentContext.length - 1500)
        : recentContext;
    final prompt = ReactPrompt.quickDecisionPrompt
        .replaceAll('{user_language_instruction}', _getUserLanguageInstruction())
        .replaceAll('{recent_context}', recentForDecision.isEmpty ? '无' : recentForDecision)
        .replaceAll('{user_message}', userMessage);

    // 3. 调用AI（极简配置）
    String aiResponse = '';

    try {
      await for (final chunk in _aiService.callAIStream(
        prompt,
        cancellationToken: cancellationToken,
      )) {
        cancellationToken?.throwIfCancelled();
        if (chunk.content != null) {
          aiResponse += chunk.content!;
        }
      }

      final decisionEndTime = DateTime.now().millisecondsSinceEpoch;
      debugPrint('【快速决策】AI耗时: ${decisionEndTime - decisionStartTime}ms');
      debugPrint('【快速决策】AI响应: $aiResponse');

      // 4. 解析响应
      final parsed = _parseQuickDecision(aiResponse);

      if (parsed == null) {
        debugPrint('【快速决策】解析失败，继续原有流程');
        return null;
      }

      final type = parsed['type'] as int;
      final reply = parsed['reply'] as String;

      debugPrint('【快速决策】类型: $type, 回复: $reply');

      // 5. 类型1：直接回复
      if (type == 1) {
        debugPrint('【快速决策】识别为闲聊，直接回复');

        // 添加到缓存
        _addToCache(normalizedMessage, reply);

        return (
          type: 1,
          result: ReActResult(
            steps: [
              ReActStep(thought: '快速决策：识别为闲聊，直接回复'),
            ],
            finalAnswer: reply,
            replyLanguage: _detectReplyLanguage(reply),
          ),
        );
      }

      // 6. 类型2：跳过向量检索
      if (type == 2) {
        debugPrint('【快速决策】识别为工具调用，跳过向量检索');
        return (type: 2, result: null);
      }

      // 7. 类型3：需要向量检索
      if (type == 3) {
        debugPrint('【快速决策】识别为笔记查询，需要向量检索');
        return (type: 3, result: null);
      }

      debugPrint('【快速决策】类型无效，继续原有流程');
      return null;

    } catch (e) {
      debugPrint('【快速决策】失败: $e，继续原有流程');
      return null;
    }
  }

  /// 解析快速决策响应
  Map<String, dynamic>? _parseQuickDecision(String response) {
    try {
      // 清理响应
      final cleaned = response.trim();

      // 按 || 分割
      final parts = cleaned.split('||');

      if (parts.length != 2) {
        debugPrint('【快速决策解析】格式错误：缺少分隔符 ||');
        return null;
      }

      final typeStr = parts[0].trim();
      final reply = parts[1].trim();

      // 验证类型
      final type = int.tryParse(typeStr);
      if (type == null || (type != 1 && type != 2 && type != 3)) {
        debugPrint('【快速决策解析】类型无效：$typeStr');
        return null;
      }

      return {
        'type': type,
        'reply': reply,
      };
    } catch (e) {
      debugPrint('【快速决策解析】异常: $e');
      return null;
    }
  }

  /// 添加到缓存（LRU策略）
  void _addToCache(String key, String value) {
    if (_greetingCache.containsKey(key)) {
      return; // 已存在，不重复添加
    }

    if (_greetingCache.length >= _maxCacheSize) {
      // 缓存已满，移除最早的条目（简化版LRU）
      final firstKey = _greetingCache.keys.first;
      _greetingCache.remove(firstKey);
      debugPrint('【快速决策缓存】淘汰旧条目: $firstKey');
    }

    _greetingCache[key] = value;
    debugPrint('【快速决策缓存】添加新条目: $key');
  }

  /// 检测回复语言（简单启发式）
  String? _detectReplyLanguage(String reply) {
    // 如果包含中文字符，认为是中文
    if (reply.contains(RegExp(r'[\u4e00-\u9fa5]'))) {
      return 'zh';
    }
    return 'en';
  }
}
