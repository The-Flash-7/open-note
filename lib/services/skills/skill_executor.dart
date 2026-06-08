// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'models/skill_result.dart';
import 'models/tool_call.dart';
import 'skill_registry.dart';
import '../../utils/cancellation_token.dart';

class SkillExecutor {
  final SkillRegistry _registry;

  SkillExecutor(this._registry);

  Future<SkillResult> executeSkill(
    String skillId,
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    final skill = _registry.getSkill(skillId);
    if (skill == null) {
      return SkillResult.error('未知的 Skill: $skillId');
    }

    final validation = validateParameters(skillId, args);
    if (!validation.isValid) {
      return SkillResult.error('参数验证失败: ${validation.errors.join(', ')}');
    }

    return await skill.execute(args, cancellationToken: cancellationToken);
  }

  Future<List<SkillResult>> executeChain(
    List<ToolCall> toolCalls, {
    CancellationToken? cancellationToken,
  }) async {
    final results = <SkillResult>[];
    for (final call in toolCalls) {
      cancellationToken?.throwIfCancelled();
      final result = await executeSkill(
        call.tool,
        call.args,
        cancellationToken: cancellationToken,
      );
      results.add(result);
      if (!result.success) break;
    }
    return results;
  }

  ValidationResult validateParameters(
    String skillId,
    Map<String, dynamic> args,
  ) {
    final skill = _registry.getSkill(skillId);
    if (skill == null) {
      return ValidationResult.failure(['未知的 Skill: $skillId']);
    }

    final errors = <String>[];
    for (final param in skill.parameters) {
      if (param.required &&
          (!args.containsKey(param.name) || args[param.name] == null)) {
        errors.add('缺少必需参数: ${param.name}');
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}
