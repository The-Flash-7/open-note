// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_provider_config.dart';
import '../services/config_service.dart';
import '../services/ai_service.dart';

class SettingsProvider extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final AIService _aiService = AIService();

  List<AIProviderConfig> _providerConfigs = [];
  AIProviderConfig? _activeProvider;
  bool _isLoading = false;
  String? _errorMessage;

  List<AIProviderConfig> get providerConfigs => _providerConfigs;
  AIProviderConfig? get activeProvider => _activeProvider;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasActiveProvider =>
      _activeProvider != null && _activeProvider!.hasValidConfig();

  AIService get aiService => _aiService;

  static const _onboardingShownKey = 'has_shown_onboarding';

  Future<bool> hasShownOnboarding() async {
    debugPrint('🔍 [hasShownOnboarding] 开始检查');
    final prefs = await SharedPreferences.getInstance();
    final result = prefs.getBool(_onboardingShownKey) ?? false;
    debugPrint('🔍 [hasShownOnboarding] SharedPreferences返回: $result');
    debugPrint('🔍 [hasShownOnboarding] 检查完成，结果: $result');
    return result;
  }

  Future<void> setOnboardingShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingShownKey, true);
    notifyListeners();
  }

  Future<void> loadSettings() async {
    debugPrint('🔍 [loadSettings] 开始加载');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _providerConfigs = await _configService.loadProviderConfigs();
      debugPrint(
        '🔍 [loadSettings] providerConfigs加载完成: ${_providerConfigs.length}个配置',
      );

      _activeProvider = await _configService.getActiveProvider();
      debugPrint(
        '🔍 [loadSettings] activeProvider: ${_activeProvider?.name ?? "null"}',
      );
      debugPrint(
        '🔍 [loadSettings] activeProvider是否有效: ${_activeProvider?.hasValidConfig() ?? false}',
      );

      if (_activeProvider != null && _activeProvider!.hasValidConfig()) {
        _aiService.setConfig(_activeProvider!);
        debugPrint('🔍 [loadSettings] AIService已配置');
      }
    } catch (e) {
      _errorMessage = '加载设置失败: $e';
      debugPrint('❌ [loadSettings] 加载错误: $e');
    } finally {
      _isLoading = false;
      debugPrint('🔍 [loadSettings] 加载完成');
      debugPrint(
        '🔍 [loadSettings] 最终状态 - isLoading: $isLoading, hasActiveProvider: $hasActiveProvider',
      );
      notifyListeners();
    }
  }

  Future<void> createProviderFromTemplate(
    AIProviderTemplate template,
    String apiKey,
    bool isDefault,
  ) async {
    final config = template
        .toConfig(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          apiKey: apiKey,
        )
        .copyWith(isDefault: isDefault);

    await _configService.saveProviderConfig(config);
    _providerConfigs.add(config);

    if (isDefault || _activeProvider == null) {
      _activeProvider = config;
      _aiService.setConfig(config);
      await _configService.setActiveProviderId(config.id);
    }

    notifyListeners();
  }

  Future<void> updateProvider(AIProviderConfig config) async {
    await _configService.saveProviderConfig(config);

    final index = _providerConfigs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      _providerConfigs[index] = config;
    }

    if (_activeProvider?.id == config.id) {
      _activeProvider = config;
      _aiService.setConfig(config);
    }

    notifyListeners();
  }

  Future<void> deleteProvider(String id) async {
    await _configService.deleteProviderConfig(id);
    _providerConfigs.removeWhere((c) => c.id == id);

    if (_activeProvider?.id == id) {
      _activeProvider = _providerConfigs.isNotEmpty
          ? _providerConfigs.first
          : null;
      if (_activeProvider != null) {
        _aiService.setConfig(_activeProvider!);
      }
    }

    notifyListeners();
  }

  Future<void> setActiveProvider(String id) async {
    final config = _providerConfigs.firstWhere(
      (c) => c.id == id,
      orElse: () => _providerConfigs.first,
    );

    if (config.id == id) {
      await _configService.setActiveProviderId(id);
      _activeProvider = config;
      _aiService.setConfig(config);
      notifyListeners();
    }
  }

  Future<bool> testConnection(AIProviderConfig config) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _aiService.setConfig(config);
      final testPrompt = '请回复"连接成功"';
      final response = await _aiService.callAI(testPrompt);
      return response.isNotEmpty;
    } catch (e) {
      _errorMessage = '连接测试失败: $e';
      debugPrint('Test connection error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String? get urlProcessingModel {
    return null;
  }

  Future<void> setUrlProcessingModel(String? model) async {
    notifyListeners();
  }
}
