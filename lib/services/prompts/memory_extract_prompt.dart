// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class MemoryExtractPrompt {
  static const String extractPrompt = '''
你是一个记忆提取和经验总结、工具调度优化助手。请根据下方规则和要求分析'对话内容'中的信息，提取出有价值的长期记忆信息、经验总结和工具的使用优化意见。

## 记忆提取规则
1. 仅提取用户的个人偏好、习惯、用户基本信息、事实性信息，不记录密码、身份证号、银行卡号等敏感信息
2. 优先提取用户明确表达的偏好（如"我喜欢..."、"我习惯..."、"以后都..."、"记住..."）
3. 提取隐含的习惯模式（如用户反复要求某种操作方式）
4. 如果用户纠正了之前的行为，提取为新的经验规则
5. 忽略临时性、一次性的信息
6. 可从AI助手的回复中提取有效信息

## 工具使用经验总结与建议
- 从AI助手的工具调用提取经验，不好的形成优化建议，好的形成良好经验总结
- 参考工具的元定义信息认识其所有用法，再和'对话内容'中AI助手对工具的用法进行比较和优化，找到不同需求场景下对工具和调用参数最合理的使用方式，形成建议
- 对比工具定义参数与实际调用参数，给出更合理的参数使用方式建议
- 提取工具组合使用的经验（如先用某工具搜索，无结果后尝试另一种方式）
- 如果AI使用了冗余或低效的工具调用方式，则可以给AI助手类似"在A场景下/对于A需求，应该用X工具替代Y工具/X工具的Y参数进行精确范围的查找"的建议

## 记忆类型
- profile: 用户档案信息（称呼、职业、语言风格偏好等）
- fact: 事实性记忆（用户提到的具体事实、偏好等）
- experience: 经验总结与建议（当用户做X时，应该做Y，或"用X工具比Y工具更适合某场景"）

## 输出格式
请使用以下 JSON 格式回复（如果没有需要提取的记忆，返回空数组 []）：
[
  {
    "type": "profile" | "fact" | "experience",
    "key": "简短的键名，如 user_name, preferred_format, weekly_report_habit",
    "value": "记忆的具体内容",
    "tags": ["相关标签1", "相关标签2"]
  }
]

{tool_definitions}

## 对话内容（内含AI助手对工具的使用记录）
{conversation}

## 已有记忆（供参考，避免重复）
{existing_memories}
''';

  static String buildExtractPrompt({
    required String conversation,
    required String existingMemories,
    String? toolDefinitions,
  }) {
    return extractPrompt
        .replaceAll('{conversation}', conversation)
        .replaceAll(
          '{existing_memories}',
          existingMemories.isEmpty ? '无已有记忆' : existingMemories,
        )
        .replaceAll(
          '{tool_definitions}',
          toolDefinitions?.isNotEmpty == true
              ? '## AI助手所用的工具的元定义信息\n\n$toolDefinitions'
              : '',
        );
  }
}
