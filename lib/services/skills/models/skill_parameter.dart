// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class SkillParameter {
  final String name;
  final String type;
  final String description;
  final bool required;
  final dynamic defaultValue;
  final List<String>? enumValues;

  const SkillParameter({
    required this.name,
    required this.type,
    required this.description,
    this.required = true,
    this.defaultValue,
    this.enumValues,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'required': required,
      if (defaultValue != null) 'default': defaultValue,
      if (enumValues != null) 'enum': enumValues,
    };
  }
}
