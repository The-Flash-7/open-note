// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../models/react_result.dart';

class ParameterDependencyGraph {
  final Map<String, Set<String>> _paramToToolsCache = {};

  Set<String> inferProvidedParameters(ReActStep step) {
    if (step.observation == null) return {};

    final provided = <String>{};

    if (step.observation!.referencedNotes.isNotEmpty) {
      provided.add('note_id');
    }

    if (step.observation!.metadata != null) {
      final metadata = step.observation!.metadata!;

      if (metadata.containsKey('categories')) {
        provided.add('category_id');
      }

      if (metadata.containsKey('tags')) {
        provided.add('tag');
      }

      if (metadata.containsKey('note_ids')) {
        provided.add('note_id');
      }
    }

    return provided;
  }

  void updateFromHistory(List<ReActStep> steps) {
    for (final step in steps) {
      if (step.tool == null) continue;

      final provided = inferProvidedParameters(step);
      if (provided.isNotEmpty) {
        if (!_paramToToolsCache.containsKey(step.tool!)) {
          _paramToToolsCache[step.tool!] = {};
        }
        _paramToToolsCache[step.tool!]!.addAll(provided);
      }
    }
  }

  String generateDependencyTable(List<ReActStep> steps) {
    updateFromHistory(steps);

    if (_paramToToolsCache.isEmpty) {
      return '参数来源对照表：暂无数据';
    }

    final paramToTools = <String, Set<String>>{};
    _paramToToolsCache.forEach((tool, params) {
      for (final param in params) {
        paramToTools.putIfAbsent(param, () => {}).add(tool);
      }
    });

    final buffer = StringBuffer();
    buffer.writeln('参数来源对照表：');
    for (final entry in paramToTools.entries) {
      buffer.writeln('- ${entry.key}：可从 ${entry.value.join("、")} 获取');
    }

    return buffer.toString().trim();
  }

  void clearCache() {
    _paramToToolsCache.clear();
  }
}