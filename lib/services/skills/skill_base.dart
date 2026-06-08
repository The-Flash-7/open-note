// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'models/skill_parameter.dart';
import 'models/skill_result.dart';
import '../../utils/cancellation_token.dart';

enum SkillCategory { query, read, write, qa }

abstract class Skill {
  final String id;
  final String name;
  final String description;
  final List<SkillParameter> parameters;
  final SkillCategory category;

  const Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.parameters,
    required this.category,
  });

  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  });

  Map<String, dynamic> toToolDefinition() {
    return {
      'name': id,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': {
          for (final p in parameters)
            p.name: {
              'type': p.type,
              'description': p.description,
              if (p.defaultValue != null) 'default': p.defaultValue,
              if (p.enumValues != null) 'enum': p.enumValues,
            },
        },
        'required': parameters
            .where((p) => p.required)
            .map((p) => p.name)
            .toList(),
      },
    };
  }

  String generateUsageExample();
}
