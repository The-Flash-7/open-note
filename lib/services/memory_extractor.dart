// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/agent_memory.dart';
import '../models/chat_message.dart';
import 'ai_service.dart';
import 'memory_persistence_service.dart';
import 'sqlite_database_service.dart';
import 'prompts/memory_extract_prompt.dart';
import 'skills/skill_registry.dart';

class MemoryExtractor {
  static final MemoryExtractor _instance = MemoryExtractor._internal();
  final MemoryPersistenceService _memoryService = MemoryPersistenceService();
  final SQLiteDatabaseService _db = SQLiteDatabaseService();

  AIService? _aiService;
  SkillRegistry? _skillRegistry;

  void setAIService(AIService aiService) {
    _aiService = aiService;
  }

  void setSkillRegistry(SkillRegistry skillRegistry) {
    _skillRegistry = skillRegistry;
  }

  int _conversationCounter = 0;
  static const int batchTriggerThreshold = 5;
  static const String _counterKey = 'memory_conversation_counter';

  static const List<String> memoryKeywords = [
    '以后',
    '以后都',
    '我习惯',
    '记住',
    '我喜欢',
    '我不喜欢',
    '我总是',
    '下次',
    '请记住',
    '帮我记住',
    '以后就这样',
    '以后按这个',
    '每次都',
    '一直用',
  ];

  factory MemoryExtractor() => _instance;

  MemoryExtractor._internal();

  Future<void> init() async {
    await _loadCounter();
  }

  Future<void> incrementCounter() async {
    _conversationCounter++;
    await _saveCounter();
  }

  Future<void> resetCounter() async {
    _conversationCounter = 0;
    await _saveCounter();
  }

  int get counter => _conversationCounter;

  Future<void> _loadCounter() async {
    try {
      final saved = await _db.getConfig(_counterKey);
      if (saved != null) {
        _conversationCounter = int.parse(saved);
      }
    } catch (e) {
      debugPrint('[MemoryExtractor] 加载计数器失败: $e');
    }
  }

  Future<void> _saveCounter() async {
    try {
      await _db.setConfig(_counterKey, _conversationCounter.toString());
    } catch (e) {
      debugPrint('[MemoryExtractor] 保存计数器失败: $e');
    }
  }

  bool shouldTriggerByKeyword(String userMessage) {
    return memoryKeywords.any((keyword) => userMessage.contains(keyword));
  }

  bool shouldTriggerByBatch() {
    return _conversationCounter >= batchTriggerThreshold;
  }

  Set<String> _extractToolNames(List<ChatMessage> recentHistory) {
    final toolNames = <String>{};
    for (final m in recentHistory) {
      if (m.messageType == CiciMessageType.toolExecution) {
        for (final e in m.toolExecutions ?? []) {
          toolNames.add(e.toolName);
        }
      }
    }
    return toolNames;
  }

  String _buildToolDefinitions(Set<String> toolNames) {
    if (toolNames.isEmpty || _skillRegistry == null) return '';

    final buffer = StringBuffer();
    for (final toolName in toolNames) {
      final skill = _skillRegistry!.getSkill(toolName);
      if (skill == null) continue;

      buffer.writeln('### ${skill.name}');
      buffer.writeln('描述: ${skill.description}');

      if (skill.parameters.isNotEmpty) {
        buffer.writeln('参数:');
        for (final p in skill.parameters) {
          final required = p.required ? '(必填)' : '(可选)';
          final defaultInfo = p.defaultValue != null
              ? ', 默认: ${p.defaultValue}'
              : '';
          buffer.writeln(
            '  - ${p.name} (${p.type}$required$defaultInfo): ${p.description}',
          );
        }
      }
      buffer.writeln();
    }

    return buffer.toString().trim();
  }

  Future<void> extractAndSave(
    List<ChatMessage> recentHistory,
    String triggerReason,
  ) async {
    if (recentHistory.isEmpty) return;
    debugPrint('[MemoryExtractor] AI 服务配置状态: ${_aiService?.hasConfig()}');
    if (_aiService == null || !_aiService!.hasConfig()) {
      debugPrint('[MemoryExtractor] AI服务未配置，跳过记忆提取');
      return;
    }

    try {
      debugPrint('[MemoryExtractor] 触发记忆提取: $triggerReason');

      final conversationBuffer = StringBuffer();
      bool lastWasToolExecution = false;

      for (final m in recentHistory) {
        switch (m.messageType) {
          case CiciMessageType.user:
            if (lastWasToolExecution) conversationBuffer.writeln();
            conversationBuffer.writeln('用户: ${m.content}');
            lastWasToolExecution = false;
            break;

          case CiciMessageType.toolExecution:
            if (m.toolExecutions?.isNotEmpty == true) {
              if (!lastWasToolExecution) {
                conversationBuffer.writeln('AI助手: [工具调用]');
              }
              for (final e in m.toolExecutions!) {
                final argsText = e.rawArgs != null && e.rawArgs!.isNotEmpty
                    ? ' ${e.rawArgs}'
                    : '';
                conversationBuffer.writeln(
                  '• ${e.toolName}$argsText: ${e.statusLabel}',
                );
              }
              lastWasToolExecution = true;
            }
            break;

          case CiciMessageType.assistant:
            if (lastWasToolExecution) {
              conversationBuffer.writeln('[/工具调用]');
            }
            String cleanContent = m.content;
            final refStart = cleanContent.indexOf('[引用笔记]');
            if (refStart >= 0) {
              final refEnd = cleanContent.indexOf('[/引用笔记]');
              if (refEnd >= 0) {
                cleanContent =
                    cleanContent.substring(0, refStart) +
                    cleanContent.substring(refEnd + 13);
              }
            }
            if (cleanContent.trim().isNotEmpty) {
              conversationBuffer.writeln('AI助手: ${cleanContent.trim()}');
            }
            lastWasToolExecution = false;
            break;

          default:
            break;
        }
      }

      final conversationText = conversationBuffer.toString().trim();
      final existingMemories = await _getExistingMemoriesText();

      final usedTools = _extractToolNames(recentHistory);
      final toolDefinitions = _buildToolDefinitions(usedTools);

      final prompt = MemoryExtractPrompt.buildExtractPrompt(
        conversation: conversationText,
        existingMemories: existingMemories,
        toolDefinitions: toolDefinitions,
      );

      debugPrint('[MemoryExtractor] 记忆提取经验总结提示词：\n$prompt');

      String responseBuffer = '';
      await for (final chunk in _aiService!.callAIStream(prompt)) {
        if (chunk.content != null) {
          responseBuffer += chunk.content!;
        }
      }

      final memories = _parseExtractedMemories(responseBuffer);
      if (memories.isNotEmpty) {
        await _memoryService.saveMemories(memories);
        debugPrint('[MemoryExtractor] 成功提取并保存 ${memories.length} 条记忆');
      } else {
        debugPrint('[MemoryExtractor] 未提取到有效记忆');
      }

      if (triggerReason.contains('批量')) {
        resetCounter();
      }
    } catch (e) {
      debugPrint('[MemoryExtractor] 记忆提取失败: $e');
    }
  }

  Future<String> _getExistingMemoriesText() async {
    try {
      final allMemories = await _memoryService.getAllActiveMemories();
      if (allMemories.isEmpty) return '';

      final buffer = StringBuffer();
      for (final memory in allMemories.take(10)) {
        buffer.writeln('- ${memory.type.name}/${memory.key}: ${memory.value}');
      }
      return buffer.toString().trim();
    } catch (e) {
      return '';
    }
  }

  List<AgentMemory> _parseExtractedMemories(String response) {
    try {
      String cleaned = response.trim();

      if (cleaned.contains('```json')) {
        final start = cleaned.indexOf('```json') + 7;
        final end = cleaned.indexOf('```', start);
        if (end > start) {
          cleaned = cleaned.substring(start, end).trim();
        }
      } else if (cleaned.contains('```')) {
        final start = cleaned.indexOf('```') + 3;
        final end = cleaned.indexOf('```', start);
        if (end > start) {
          cleaned = cleaned.substring(start, end).trim();
        }
      }

      if (cleaned == '[]' || cleaned.isEmpty) {
        return [];
      }

      final parsed = jsonDecode(cleaned) as List;
      final memories = <AgentMemory>[];

      for (final item in parsed) {
        final map = item as Map<String, dynamic>;
        final typeStr = map['type'] as String?;
        if (typeStr == null) continue;

        final memoryType = MemoryType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => MemoryType.fact,
        );

        final key = map['key'] as String?;
        final value = map['value'] as String?;
        if (key == null || key.isEmpty || value == null || value.isEmpty) {
          continue;
        }

        final tags = (map['tags'] as List?)?.cast<String>() ?? [];

        final memory = AgentMemory(
          id: 'mem_${DateTime.now().millisecondsSinceEpoch}_${memories.length}',
          type: memoryType,
          key: key,
          value: value,
          tags: tags,
        );

        memories.add(memory);
      }

      return memories;
    } catch (e) {
      debugPrint('[MemoryExtractor] 解析提取结果失败: $e');
      return [];
    }
  }
}
