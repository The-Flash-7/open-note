// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class ToolCall {
  final String tool;
  final Map<String, dynamic> args;

  const ToolCall({required this.tool, required this.args});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      tool: json['tool'] as String? ?? '',
      args: (json['args'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'tool': tool, 'args': args};
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({required this.isValid, this.errors = const []});

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.failure(List<String> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }
}
