// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/note.dart';
import '../l10n/strings.g.dart';
import 'ai_service.dart';
import 'skills/skill_registry.dart';
import 'skills/skill_executor.dart' as skill_executor_pkg;
import 'vector_store.dart';
import 'react_engine.dart';
import 'chat_message_persistence_service.dart';
import 'memory_extractor.dart';
import '../providers/memory_settings_provider.dart';
import '../utils/cancellation_token.dart';

class CiciAgent {
  final AIService _aiService;
  final MemorySettingsProvider _memorySettings;
  final List<ChatMessage> _history = [];
  late final ReActEngine _reactEngine;
  final ChatMessagePersistenceService _persistenceService =
      ChatMessagePersistenceService();
  final MemoryExtractor _memoryExtractor = MemoryExtractor();

  CiciAgent({
    required AIService aiService,
    required SkillRegistry skillRegistry,
    required skill_executor_pkg.SkillExecutor skillExecutor,
    required VectorStore vectorStore,
    required MemorySettingsProvider memorySettings,
    required AppLocale userLanguage,
  }) : _aiService = aiService,
       _memorySettings = memorySettings {
    _reactEngine = ReActEngine(
      aiService: aiService,
      skillRegistry: skillRegistry,
      skillExecutor: skillExecutor,
      vectorStore: vectorStore,
      memorySettings: memorySettings,
      userLanguage: userLanguage,
    );
    _memoryExtractor.setSkillRegistry(skillRegistry);
  }

  set userLanguage(AppLocale locale) {
    _reactEngine.userLanguage = locale;
  }

  List<ChatMessage> get history => List.unmodifiable(_history);

  void clearHistory() {
    _history.clear();
    _memoryExtractor.resetCounter();
  }

  void addHistoryMessages(List<ChatMessage> messages) {
    _history.clear();
    _history.addAll(messages);
  }

  /// Clear history from a given index to the end (for undo/revoke)
  void clearHistoryFromIndex(int index) {
    if (index >= 0 && index < _history.length) {
      _history.removeRange(index, _history.length);
    }
  }

  void addSystemMessage(String content) {
    final message = ChatMessage.system(content);
    _history.add(message);
    _saveMessageAsync(message);
  }

  void addToolExecution(List<ToolExecutionEntry> entries) {
    final message = ChatMessage.toolExecution(entries: entries);
    _history.add(message);
    _saveMessageAsync(message);
  }

  void _saveMessageAsync(ChatMessage message) {
    _persistenceService.saveMessage(message).catchError((e) {
      debugPrint('异步保存消息失败: $e');
    });
  }

  void saveMessageToPersistence(ChatMessage message) {
    _saveMessageAsync(message);
  }

  void truncateContent(Map<String, dynamic> args) {
    if (args.containsKey('content')) {
      String original = args['content']?.toString() ?? '';
      if (original.length > 16) {
        args['content'] = '${original.substring(0, 16)}...[此处省略实际的内容]...';
      }
    }
  }

  Future<AgentResponse> chatStream(
    String message, {
    Note? currentNote,
    CancellationToken? cancellationToken,
    required void Function(String chunk) onChunk,
    required void Function(ToolExecutionEntry entry) onToolUpdate,
    required void Function(String thinking) onThinking,
  }) async {
    if (!_aiService.hasConfig()) {
      return AgentResponse.fromError('AI 服务未配置，请前往设置中配置 AI 提供商');
    }

    try {
      _history.add(ChatMessage.user(message));
      final recentHistory = _buildRecentHistory(_history, maxMessages: 20);
      final historyMaps = recentHistory.map((m) {
        String content = m.content;

        switch (m.messageType) {
          case CiciMessageType.system:
            content = '[系统消息]\n${m.content}\n[/系统消息]';
            break;
          case CiciMessageType.toolExecution:
            if (m.toolExecutions?.isNotEmpty == true) {
              final toolLogs = m.toolExecutions!
                  .map((e) {
                    final argsText = e.rawArgs != null && e.rawArgs!.isNotEmpty
                        ? ' ${e.rawArgs}'
                        : '';
                    return '• ${e.toolName}$argsText: ${e.statusLabel}';
                  })
                  .join('\n');
              content = '[工具执行记录]\n$toolLogs\n[/工具执行记录]';
            }
            break;
          case CiciMessageType.assistant:
            if (m.referencedNotes.isNotEmpty) {
              final notesInfo = m.referencedNotes
                  .map(
                    (n) =>
                        '- 笔记ID: ${n.id} | 标题: ${n.title} | 分类ID: ${n.category ?? 'null'} | 标签: ${n.tags.isEmpty ? '无' : n.tags.join(', ')}',
                  )
                  .join('\n');
              content += '\n\n[引用笔记]\n$notesInfo\n[/引用笔记]';
            }
            break;
          case CiciMessageType.user:
            // 用户消息保持不变
            break;
        }

        return {'role': m.role, 'content': content};
      }).toList();

      final result = await _reactEngine.run(
        message,
        historyMaps,
        currentNote: currentNote,
        cancellationToken: cancellationToken,
        onThinking: onThinking,
        onStepUpdate:
            (
              step,
              toolName,
              status, {
              Map<String, dynamic> args = const {},
              Map<String, dynamic>? resultData,
            }) {
              if (step == 'thinking') {
                // 推理阶段，不创建工具条目
              } else if (step == 'tool_call') {
                final details = _extractKeyArgs(toolName, args);
                final entry = ToolExecutionEntry(
                  toolId: 'exec_${DateTime.now().millisecondsSinceEpoch}',
                  toolName: toolName,
                  icon: ToolExecutionEntry.iconForTool(toolName),
                  status: ToolStatus.calling,
                  statusLabel: '正在调用 ${_getToolDisplayName(toolName)}...',
                  details: details,
                );
                onToolUpdate(entry);
              } else if (step == 'tool_result') {
                truncateContent(args);
                final entry = ToolExecutionEntry(
                  toolId: 'exec_${DateTime.now().millisecondsSinceEpoch}',
                  toolName: toolName,
                  icon: ToolExecutionEntry.iconForTool(toolName),
                  status: ToolStatus.completed,
                  statusLabel: '已调用 ${_getToolDisplayName(toolName)}',
                  details: [],
                  resultData: resultData,
                  rawArgs: jsonEncode(args),
                );
                onToolUpdate(entry);
              }
            },
      );

      // 检查是否被中断
      if (cancellationToken?.isCancelled == true) {
        return AgentResponse.cancelled();
      }

      // 流式输出最终答案
      String streamedContent = '';
      String thinkingBuffer = '';
      await for (final chunk in _aiService.callAIStream(
        '不改变任何东西，原样输出：\n${result.finalAnswer}',
        cancellationToken: cancellationToken,
      )) {
        if (cancellationToken?.isCancelled == true) {
          return AgentResponse.cancelled();
        }
        if (chunk.thinking != null) {
          thinkingBuffer += chunk.thinking!;
          if (thinkingBuffer.length >= 12) {
            onThinking(thinkingBuffer);
            thinkingBuffer = '';
          }
        }
        if (chunk.content != null) {
          streamedContent += chunk.content!;
          onChunk(streamedContent);
        }
      }

      // 构建工具调用列表
      final toolCalls = result.toolCalls
          .map((tc) => ToolCall(tool: tc.tool, args: tc.args))
          .toList();

      // 添加工具执行记录到历史（供记忆提取使用）
      if (result.steps.any((s) => s.isToolCall)) {
        final toolEntries = <ToolExecutionEntry>[];
        for (final step in result.steps.where((s) => s.isToolCall)) {
          final isSuccess = step.observation?.success ?? false;
          final resultMessage = step.observation?.message ?? '';
          final statusLabel = isSuccess
              ? '✅ 调用成功 ($resultMessage)'
              : '❌ 调用失败 ($resultMessage)';

          toolEntries.add(
            ToolExecutionEntry(
              toolId: 'exec_${DateTime.now().millisecondsSinceEpoch}',
              toolName: step.tool!,
              icon: ToolExecutionEntry.iconForTool(step.tool!),
              status: isSuccess ? ToolStatus.completed : ToolStatus.failed,
              statusLabel: statusLabel,
              details: _extractKeyArgs(step.tool!, step.args ?? {}),
              rawArgs: jsonEncode(step.args ?? {}),
            ),
          );
        }

        if (toolEntries.isNotEmpty) {
          _history.add(ChatMessage.toolExecution(entries: toolEntries));
        }
      }

      _history.add(
        ChatMessage.assistant(
          streamedContent,
          referencedNotes: result.referencedNotes,
          toolCalls: toolCalls,
        ),
      );

      _memoryExtractor.incrementCounter();
      _memoryExtractor.setAIService(_memorySettings.memoryAIService);

      final keywordTrigger = _memoryExtractor.shouldTriggerByKeyword(message);
      final batchTrigger = _memoryExtractor.shouldTriggerByBatch();
      final shouldExtract =
          _memorySettings.memorySystemEnabled &&
          _memorySettings.hasAvailableModel &&
          (keywordTrigger || batchTrigger);

      if (shouldExtract) {
        final triggerReason = keywordTrigger
            ? '关键词触发'
            : '批量触发(第${_memoryExtractor.counter}轮)';
        final useMessageNum = keywordTrigger ? 3 : _memoryExtractor.counter * 3;
        final recentHistory = _buildRecentHistory(
          _history,
          maxMessages: useMessageNum,
        );
        debugPrint(
          '[Memory] 开始记忆提取: $triggerReason, 消息数: ${recentHistory.length}',
        );
        _memoryExtractor
            .extractAndSave(recentHistory, triggerReason)
            .catchError((e) {
              debugPrint('[CiciAgent] 记忆提取异步任务失败: $e');
            });
      }

      return AgentResponse(
        text: streamedContent,
        referencedNotes: result.referencedNotes,
        usedTools: result.steps.any((s) => s.isToolCall),
        toolCalls: toolCalls,
      );
    } catch (e) {
      final errorMsg = '处理请求时出错: $e';
      debugPrint('=== Agent 异常 ===');
      debugPrint('错误: $e');
      _history.add(ChatMessage.error(errorMsg));
      return AgentResponse.fromError(errorMsg);
    }
  }

  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'note_search':
        return '搜索笔记';
      case 'note_read':
        return '读取笔记';
      case 'note_search_by_title':
        return '标题搜索';
      case 'note_edit_info':
        return '编辑笔记基本信息';
      case 'note_edit_content':
        return '编辑笔记内容';
      case 'note_create':
        return '新建笔记';
      case 'note_delete':
        return '删除笔记';
      case 'note_rewrite':
        return '改写润色';
      case 'note_merge':
        return '合并笔记';
      case 'note_summarize':
        return '总结提炼';
      case 'note_extract_keywords':
        return '关键词提取';
      case 'note_qa':
        return '笔记问答';
      case 'note_list_recent':
        return '最近笔记';
      case 'note_list_categories':
        return '分类列表';
      case 'note_list_tags':
        return '标签列表';
      case 'note_list_by_category':
        return '分类浏览';
      case 'note_vector_search':
        return '向量检索';
      case 'note_get_format':
        return '获取格式';
      case 'note_create_from_url':
        return '网页提取';
      case 'note_open':
        return '打开笔记';
      default:
        return toolName;
    }
  }

  List<String> _extractKeyArgs(String toolName, Map<String, dynamic> args) {
    switch (toolName) {
      case 'note_search':
        final queryList = args['queryList'] as List?;
        if (queryList != null && queryList.isNotEmpty) {
          return ['关键词: ${queryList.join(', ')}'];
        }
        return [];
      case 'note_vector_search':
        final query = args['query'] as String?;
        if (query != null && query.isNotEmpty) {
          return ['查询: $query'];
        }
        return [];
      case 'note_search_by_title':
        return args.containsKey('title_query')
            ? ['标题: ${args['title_query']}']
            : [];
      case 'note_read':
      case 'note_edit_info':
      case 'note_delete':
      case 'note_summarize':
      case 'note_rewrite':
      case 'note_qa':
        return args.containsKey('note_id') ? ['笔记ID: ${args['note_id']}'] : [];
      case 'note_create':
        return args.containsKey('title') ? ['标题: ${args['title']}'] : [];
      case 'note_list_recent':
        return args.containsKey('limit') ? ['数量: ${args['limit']}'] : [];
      case 'note_list_categories':
        return ['获取所有分类'];
      case 'note_list_tags':
        return ['获取所有标签'];
      case 'note_list_by_category':
        final cat = args['category'] ?? args['categoryId'];
        return cat != null ? ['分类: $cat'] : [];
      case 'note_merge':
        final ids = args['note_ids'] as List?;
        if (ids != null && ids.isNotEmpty) {
          return ['合并 ${ids.length} 篇笔记'];
        }
        return [];
      case 'note_get_format':
        final ids = args['note_ids'] as List?;
        if (ids != null && ids.isNotEmpty) {
          return ['查询 ${ids.length} 篇笔记格式'];
        }
        return [];
      case 'note_create_from_url':
        final url = args['url'] as String?;
        if (url != null && url.isNotEmpty) {
          return ['URL: $url'];
        }
        return [];
      case 'note_open':
        return args.containsKey('note_id') ? ['笔记ID: ${args['note_id']}'] : [];
      default:
        return [];
    }
  }

  /// 构建最近历史记录，确保以用户消息开头、最后一条消息结尾
  List<ChatMessage> _buildRecentHistory(
    List<ChatMessage> history, {
    int maxMessages = 20,
  }) {
    if (history.isEmpty) return [];

    // 1. 终点：最后一条消息（可以是任何类型）
    final endIndex = history.length - 1;

    // 2. 从终点往前数 maxMessages 条
    int startIndex = (endIndex - maxMessages + 1).clamp(0, endIndex);

    // 3. 如果起始位置不是 user 消息，继续往前找第一个 user 消息
    while (startIndex > 0 &&
        history[startIndex].messageType != CiciMessageType.user) {
      startIndex--;
    }

    // 返回 [startIndex, endIndex] 范围的消息（包含 endIndex）
    return history.sublist(startIndex, endIndex + 1);
  }
}
