// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'skill_base.dart';

class SkillRegistry {
  final Map<String, Skill> _skills = {};

  void register(Skill skill) {
    _skills[skill.id] = skill;
  }

  Skill? getSkill(String id) {
    return _skills[id];
  }

  List<Skill> getAllSkills() {
    return _skills.values.toList();
  }

  List<Skill> getSkillsByCategory(SkillCategory category) {
    return _skills.values.where((s) => s.category == category).toList();
  }

  bool hasSkill(String id) {
    return _skills.containsKey(id);
  }

  String generateToolDefinitionsPrompt() {
    final definitions = _skills.values
        .map((s) => s.toToolDefinition())
        .toList();
    return jsonEncode(definitions);
  }

  String generateToolSummariesPrompt() {
    final summaries = _skills.values.map((s) => {
      'name': s.id,
      'brief': s.description.split('.').first,
    }).toList();
    return jsonEncode(summaries);
  }

  String generateToolRequirementsPrompt() {
    final buffer = StringBuffer();

    for (final skill in _skills.values) {
      final requiredParams = skill.parameters
          .where((p) => p.required)
          .map((p) => p.name)
          .toList();

      if (requiredParams.isNotEmpty) {
        buffer.writeln('- ${skill.id}：需要 ${requiredParams.join("、")}（必需）');
      }
    }

    return buffer.toString().trim();
  }
}
