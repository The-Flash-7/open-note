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

  /// 预处理对话上下文：过滤无关内容，增强相关内容，节约 token
  Future<String> _preprocessContext(
    String userMessage,
    String originalContext,
    void Function(String thinking) onThinking,
    CancellationToken? cancellationToken,
  ) async {
    if (originalContext.isEmpty || originalContext == '无') {
      return originalContext;
    }

    final preprocessStartTime = DateTime.now().millisecondsSinceEpoch;
    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('【预处理】开始处理对话上下文');
    debugPrint('════════════════════════════════════════════════════════════');

    // 在界面上显示预处理开始
    onThinking('正在分析对话历史，提取关键信息...');

    final prompt = ReactPrompt.buildContextPreprocessPrompt(
      userQuery: userMessage,
      originalContext: originalContext,
    );

    try {
      final result = await _callAIWithTokenTracking(
        prompt,
        onThinking: onThinking,
        cancellationToken: cancellationToken,
      );
      final processedContext = result.response;

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

      final originalLength = originalContext.length;
      final processedLength = processedContext.length;
      final compressionRatio = originalLength > 0
          ? ((originalLength - processedLength) / originalLength * 100).toStringAsFixed(1)
          : '0.0';

      debugPrint('【预处理】完成，耗时: ${preprocessDuration}ms');
      debugPrint('【预处理】Token: prompt=${pTok ?? "N/A"}, completion=${cTok ?? "N/A"}, total=${tTok ?? "N/A"}');
      debugPrint('【预处理】压缩效果: $originalLength字符 → $processedLength字符 (压缩$compressionRatio%)');
      debugPrint('════════════════════════════════════════════════════════════');

      return processedContext;
    } catch (e) {
      debugPrint('【预处理】失败: $e，使用原始上下文');
      return originalContext;
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

      // 初始化 relevantNotes 为向量预检索结果
      final vectorStartTime = DateTime.now().millisecondsSinceEpoch;
      final initialResults = await _vectorStore.search(userMessage, topK: 3);
      final vectorEndTime = DateTime.now().millisecondsSinceEpoch;
      final vectorDuration = vectorEndTime - vectorStartTime;
      debugPrint('【向量搜索】耗时: ${vectorDuration}ms, 结果数: ${initialResults.length}');
      
      for (final r in initialResults) {
        final note = await OpenNoteTools.getNoteById(r.noteId);
        if (note != null) relevantNotes.add(note);
      }
      // 给AI参考的笔记上下文（动态更新）
      String relevantNotesContext = _buildRelevantNotesContext(relevantNotes);

      // 构建当前打开的笔记上下文
      String currentNoteContext = _buildCurrentNoteContext(currentNote);

      // 预处理对话上下文（在循环之前，只执行一次）
      final originalHistoryContext = history
          .map((m) {
            return '${m['role']}: ${m['content']}';
          })
          .join('\n');
      final processedHistoryContext = await _preprocessContext(
        userMessage,
        originalHistoryContext,
        onThinking,
        cancellationToken,
      );

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
}
