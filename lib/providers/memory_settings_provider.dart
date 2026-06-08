// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/agent_memory.dart';
import '../models/ai_provider_config.dart';
import '../services/memory_persistence_service.dart';
import '../services/ai_service.dart';
import 'settings_provider.dart';

class MemorySettingsProvider extends ChangeNotifier {
  MemorySettingsProvider({SettingsProvider? settingsProvider}) {
    _loadSettings();
    if (settingsProvider != null) {
      _syncAvailableProviders(settingsProvider.providerConfigs);
    }
  }

  static const String _keyMemorySystemEnabled = 'memory_system_enabled';
  static const String _keyProfileInjectionEnabled =
      'memory_profile_injection_enabled';
  static const String _keyFactInjectionEnabled =
      'memory_fact_injection_enabled';
  static const String _keyExperienceInjectionEnabled =
      'memory_experience_injection_enabled';
  static const String _keyMemoryAiProviderId = 'memory_ai_provider_id';
  static const String _keyMemoryAiModel = 'memory_ai_model';

  Map<MemoryType, int> _memoryCounts = {
    MemoryType.profile: 0,
    MemoryType.fact: 0,
    MemoryType.experience: 0,
  };

  bool _memorySystemEnabled = true;
  bool _profileInjectionEnabled = true;
  bool _factInjectionEnabled = true;
  bool _experienceInjectionEnabled = true;
  bool _isLoading = false;

  String _memoryAiProviderId = '';
  String _memoryAiModel = '';
  List<AIProviderConfig> _availableProviders = [];
  final AIService _memoryAIService = AIService();

  bool get memorySystemEnabled => _memorySystemEnabled;
  bool get profileInjectionEnabled => _profileInjectionEnabled;
  bool get factInjectionEnabled => _factInjectionEnabled;
  bool get experienceInjectionEnabled => _experienceInjectionEnabled;
  bool get isLoading => _isLoading;

  String get memoryAiProviderId => _memoryAiProviderId;
  String get memoryAiModel => _memoryAiModel;
  List<AIProviderConfig> get availableProviders => _availableProviders;
  AIService get memoryAIService => _memoryAIService;

  int getMemoryCount(MemoryType type) => _memoryCounts[type] ?? 0;

  bool get hasAvailableModel {
    return _availableProviders.any(
      (p) => p.hasValidConfig() && p.models.isNotEmpty,
    );
  }

  bool get canEnableMemorySystem => hasAvailableModel;

  Future<void> _loadSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      _memorySystemEnabled = prefs.getBool(_keyMemorySystemEnabled) ?? true;
      _profileInjectionEnabled =
          prefs.getBool(_keyProfileInjectionEnabled) ?? true;
      _factInjectionEnabled = prefs.getBool(_keyFactInjectionEnabled) ?? true;
      _experienceInjectionEnabled =
          prefs.getBool(_keyExperienceInjectionEnabled) ?? true;
      _memoryAiProviderId = prefs.getString(_keyMemoryAiProviderId) ?? '';
      _memoryAiModel = prefs.getString(_keyMemoryAiModel) ?? '';
    } catch (e) {
      debugPrint('[MemorySettings] 加载设置失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncAvailableProviders(List<AIProviderConfig> allProviders) {
    _availableProviders = allProviders
        .where((p) => p.hasValidConfig() && p.models.isNotEmpty)
        .toList();
    debugPrint('[MemorySettings] 过滤后可用提供商数=${_availableProviders.length}');

    if (_memoryAiProviderId.isEmpty && _availableProviders.isNotEmpty) {
      _memoryAiProviderId = _availableProviders.first.id;
      _memoryAiModel = _availableProviders.first.defaultModel;
      _initializeMemoryAIService();
    } else if (_availableProviders.isNotEmpty) {
      final exists = _availableProviders.any(
        (p) => p.id == _memoryAiProviderId,
      );
      if (exists) {
        _initializeMemoryAIService();
      } else {
        _memoryAiProviderId = _availableProviders.first.id;
        _memoryAiModel = _availableProviders.first.defaultModel;
        _initializeMemoryAIService();
      }
    } else {
      _memoryAIService.setConfig(
        AIProviderConfig(
          id: '',
          name: '',
          displayName: '',
          models: [],
          defaultModel: '',
          createdAt: DateTime.now(),
        ),
      );
    }

    if (!canEnableMemorySystem && _memorySystemEnabled) {
      _memorySystemEnabled = false;
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('[MemorySettings] 保存设置失败: $e');
    }
  }

  Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('[MemorySettings] 保存设置失败: $e');
    }
  }

  Future<void> toggleMemorySystem(bool enabled) async {
    if (enabled && !canEnableMemorySystem) return;

    _memorySystemEnabled = enabled;
    await _saveBool(_keyMemorySystemEnabled, enabled);
    notifyListeners();
  }

  Future<void> toggleProfileInjection(bool enabled) async {
    _profileInjectionEnabled = enabled;
    await _saveBool(_keyProfileInjectionEnabled, enabled);
    notifyListeners();
  }

  Future<void> toggleFactInjection(bool enabled) async {
    _factInjectionEnabled = enabled;
    await _saveBool(_keyFactInjectionEnabled, enabled);
    notifyListeners();
  }

  Future<void> toggleExperienceInjection(bool enabled) async {
    _experienceInjectionEnabled = enabled;
    await _saveBool(_keyExperienceInjectionEnabled, enabled);
    notifyListeners();
  }

  Future<void> refreshMemoryCounts() async {
    try {
      final memoryService = MemoryPersistenceService();
      _memoryCounts = await memoryService.getMemoryCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('[MemorySettings] 刷新记忆统计失败: $e');
    }
  }

  void loadAvailableProviders(List<AIProviderConfig> allProviders) {
    _syncAvailableProviders(allProviders);
    notifyListeners();
  }

  Future<void> setMemoryAiModel(String providerId, String model) async {
    _memoryAiProviderId = providerId;
    _memoryAiModel = model;

    await _saveString(_keyMemoryAiProviderId, providerId);
    await _saveString(_keyMemoryAiModel, model);

    _initializeMemoryAIService();
    notifyListeners();
  }

  void _initializeMemoryAIService() {
    final provider = _availableProviders.firstWhere(
      (p) => p.id == _memoryAiProviderId,
      orElse: () => _availableProviders.isEmpty
          ? AIProviderConfig(
              id: '',
              name: '',
              displayName: '',
              models: [],
              defaultModel: '',
              createdAt: DateTime.now(),
            )
          : _availableProviders.first,
    );

    final configToUse = provider.copyWith(defaultModel: _memoryAiModel);
    _memoryAIService.setConfig(configToUse);
  }

  Future<void> clearMemoryByType(MemoryType type) async {
    try {
      final memoryService = MemoryPersistenceService();
      final allMemories = await memoryService.getAllActiveMemories();

      for (final memory in allMemories) {
        if (memory.type == type) {
          await memoryService.deleteMemory(memory.id);
        }
      }
      await refreshMemoryCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('[MemorySettings] 清空记忆失败: $e');
    }
  }

  Future<void> clearAllMemories() async {
    try {
      final memoryService = MemoryPersistenceService();
      await memoryService.clearAllMemories();
      await refreshMemoryCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('[MemorySettings] 清空全部记忆失败: $e');
    }
  }

  bool isMemoryTypeEnabled(MemoryType type) {
    if (!_memorySystemEnabled) return false;

    switch (type) {
      case MemoryType.profile:
        return _profileInjectionEnabled;
      case MemoryType.fact:
        return _factInjectionEnabled;
      case MemoryType.experience:
        return _experienceInjectionEnabled;
    }
  }
}
