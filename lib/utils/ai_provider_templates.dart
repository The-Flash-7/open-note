// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../models/ai_provider_config.dart';

class AIProviderTemplates {
  static final List<AIProviderTemplate> templates = [
    AIProviderTemplate(
      name: 'DeepSeek',
      displayName: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      models: ['deepseek-v4-flash', 'deepseek-v4-pro'],
      defaultModel: 'deepseek-v4-flash',
      description: 'DeepSeek',
    ),
    AIProviderTemplate(
      name: 'OpenAI',
      displayName: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      models: [
        'gpt-5.5-chat-latest',
        'gpt-5.5-thinking',
        'gpt-5.5-pro',
        'gpt-5.4-thinking',
        'gpt-5.4-pro',
        'gpt-5.3-chat-latest',
        'gpt-5.2',
        'gpt-5.2-chat-latest',
        'gpt-5.2-pro',
        'gpt-4o',
        'gpt-4o-mini',
        'gpt-4',
        'gpt-4-32k',
        'gpt-3.5-turbo',
        'gpt-3.5-turbo-16k',
        'text-embedding-3-small',
        'text-embedding-3-large',
        'omni-moderation-latest',
      ],
      defaultModel: 'gpt-4o',
      description: 'OpenAI官方API',
    ),
    AIProviderTemplate(
      name: '阿里云百炼Token Plan',
      displayName: '阿里云百炼 Token Plan',
      baseUrl:
          'https://token-plan.cn-beijing.maas.aliyuncs.com/compatible-mode/v1',
      models: ['qwen3.6-plus', 'glm-5', 'MiniMax-M2.5', 'deepseek-v3.2'],
      defaultModel: 'qwen3.6-plus',
      description: '阿里云百炼Token Plan，支持Qwen、GLM、MiniMax、DeepSeek等多模型',
    ),
    AIProviderTemplate(
      name: '阿里云百炼Coding Plan',
      displayName: '阿里云百炼 Coding Plan',
      baseUrl: 'https://coding.dashscope.aliyuncs.com/v1',
      models: [
        'qwen3.6-plus',
        'qwen3.5-plus',
        'qwen3-max-2026-01-23',
        'qwen3-coder-next',
        'qwen3-coder-plus',
        'MiniMax-M2.5',
        'glm-5',
        'glm-4.7',
        'kimi-k2.5',
      ],
      defaultModel: 'qwen3-coder-plus',
      description: '阿里云百炼Coding Plan，包含Qwen3、GLM、Kimi等多模型',
    ),
    AIProviderTemplate(
      name: '火山方舟Coding Plan',
      displayName: '火山方舟 Coding Plan',
      baseUrl: 'https://ark.cn-beijing.volces.com/api/coding/v3',
      models: [
        'doubao-seed-2.0-code',
        'doubao-seed-2.0-pro',
        'doubao-seed-2.0-lite',
        'doubao-seed-code',
        'minimax-latest',
        'glm-5.1',
        'glm-4.7',
        'deepseek-v3.2',
        'kimi-k2.6',
        'kimi-k2.5',
      ],
      defaultModel: 'doubao-seed-2.0-code',
      description: '火山方舟Coding Plan，支持豆包、MiniMax、GLM、DeepSeek、Kimi等多模型',
    ),
    AIProviderTemplate(
      name: '腾讯混元',
      displayName: '腾讯混元',
      baseUrl: 'https://api.hunyuan.tencent.com/v1',
      models: [
        'hunyuan-lite',
        'hunyuan-standard',
        'hunyuan-pro',
        'hunyuan-turbo',
      ],
      defaultModel: 'hunyuan-standard',
      description: '腾讯混元大模型',
    ),
    AIProviderTemplate(
      name: '火山豆包',
      displayName: '火山豆包',
      baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      models: ['doubao-pro-32k', 'doubao-lite-32k', 'doubao-pro-128k'],
      defaultModel: 'doubao-pro-32k',
      description: '字节跳动豆包大模型',
    ),
    AIProviderTemplate(
      name: '智谱GLM Coding Plan',
      displayName: '智谱GLM Coding Plan',
      baseUrl: 'https://open.bigmodel.cn/api/coding/paas/v4',
      models: ['GLM-5.1', 'GLM-5-Turbo', 'GLM-4.7', 'GLM-4.5-Air'],
      defaultModel: 'GLM-5.1',
      description: '智谱GLM Coding Plan，专为编程场景优化的GLM模型系列',
    ),
    AIProviderTemplate(
      name: '智谱GLM',
      displayName: '智谱GLM',
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      models: ['glm-4', 'glm-4-flash', 'glm-4-plus', 'glm-3-turbo'],
      defaultModel: 'glm-4-flash',
      description: '智谱ChatGLM',
    ),
    AIProviderTemplate(
      name: '百度千帆',
      displayName: '百度千帆',
      baseUrl:
          'https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat',
      models: ['ERNIE-Bot-4', 'ERNIE-Bot-turbo', 'ERNIE-Bot'],
      defaultModel: 'ERNIE-Bot-turbo',
      description: '百度文心一言',
    ),
    AIProviderTemplate(
      name: 'Moonshot',
      displayName: 'Moonshot (Kimi)',
      baseUrl: 'https://api.moonshot.cn/v1',
      models: ['moonshot-v1-8k', 'moonshot-v1-32k', 'moonshot-v1-128k'],
      defaultModel: 'moonshot-v1-8k',
      description: 'Moonshot Kimi',
    ),
    AIProviderTemplate(
      name: 'Claude',
      displayName: 'Claude',
      baseUrl: 'https://api.anthropic.com/v1',
      models: [
        'claude-3-5-sonnet-20241022',
        'claude-3-5-haiku-20241022',
        'claude-3-opus-20240229',
      ],
      defaultModel: 'claude-3-5-sonnet-20241022',
      description: 'Anthropic Claude',
    ),
    AIProviderTemplate(
      name: 'Ollama本地',
      displayName: 'Ollama (本地)',
      baseUrl: 'http://localhost:11434/v1',
      models: ['llama3', 'llama2', 'mistral', 'codellama', 'qwen2'],
      defaultModel: 'llama3',
      description: 'Ollama本地部署',
    ),
    AIProviderTemplate(
      name: '自定义',
      displayName: '完全自定义',
      baseUrl: '',
      models: [],
      defaultModel: '',
      description: '完全自定义厂商、URL和模型',
    ),
  ];

  static AIProviderTemplate? findByName(String name) {
    try {
      return templates.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }
}
