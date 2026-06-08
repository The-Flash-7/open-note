// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';

class AIProviderConfig {
  final String id;
  final String name;
  final String displayName;
  final String? baseUrl;
  final String? apiKey;
  final List<String> models;
  final String defaultModel;
  final bool isDefault;
  final String? description;
  final DateTime createdAt;

  AIProviderConfig({
    required this.id,
    required this.name,
    required this.displayName,
    this.baseUrl,
    this.apiKey,
    required this.models,
    required this.defaultModel,
    this.isDefault = false,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'base_url': baseUrl,
      'api_key': apiKey,
      'models': jsonEncode(models),
      'default_model': defaultModel,
      'is_default': isDefault ? 1 : 0,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory AIProviderConfig.fromMap(Map<String, dynamic> map) {
    return AIProviderConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      displayName: map['display_name'] as String,
      baseUrl: map['base_url'] as String?,
      apiKey: map['api_key'] as String?,
      models: map['models'] != null
          ? List<String>.from(jsonDecode(map['models'] as String))
          : [],
      defaultModel: map['default_model'] as String,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  AIProviderConfig copyWith({
    String? id,
    String? name,
    String? displayName,
    String? baseUrl,
    String? apiKey,
    List<String>? models,
    String? defaultModel,
    bool? isDefault,
    String? description,
    DateTime? createdAt,
  }) {
    return AIProviderConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      baseUrl: baseUrl ?? this.baseUrl,
      apiKey: apiKey ?? this.apiKey,
      models: models ?? this.models,
      defaultModel: defaultModel ?? this.defaultModel,
      isDefault: isDefault ?? this.isDefault,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool hasValidConfig() {
    return baseUrl != null &&
        baseUrl!.isNotEmpty &&
        apiKey != null &&
        apiKey!.isNotEmpty &&
        models.isNotEmpty &&
        defaultModel.isNotEmpty;
  }
}

class AIProviderTemplate {
  final String name;
  final String displayName;
  final String baseUrl;
  final List<String> models;
  final String defaultModel;
  final String description;

  AIProviderTemplate({
    required this.name,
    required this.displayName,
    required this.baseUrl,
    required this.models,
    required this.defaultModel,
    required this.description,
  });

  AIProviderConfig toConfig({required String id, String? apiKey}) {
    return AIProviderConfig(
      id: id,
      name: name,
      displayName: displayName,
      baseUrl: baseUrl,
      apiKey: apiKey,
      models: models,
      defaultModel: defaultModel,
      description: description,
      createdAt: DateTime.now(),
    );
  }
}
