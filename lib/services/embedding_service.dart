// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_provider_config.dart';

class EmbeddingService {
  final http.Client _client = http.Client();
  AIProviderConfig? _config;
  final Map<String, List<double>> _cache = {};
  static const int _maxCacheSize = 5000;

  bool _usePythonService = false;
  String? _pythonServiceUrl;

  AIProviderConfig? get currentConfig => _config;
  bool get isConfigured {
    // Python 服务模式
    if (_usePythonService && _pythonServiceUrl != null) return true;
    // API 模式
    return _config != null &&
        _config!.apiKey != null &&
        _config!.apiKey!.isNotEmpty;
  }

  bool get useLocalModel => _usePythonService;
  bool get isAvailable => isConfigured;

  void setConfig(AIProviderConfig config) {
    _config = config;
    _usePythonService = false;
    _pythonServiceUrl = null;
  }

  Future<void> initializeLocalModel({
    required String modelPath,
    String serviceUrl = 'http://127.0.0.1:8765',
  }) async {
    _usePythonService = true;
    _pythonServiceUrl = serviceUrl;
    debugPrint('EmbeddingService: 本地模型服务已配置 ($serviceUrl)');
  }

  List<double>? getCachedEmbedding(String text) {
    return _cache[text];
  }

  void cacheEmbedding(String text, List<double> vector) {
    if (_cache.length >= _maxCacheSize) {
      final firstKey = _cache.keys.first;
      _cache.remove(firstKey);
    }
    _cache[text] = vector;
  }

  Future<List<double>> generateEmbedding(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return _zeroVector(3584);

    // 检查缓存
    final cached = getCachedEmbedding(trimmedText);
    if (cached != null) return cached;

    // 使用 Python 服务
    if (_usePythonService && _pythonServiceUrl != null) {
      return await _callPythonService(trimmedText);
    }

    // 使用 AI API
    if (isConfigured) {
      return await _callEmbeddingAPI(trimmedText);
    }

    throw Exception('Embedding 服务未配置');
  }

  Future<List<double>> _callPythonService(String text) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_pythonServiceUrl/api/embedding'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final embedding = (data['embedding'] as List)
            .map((e) => (e as num).toDouble())
            .toList();

        cacheEmbedding(text, embedding);
        return embedding;
      } else {
        final previewText = text.length > 100
            ? '${text.substring(0, 100)}...'
            : text;
        debugPrint(
          'EmbeddingService: Python 服务返回错误 ${response.statusCode}\n'
          'URL: $_pythonServiceUrl/api/embedding\n'
          'Request: $previewText\n'
          'Response: ${response.body}',
        );
        throw Exception('Python 服务返回错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('EmbeddingService: Python 服务调用失败: $e');
      throw Exception('Embedding 生成失败: $e');
    }
  }

  Future<List<double>> _callEmbeddingAPI(String text) async {
    if (_config == null) {
      throw Exception('AI 配置未设置');
    }

    try {
      final client = http.Client();
      final url = '${_config!.baseUrl}/embeddings';

      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_config!.apiKey}',
            },
            body: jsonEncode({'model': _config!.defaultModel, 'input': text}),
          )
          .timeout(const Duration(seconds: 30));

      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final embeddingData = data['data'] as List;
        final embedding = (embeddingData[0]['embedding'] as List)
            .map((e) => (e as num).toDouble())
            .toList();

        cacheEmbedding(text, embedding);
        return embedding;
      } else {
        throw Exception('API 返回错误: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('EmbeddingService: API 调用失败: $e');
      throw Exception('Embedding 生成失败: $e');
    }
  }

  Future<Map<String, List<double>>> generateBatchEmbeddings(
    List<String> texts,
  ) async {
    final results = <String, List<double>>{};

    for (final text in texts) {
      try {
        final vector = await generateEmbedding(text);
        results[text] = vector;

        // 小延迟避免 API 限流
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Batch embedding failed for "$text": $e');
      }
    }

    return results;
  }

  double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = normA * normB;
    if (denominator == 0) return 0.0;

    return dotProduct / denominator;
  }

  List<double> _zeroVector(int dimensions) {
    return List.filled(dimensions, 0.0);
  }

  void clearCache() {
    _cache.clear();
  }

  int get cacheSize => _cache.length;

  void dispose() {
    _client.close();
  }
}
