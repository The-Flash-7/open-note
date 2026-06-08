// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import '../models/agent_memory.dart';
import 'sqlite_database_service.dart';

class MemoryPersistenceService {
  static final MemoryPersistenceService _instance =
      MemoryPersistenceService._internal();
  final SQLiteDatabaseService _db = SQLiteDatabaseService();

  factory MemoryPersistenceService() => _instance;

  MemoryPersistenceService._internal();

  static const int maxMemoriesForPrompt = 5;
  static const int maxExperiencesForPrompt = 3;
  static const int confidenceThreshold = 1;

  Future<void> saveMemory(AgentMemory memory) async {
    try {
      final existing = await getMemoryByKey(memory.type, memory.key);
      if (existing != null) {
        final updated = existing.copyWith(
          value: memory.value,
          frequency: existing.frequency + 1,
          confidence: (existing.confidence + 1).clamp(1, 5),
          lastAccessedAt: DateTime.now(),
          tags: _mergeTags(existing.tags, memory.tags),
        );
        await _db.saveAgentMemory(updated.toMap());
        debugPrint('[Memory] 更新记忆: ${memory.type.name}/${memory.key}');
      } else {
        await _db.saveAgentMemory(memory.toMap());
        debugPrint('[Memory] 新增记忆: ${memory.type.name}/${memory.key}');
      }
    } catch (e) {
      debugPrint('[Memory] 保存记忆失败: $e');
    }
  }

  Future<void> saveMemories(List<AgentMemory> memories) async {
    for (final memory in memories) {
      await saveMemory(memory);
    }
  }

  Future<AgentMemory?> getMemoryById(String id) async {
    try {
      final map = await _db.getAgentMemory(id);
      if (map == null) return null;
      return AgentMemory.fromMap(map);
    } catch (e) {
      debugPrint('[Memory] 获取记忆失败: $e');
      return null;
    }
  }

  Future<AgentMemory?> getMemoryByKey(MemoryType type, String key) async {
    try {
      final entries = await _db.getAllAgentMemories();
      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);
        if (memory.type == type && memory.key == key) {
          return memory;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[Memory] 按键获取记忆失败: $e');
      return null;
    }
  }

  Future<List<AgentMemory>> getMemoriesByTags(
    List<String> tags, {
    int limit = maxMemoriesForPrompt,
  }) async {
    try {
      final entries = await _db.getAllAgentMemories();
      final memories = <AgentMemory>[];

      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);

        if (memory.decayedConfidence < confidenceThreshold) continue;
        if (memory.isExpired()) continue;

        final hasMatchingTag = memory.tags.any(
          (t) => tags.any((tag) => t.contains(tag) || tag.contains(t)),
        );
        if (hasMatchingTag) {
          memories.add(memory);
        }
      }

      memories.sort((a, b) {
        final scoreA = a.confidence * 10 + a.frequency;
        final scoreB = b.confidence * 10 + b.frequency;
        return scoreB.compareTo(scoreA);
      });

      return memories.take(limit).toList();
    } catch (e) {
      debugPrint('[Memory] 按标签检索记忆失败: $e');
      return [];
    }
  }

  Future<List<AgentMemory>> getProfileMemories({
    int limit = maxMemoriesForPrompt,
  }) async {
    try {
      final entries = await _db.getAllAgentMemories();
      final memories = <AgentMemory>[];

      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);

        if (memory.type != MemoryType.profile) continue;
        if (memory.decayedConfidence < confidenceThreshold) continue;

        final updated = memory.copyWith(lastAccessedAt: DateTime.now());
        await _db.saveAgentMemory(updated.toMap());

        memories.add(memory);
      }

      memories.sort((a, b) => b.confidence.compareTo(a.confidence));
      return memories.take(limit).toList();
    } catch (e) {
      debugPrint('[Memory] 获取档案记忆失败: $e');
      return [];
    }
  }

  Future<List<AgentMemory>> getExperienceMemories({
    int limit = maxExperiencesForPrompt,
  }) async {
    try {
      final entries = await _db.getAllAgentMemories();
      final memories = <AgentMemory>[];

      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);

        if (memory.type != MemoryType.experience) continue;
        if (memory.decayedConfidence < confidenceThreshold) continue;

        final updated = memory.copyWith(lastAccessedAt: DateTime.now());
        await _db.saveAgentMemory(updated.toMap());

        memories.add(memory);
      }

      memories.sort((a, b) {
        final scoreA = a.confidence * 10 + a.frequency * 5;
        final scoreB = b.confidence * 10 + b.frequency * 5;
        return scoreB.compareTo(scoreA);
      });

      return memories.take(limit).toList();
    } catch (e) {
      debugPrint('[Memory] 获取经验记忆失败: $e');
      return [];
    }
  }

  Future<List<AgentMemory>> getAllActiveMemories() async {
    try {
      final entries = await _db.getAllAgentMemories();
      final memories = <AgentMemory>[];

      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);

        if (memory.decayedConfidence >= confidenceThreshold &&
            !memory.isExpired()) {
          memories.add(memory);
        }
      }

      return memories;
    } catch (e) {
      debugPrint('[Memory] 获取所有活跃记忆失败: $e');
      return [];
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await _db.deleteAgentMemory(id);
      debugPrint('[Memory] 删除记忆: $id');
    } catch (e) {
      debugPrint('[Memory] 删除记忆失败: $e');
    }
  }

  Future<Map<MemoryType, int>> getMemoryCounts() async {
    try {
      final entries = await _db.getAllAgentMemories();
      final counts = <MemoryType, int>{
        MemoryType.profile: 0,
        MemoryType.fact: 0,
        MemoryType.experience: 0,
      };

      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);
        if (!memory.isExpired() &&
            memory.decayedConfidence >= confidenceThreshold) {
          counts[memory.type] = (counts[memory.type] ?? 0) + 1;
        }
      }

      return counts;
    } catch (e) {
      debugPrint('[Memory] 获取记忆统计失败: $e');
      return {
        MemoryType.profile: 0,
        MemoryType.fact: 0,
        MemoryType.experience: 0,
      };
    }
  }

  Future<void> clearAllMemories() async {
    try {
      await _db.clearAllAgentMemories();
      debugPrint('[Memory] 清空所有记忆');
    } catch (e) {
      debugPrint('[Memory] 清空记忆失败: $e');
    }
  }

  Future<void> applyDecayToAll() async {
    try {
      final entries = await _db.getAllAgentMemories();
      for (final map in entries) {
        final memory = AgentMemory.fromMap(map);

        if (memory.isExpired() && memory.confidence <= confidenceThreshold) {
          await deleteMemory(memory.id);
        }
      }
    } catch (e) {
      debugPrint('[Memory] 应用衰减失败: $e');
    }
  }

  List<String> _mergeTags(List<String> existing, List<String> newTags) {
    final merged = <String>{...existing, ...newTags};
    return merged.toList();
  }

  static String formatMemoriesForPrompt(List<AgentMemory> memories) {
    if (memories.isEmpty) return '无';

    final buffer = StringBuffer();
    for (final memory in memories) {
      switch (memory.type) {
        case MemoryType.profile:
          buffer.writeln('- ${memory.key}: ${memory.value}');
          break;
        case MemoryType.fact:
          buffer.writeln('- ${memory.value}');
          break;
        case MemoryType.experience:
          buffer.writeln('- 当用户${memory.key}时，${memory.value}');
          break;
      }
    }
    return buffer.toString().trim();
  }
}
