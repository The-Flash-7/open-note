// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:shared_preferences/shared_preferences.dart';

class KnowledgeConfig {
  static final KnowledgeConfig _instance = KnowledgeConfig._internal();
  static KnowledgeConfig get instance => _instance;
  KnowledgeConfig._internal();

  double searchThreshold = 0.5;
  int chunkSize = 500;
  int chunkOverlap = 50;
  int indexCacheSize = 5000;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    searchThreshold = prefs.getDouble('search_threshold') ?? 0.5;
    chunkSize = prefs.getInt('chunk_size') ?? 500;
    chunkOverlap = prefs.getInt('chunk_overlap') ?? 50;
    indexCacheSize = prefs.getInt('index_cache_size') ?? 5000;
  }

  Future<void> setSearchThreshold(double value) async {
    searchThreshold = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('search_threshold', value);
  }

  Future<void> setChunkSize(int value) async {
    chunkSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chunk_size', value);
  }

  Future<void> setChunkOverlap(int value) async {
    chunkOverlap = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('chunk_overlap', value);
  }

  Future<void> setIndexCacheSize(int value) async {
    indexCacheSize = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('index_cache_size', value);
  }
}
