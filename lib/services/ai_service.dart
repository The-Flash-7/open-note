// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/ai_provider_config.dart';
import '../utils/cancellation_token.dart';

class AIStreamChunk {
  final String? thinking;
  final String? content;

  AIStreamChunk({this.thinking, this.content});
}

class AIService {
  Dio? _dio;
  AIProviderConfig? _currentConfig;

  void setConfig(AIProviderConfig config) {
    _currentConfig = config;
    _updateDioConfig();
  }

  void _updateDioConfig() {
    if (_currentConfig == null || !_currentConfig!.hasValidConfig()) {
      _dio = null;
      return;
    }

    final baseUrl = _currentConfig!.baseUrl!;
    final headers = <String, String>{};

    if (_currentConfig!.apiKey != null && _currentConfig!.apiKey!.isNotEmpty) {
      if (_currentConfig!.name == 'Claude') {
        headers['x-api-key'] = _currentConfig!.apiKey!;
        headers['anthropic-version'] = '2023-06-01';
      } else {
        headers['Authorization'] = 'Bearer ${_currentConfig!.apiKey!}';
      }
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        headers: headers,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 180),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
  }

  bool hasConfig() {
    return _currentConfig != null && _currentConfig!.hasValidConfig();
  }

  AIProviderConfig? get currentConfig => _currentConfig;

  Future<String> callAI(
    String prompt, {
    String? modelOverride,
    CancellationToken? cancellationToken,
  }) async {
    if (!hasConfig() || _dio == null) {
      throw Exception('AI服务未配置');
    }

    final cancelToken = CancelToken();

    if (cancellationToken != null) {
      cancellationToken.onCancel(() {
        cancelToken.cancel('Operation cancelled by user');
      });
    }

    try {
      final modelName = modelOverride ?? _currentConfig!.defaultModel;
      final baseUrl = _currentConfig!.baseUrl;

      debugPrint('=== AI Call Debug ===');
      debugPrint('Base URL: $baseUrl');
      debugPrint('Model: $modelName');
      debugPrint('API Key: ${_currentConfig!.apiKey?.substring(0, 10)}...');

      if (_currentConfig!.name == 'Claude') {
        final response = await _dio!.post(
          '/messages',
          data: {
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
          },
          cancelToken: cancelToken,
        );
        return response.data['content'][0]['text'] as String;
      } else {
        final endpoint = '$baseUrl/chat/completions';
        debugPrint('Full URL: $endpoint');

        final response = await _dio!.post(
          '/chat/completions',
          data: {
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
          },
          cancelToken: cancelToken,
        );
        return response.data['choices'][0]['message']['content'] as String;
      }
    } on DioException catch (e) {
      debugPrint('DioException type: ${e.type}');
      debugPrint('DioException message: ${e.message}');
      debugPrint('DioException response: ${e.response?.data}');
      debugPrint('DioException statusCode: ${e.response?.statusCode}');
      if (e.type == DioExceptionType.cancel) {
        throw const OperationCancelledException('AI调用已被取消');
      }
      throw Exception('AI调用失败: ${e.message} - ${e.response?.data}');
    } catch (e) {
      debugPrint('AI call error: $e');
      throw Exception('AI调用失败: $e');
    }
  }

  Stream<AIStreamChunk> callAIStream(
    String prompt, {
    String? modelOverride,
    CancellationToken? cancellationToken,
  }) async* {
    if (!hasConfig() || _dio == null) {
      throw Exception('AI服务未配置');
    }

    final cancelToken = CancelToken();

    if (cancellationToken != null) {
      cancellationToken.onCancel(() {
        cancelToken.cancel('Operation cancelled by user');
      });
    }

    try {
      final modelName = modelOverride ?? _currentConfig!.defaultModel;

      final response = await _dio!.post(
        '/chat/completions',
        data: {
          'model': modelName,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'stream': true,
        },
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      final stream = response.data.stream as Stream<List<int>>;
      final decoder = utf8.decoder.bind(stream);
      String buffer = '';

      await for (final chunk in decoder) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast();

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            try {
              final json = jsonDecode(data);
              final delta = json['choices'][0]['delta'];
              final reasoning = delta['reasoning_content'] as String?;
              final content = delta['content'] as String?;
              if (reasoning != null || content != null) {
                yield AIStreamChunk(thinking: reasoning, content: content);
              }
            } catch (e) {
              // 忽略解析错误（可能是空行或格式异常）
            }
          }
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const OperationCancelledException('AI流式调用已被取消');
      }
      throw Exception('AI流式调用失败: ${e.message}');
    } catch (e) {
      throw Exception('AI流式调用失败: $e');
    }
  }

  Future<String> generateSummary(String content) async {
    final prompt = '请为以下内容生成一个简洁的摘要（不超过200字）：\n\n$content';
    return await callAI(prompt);
  }

  Future<List<String>> generateKeywords(String content) async {
    final prompt = '请提取以下内容的关键词（不超过5个），以逗号分隔返回，不要添加任何额外文字：\n\n$content';
    final response = await callAI(prompt);
    return response
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .take(5)
        .toList();
  }

  Future<String> generateCategory(
    String title,
    String content,
    List<String> categories,
  ) async {
    final categoriesStr = categories.isEmpty
        ? '暂无可选分类'
        : categories.map((c) => '• $c').join('\n');

    final prompt =
        '''
请为以下笔记推荐一个分类（只返回分类名称或"无分类"，不要解释）：

标题：$title
内容摘要：${content.length > 500 ? content.substring(0, 500) : content}

可选分类列表：
$categoriesStr
• 无分类（如果笔记不属于以上任何分类）

要求：
1. 分类必须从可选分类列表中选择（包含"无分类"）
2. 如果不符合任何分类，返回"无分类"
3. 不要自创分类名称
4. 只返回分类名称，不要添加任何解释

直接返回一个分类名称或"无分类"。
''';
    final response = await callAI(prompt);
    final category = response.trim();

    // 处理"无分类"返回值
    if (category == '无分类') {
      return ''; // 空字符串表示无分类
    }
    return category;
  }

  Future<List<String>> generateSuggestedTags(
    String title,
    String content,
    List<String> existingTags,
  ) async {
    final existingTagsStr = existingTags.isEmpty
        ? '暂无现有标签'
        : existingTags.join(', ');
    final prompt =
        '''
请为以下笔记内容推荐合适的标签（从现有标签中选择或创建新标签）：

标题：$title
内容摘要：${content.length > 500 ? content.substring(0, 500) : content}

现有标签库：$existingTagsStr

要求：
1. 优先从现有标签库中选择合适的标签
2. 如果现有标签不合适，可以创建1-2个新标签
3. 总共推荐不超过3个标签
4. 以逗号分隔返回标签名称，不要添加任何额外文字
''';
    final response = await callAI(prompt);
    return response
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();
  }

  Future<String> cleanContent({
    required String title,
    required String rawContent,
    String? author,
    String? publishDate,
  }) async {
    final prompt =
        '''
请对以下网页内容进行深度清洗和Markdown格式化：

标题：$title
作者：${author ?? '未知'}
日期：${publishDate ?? '未知'}

原始内容：
$rawContent

清洗要求：
1. 结构整理：保持正确的标题层级，确保正文在对应标题下方
2. 内容清洗：去除导航、广告、多余空行、HTML残留
3. Markdown格式化：使用##、###标注标题，代码块用```language包裹
4. 内容保留：保留所有正文内容，不删减重要信息

直接返回清洗后的Markdown内容，不要解释。
''';

    return await callAI(prompt);
  }

  Future<Map<String, dynamic>> generateSummaryAndKeywords(
    String content,
  ) async {
    final prompt =
        '''
请为以下内容生成摘要和关键词，严格按照指定格式返回：

【摘要】
（在这里写摘要内容，要求：简洁准确，字数控制在150-200字之间，不要超过200字）

【关键词】
（在这里写关键词，要求：提取3-5个关键词，用逗号分隔，不要添加编号或其他符号）

---格式要求---
1. 必须使用【摘要】和【关键词】作为标记，不要使用其他格式
2. 摘要字数严格控制在150-200字之间
3. 关键词数量控制在3-5个，用逗号分隔，格式如：关键词1,关键词2,关键词3
4. 不要添加任何解释、编号或其他额外内容
5. 不要使用markdown格式（如##、**等）

---示例格式---
【摘要】
这是一篇关于OpenNote跨平台智能笔记软件的介绍，介绍了OpenNote智能笔记的功能和新特性。文章详细讲解了OpenNote强大的笔记Agent能力，个人笔记知识库可以使用自然语言对话进行搜索和问答。

【关键词】
OpenNote, 跨平台, 智能笔记, Agent, 笔记知识库

---待处理内容---
$content
''';

    final response = await callAI(prompt);
    return _parseSummaryAndKeywords(response);
  }

  Future<Map<String, dynamic>> generateCategoryAndTags(
    String title,
    String content,
    List<String> existingTags,
    Map<String, String> categories,
  ) async {
    final existingTagsStr = existingTags.isEmpty
        ? '暂无现有标签'
        : existingTags.join(', ');

    final categoriesStr = categories.isEmpty
        ? '暂无可选分类'
        : categories.entries
              .map((e) => '• ${e.value} (ID: ${e.key})')
              .join('\n');

    final prompt =
        '''
请为以下笔记推荐分类和标签，严格按照指定格式返回：

【分类】
（完整分类路径，用于显示）

【分类ID】
（分类ID，用于存储）

【标签】
（在这里写标签，要求：推荐2-3个标签，用逗号分隔，不要添加编号）

---可选分类列表---
$categoriesStr
• 无分类（如果笔记不属于以上任何分类，【分类】返回"无分类"，【分类ID】返回空）

---重要提示---
1. 【分类】和【分类ID】必须对应，路径和ID要匹配
2. 【分类】返回完整路径（如"学习-数学-作业")
3. 【分类ID】返回对应的ID（如"wxy1242")
4. 如果笔记不属于任何分类，【分类】返回"无分类"，【分类ID】返回空
5. 不要自创分类路径或ID
6. 不要添加任何解释或编号

---标签推荐规则---
1. 优先从现有标签库中选择合适的标签：$existingTagsStr
2. 如果现有标签不合适，可以创建1-2个新标签
3. 总共推荐不超过3个标签
4. 标签要简洁准确，避免过于宽泛

---格式要求---
1. 必须使用【分类】、【分类ID】和【标签】作为标记，不要使用其他格式
2. 【分类】标记后直接写完整路径（如"学习-数学-作业")
3. 【分类ID】标记后直接写对应的ID（如"wxy1242")
4. 如果笔记不属于任何分类，【分类】返回"无分类"，【分类ID】返回空
5. 标签数量控制在2-3个，用逗号分隔，格式如：标签1,标签2,标签3
6. 不要添加任何解释、编号或其他额外内容
7. 不要使用markdown格式（如##、**等）

---示例格式---
【分类】
学习-数学-作业

【分类ID】
wxy1242

【标签】
OpenNote, 跨平台应用, 笔记知识库

---笔记信息---
标题：$title
内容摘要：${content.length > 500 ? content.substring(0, 500) : content}
''';

    final response = await callAI(prompt);
    return _parseCategoryAndTags(response);
  }

  Future<Map<String, dynamic>> initializeNoteFromUrl({
    required String title,
    required String rawContent,
    String? author,
    String? publishDate,
    String? modelOverride,
    CancellationToken? cancellationToken,
    List<String> existingTags = const [],
    Map<String, String> categories = const {},
  }) async {
    final existingTagsStr = existingTags.isEmpty
        ? '暂无现有标签'
        : existingTags.join(', ');

    final categoriesStr = categories.isEmpty
        ? '暂无可选分类'
        : categories.entries
              .map((e) => '• ${e.value} (ID: ${e.key})')
              .join('\n');

    final prompt =
        '''
请对以下网页内容进行完整处理，严格按照指定格式返回：

【Markdown内容】
（深度清洗并格式化为Markdown，保持正确层级，去除广告导航，保留所有正文内容）

【摘要】
（简洁准确的摘要，150-200字，不超过200字）

【关键词】
（提取3-5个关键词，用逗号分隔，格式：关键词1,关键词2,关键词3）

【分类】
（完整分类路径，用于显示）

【分类ID】
（分类ID，用于存储）

【标签】
（推荐2-3个标签，用逗号分隔，优先从现有标签库选择：$existingTagsStr）

---可选分类列表---
$categoriesStr
• 无分类（如果笔记不属于以上任何分类，【分类】返回"无分类"，【分类ID】返回空）

---重要提示---
1. 【分类】和【分类ID】必须对应，路径和ID要匹配
2. 【分类】返回完整路径（如"学习-数学-作业")
3. 【分类ID】返回对应的ID（如"wxy1242")
4. 如果笔记内容不符合任何分类，【分类】返回"无分类"，【分类ID】返回空
5. 不要自创分类路径或ID

---格式要求---
1. 必须使用【Markdown内容】【摘要】【关键词】【分类】【分类ID】【标签】作为标记
2. 每个标记后直接写内容，不要添加解释或编号
3. Markdown内容要完整，不要删减重要信息
4. 摘要严格控制在150-200字
5. 关键词3-5个，逗号分隔
6. 【分类】标记后直接写完整路径（如"学习-数学-作业")
7. 【分类ID】标记后直接写对应的ID（如"wxy1242")
8. 如果笔记不属于任何分类，【分类】返回"无分类"，【分类ID】返回空
9. 标签优先复用现有标签，可创建1-2个新标签
10. 不要使用额外的markdown格式标记

---示例格式---
【Markdown内容】
## OpenNote智能笔记使用指南

OpenNote是一款由个人开发者litongshuai开发的跨平台AI智能笔记...

### 安装方法
1.下载对应平台的安装文件
2.双击打开进行安装...

【摘要】
这是一篇关于OpenNote跨平台智能笔记软件的介绍，介绍了OpenNote智能笔记的功能和新特性。文章详细讲解了OpenNote强大的笔记Agent能力，个人笔记知识库可以使用自然语言对话进行搜索和问答。

【关键词】
OpenNote, 跨平台, 智能笔记, Agent, 笔记知识库

【分类】
学习-数学-作业

【分类ID】
wxy1242

【标签】
OpenNote, 跨平台应用, 笔记知识库

---网页信息---
标题：$title
作者：${author ?? '未知'}
日期：${publishDate ?? '未知'}

---原始内容---
$rawContent
''';

    final response = await callAI(
      prompt,
      modelOverride: modelOverride,
      cancellationToken: cancellationToken,
    );
    return _parseNoteInitialization(response);
  }

  Map<String, dynamic> _parseNoteInitialization(String response) {
    final content = _extractSection(response, 'Markdown内容');
    final summary = _extractSection(response, '摘要');
    final keywordsStr = _extractSection(response, '关键词');
    final categoryPath = _extractSection(response, '分类');
    final categoryId = _extractSection(response, '分类ID');
    final tagsStr = _extractSection(response, '标签');

    String finalContent = content.isNotEmpty ? content : response;

    String? finalSummary = summary.isNotEmpty ? summary : null;

    List<String> keywords = keywordsStr
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .take(5)
        .toList();

    // 存储：使用【分类ID】的值
    String? finalCategory;
    if (categoryId.isEmpty || categoryPath == '无分类') {
      finalCategory = null;
    } else {
      finalCategory = categoryId;
    }

    List<String> tags = tagsStr
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();

    if (response.isEmpty) {
      throw FormatException('AI返回完全为空，无法处理');
    }

    return {
      'content': finalContent,
      'summary': finalSummary,
      'keywords': keywords,
      'category': finalCategory,
      'categoryPath': categoryPath,
      'tags': tags,
    };
  }

  Map<String, dynamic> _parseSummaryAndKeywords(String response) {
    final summary = _extractSection(response, '摘要');
    final keywordsStr = _extractSection(response, '关键词');

    String? finalSummary = summary.isNotEmpty ? summary : null;

    List<String> keywords = keywordsStr
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .take(5)
        .toList();

    if (response.isEmpty) {
      throw FormatException('AI返回完全为空，无法处理');
    }

    // debugPrint('=== 解析结果 ===');
    // debugPrint('摘要: ${finalSummary?.length ?? "null"}');
    // debugPrint('关键词数量: ${keywords.length}');

    return {'summary': finalSummary, 'keywords': keywords};
  }

  Map<String, dynamic> _parseCategoryAndTags(String response) {
    final categoryPath = _extractSection(response, '分类');
    final categoryId = _extractSection(response, '分类ID');
    final tagsStr = _extractSection(response, '标签');

    // 存储：使用【分类ID】的值
    String? finalCategory;
    if (categoryId.isEmpty || categoryPath == '无分类') {
      finalCategory = null;
    } else {
      finalCategory = categoryId;
    }

    List<String> tags = tagsStr
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList();

    if (response.isEmpty) {
      throw FormatException('AI返回完全为空，无法处理');
    }

    return {
      'category': finalCategory,
      'categoryPath': categoryPath,
      'tags': tags,
    };
  }

  String _extractSection(String response, String marker) {
    final patterns = ['【$marker】', '[$marker]', '$marker:', '$marker='];

    for (final pattern in patterns) {
      final startIndex = response.indexOf(pattern);
      if (startIndex == -1) continue;

      int endIndex = response.length;

      final nextMarkerStart = response.indexOf(
        '【',
        startIndex + pattern.length,
      );
      final nextBracketStart = response.indexOf(
        '[',
        startIndex + pattern.length,
      );

      if (nextMarkerStart != -1) endIndex = nextMarkerStart;
      if (nextBracketStart != -1 && nextBracketStart < endIndex) {
        endIndex = nextBracketStart;
      }

      final content = response
          .substring(startIndex + pattern.length, endIndex)
          .trim();

      if (content.isNotEmpty) {
        return content;
      }
    }

    return '';
  }
}
