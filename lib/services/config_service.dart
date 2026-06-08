// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider_config.dart';
import '../models/knowledge_base_config.dart';

class ConfigService {
  static const String _providerConfigsKey = 'ai_provider_configs';
  static const String _activeProviderIdKey = 'active_provider_id';
  static const String _knowledgeBaseConfigKey = 'knowledge_base_config';

  Future<void> saveProviderConfigs(List<AIProviderConfig> configs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = configs.map((c) => c.toMap()).toList();
    await prefs.setString(_providerConfigsKey, jsonEncode(jsonList));
  }

  Future<List<AIProviderConfig>> loadProviderConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_providerConfigsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => AIProviderConfig.fromMap(json)).toList();
    } catch (e) {
      debugPrint('Load provider configs error: $e');
      return [];
    }
  }

  Future<void> setActiveProviderId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activeProviderIdKey);
    } else {
      await prefs.setString(_activeProviderIdKey, id);
    }
  }

  Future<String?> getActiveProviderId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProviderIdKey);
  }

  Future<AIProviderConfig?> getActiveProvider() async {
    final configs = await loadProviderConfigs();
    final activeId = await getActiveProviderId();

    if (activeId == null || configs.isEmpty) {
      return configs.isNotEmpty ? configs.first : null;
    }

    return configs.firstWhere(
      (c) => c.id == activeId,
      orElse: () => configs.first,
    );
  }

  Future<void> saveProviderConfig(AIProviderConfig config) async {
    final configs = await loadProviderConfigs();
    final existingIndex = configs.indexWhere((c) => c.id == config.id);

    if (existingIndex >= 0) {
      configs[existingIndex] = config;
    } else {
      configs.add(config);
    }

    await saveProviderConfigs(configs);

    if (config.isDefault) {
      await setActiveProviderId(config.id);
    }
  }

  Future<void> deleteProviderConfig(String id) async {
    final configs = await loadProviderConfigs();
    configs.removeWhere((c) => c.id == id);
    await saveProviderConfigs(configs);

    final activeId = await getActiveProviderId();
    if (activeId == id) {
      if (configs.isNotEmpty) {
        await setActiveProviderId(configs.first.id);
      } else {
        await setActiveProviderId(null);
      }
    }
  }

  Future<void> addModelToProvider(String providerId, String modelName) async {
    final configs = await loadProviderConfigs();
    final index = configs.indexWhere((c) => c.id == providerId);

    if (index >= 0) {
      final config = configs[index];
      if (!config.models.contains(modelName)) {
        final updatedConfig = config.copyWith(
          models: [...config.models, modelName],
        );
        configs[index] = updatedConfig;
        await saveProviderConfigs(configs);
      }
    }
  }

  Future<void> removeModelFromProvider(
    String providerId,
    String modelName,
  ) async {
    final configs = await loadProviderConfigs();
    final index = configs.indexWhere((c) => c.id == providerId);

    if (index >= 0) {
      final config = configs[index];
      final updatedModels = config.models.where((m) => m != modelName).toList();
      final updatedConfig = config.copyWith(
        models: updatedModels,
        defaultModel: config.defaultModel == modelName
            ? (updatedModels.isNotEmpty ? updatedModels.first : '')
            : config.defaultModel,
      );
      configs[index] = updatedConfig;
      await saveProviderConfigs(configs);
    }
  }

  Future<void> setDefaultModel(String providerId, String modelName) async {
    final configs = await loadProviderConfigs();
    final index = configs.indexWhere((c) => c.id == providerId);

    if (index >= 0) {
      final config = configs[index];
      if (config.models.contains(modelName)) {
        final updatedConfig = config.copyWith(defaultModel: modelName);
        configs[index] = updatedConfig;
        await saveProviderConfigs(configs);
      }
    }
  }

  Future<void> saveKnowledgeBaseConfig(KnowledgeBaseConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_knowledgeBaseConfigKey, jsonEncode(config.toMap()));
  }

  Future<KnowledgeBaseConfig> loadKnowledgeBaseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_knowledgeBaseConfigKey);
    if (jsonString == null || jsonString.isEmpty) {
      return KnowledgeBaseConfig.defaultConfig;
    }
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return KnowledgeBaseConfig.fromMap(jsonMap);
    } catch (e) {
      debugPrint('Load knowledge base config error: $e');
      return KnowledgeBaseConfig.defaultConfig;
    }
  }

  Future<void> setKnowledgeBaseEnabled(bool enabled) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(isEnabled: enabled));
  }

  Future<void> setModelPath(String path) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(modelPath: path));
  }

  Future<void> setModelVersion(EmbeddingModelVersion version) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(modelVersion: version));
  }

  Future<void> setModelDownloaded(bool downloaded) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(
      config.copyWith(isModelDownloaded: downloaded),
    );
  }

  Future<void> setDownloadStatus(DownloadStatus status) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(downloadStatus: status));
  }

  Future<void> setDownloadProgress(double progress) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(downloadProgress: progress));
  }

  Future<void> setLastError(String? error) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(lastError: error));
  }

  Future<void> updateIndexStats({
    int? indexedNotesCount,
    int? totalVectors,
    DateTime? lastIndexedAt,
  }) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(
      config.copyWith(
        indexedNotesCount: indexedNotesCount,
        totalVectors: totalVectors,
        lastIndexedAt: lastIndexedAt,
      ),
    );
  }

  Future<void> updateChunkSize(int size) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(chunkSize: size));
  }

  Future<void> updateChunkOverlap(int overlap) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(chunkOverlap: overlap));
  }

  Future<void> updateIndexCacheSize(int size) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(indexCacheSize: size));
  }

  Future<void> updateSearchThreshold(double threshold) async {
    final config = await loadKnowledgeBaseConfig();
    await saveKnowledgeBaseConfig(config.copyWith(searchThreshold: threshold));
  }
}
