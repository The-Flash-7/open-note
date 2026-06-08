// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';
import '../../../providers/category_provider.dart';
import '../../../utils/category_path_helper.dart';
import '../../../services/readability_service.dart';
import '../../../services/dart_scraper_service.dart';
import '../../../models/article_data.dart';

class NoteCreateFromUrlSkill extends Skill {
  final AIService? aiService;
  CategoryProvider? _categoryProvider;

  set categoryProvider(CategoryProvider? provider) {
    _categoryProvider = provider;
  }

  NoteCreateFromUrlSkill({this.aiService})
    : super(
        id: 'note_create_from_url',
        name: '从URL创建笔记',
        description:
            '从网页URL提取内容并创建笔记。自动提取标题、摘要、关键词、推荐分类和标签。可指定分类ID，不指定则自动选择。需要向用户声明，并非一定能提取，可能因为目标网页的限制等原因而无法获取内容。',
        parameters: [
          const SkillParameter(
            name: 'url',
            type: 'string',
            description: '网页URL（如 https://example.com/article）',
            required: true,
          ),
          const SkillParameter(
            name: 'categoryId',
            type: 'string',
            description: '指定分类ID（可选。不指定则自动选择分类）',
            required: false,
          ),
          const SkillParameter(
            name: 'tags',
            type: 'array',
            description: '指定标签（可选。会与智能推荐的标签合并）',
            required: false,
          ),
        ],
        category: SkillCategory.write,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (aiService == null || !aiService!.hasConfig()) {
        return SkillResult.error('AI 服务未配置，无法从URL创建笔记');
      }

      final url = args['url'] as String?;
      if (url == null || url.isEmpty) {
        return SkillResult.error('URL不能为空');
      }

      // 验证URL格式
      String processedUrl = url.trim();
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      }

      final uri = Uri.tryParse(processedUrl);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return SkillResult.error('URL格式不正确');
      }

      final specifiedCategoryId = args['categoryId'] as String?;
      final specifiedTags = (args['tags'] as List?)?.cast<String>();

      debugPrint('[NoteCreateFromUrl] 提取URL: $processedUrl');

      // 1. 使用 ReadabilityService 提取网页内容
      final readabilityService = ReadabilityService();
      ArticleData? articleData;

      try {
        articleData = await readabilityService.extractFromUrl(processedUrl);
      } finally {
        readabilityService.dispose();
      }

      if (articleData == null) {
        // 尝试使用 DartScraperService fallback
        debugPrint(
          '[NoteCreateFromUrl] Readability 提取失败，尝试 DartScraperService',
        );
        final scraperService = DartScraperService();
        try {
          final scrapedData = await scraperService.scrapeUrl(processedUrl);
          if (scrapedData != null) {
            articleData = ArticleData(
              title: scrapedData['title'] ?? 'Untitled',
              textContent: scrapedData['content'] ?? '',
              htmlContent: scrapedData['content'] ?? '',
              author: scrapedData['author'],
              publishDate: scrapedData['publish_date'],
              url: processedUrl,
            );
          }
        } finally {
          scraperService.dispose();
        }
      }

      if (articleData == null || articleData.textContent.isEmpty) {
        return SkillResult.error('网页内容提取失败，无法创建笔记');
      }

      debugPrint(
        '[NoteCreateFromUrl] 提取成功 - 标题: ${articleData.title}, 内容长度: ${articleData.textContent.length}',
      );

      // 2. 获取分类路径映射和现有标签
      Map<String, String> categoryPaths = {};
      List<String> existingTags = [];

      if (_categoryProvider != null) {
        categoryPaths = CategoryPathHelper.generateCategoryPathsWithId(
          _categoryProvider!,
        );
      }

      // 3. 调用 AI 初始化笔记
      final initializedData = await aiService!.initializeNoteFromUrl(
        title: articleData.title,
        rawContent: articleData.textContent,
        author: articleData.author,
        publishDate: articleData.publishDate,
        cancellationToken: cancellationToken,
        existingTags: existingTags,
        categories: categoryPaths,
      );

      // 4. 提取 AI 返回的数据
      final aiTitle = initializedData['title'] as String? ?? articleData.title;
      final aiContent =
          initializedData['content'] as String? ?? articleData.textContent;
      final aiSummary = initializedData['summary'] as String?;
      final aiKeywords =
          (initializedData['keywords'] as List?)?.cast<String>() ?? [];
      final aiCategoryId = initializedData['category'] as String?;
      final aiTags = (initializedData['tags'] as List?)?.cast<String>() ?? [];

      // 5. 合并标签（用户指定的 + AI推荐的）
      final allTags = <String>{};
      if (specifiedTags != null) allTags.addAll(specifiedTags);
      allTags.addAll(aiTags);

      // 6. 确定最终分类ID（用户指定的优先，否则使用AI推荐的）
      final finalCategoryId =
          specifiedCategoryId ??
          (aiCategoryId != null && aiCategoryId.isNotEmpty
              ? aiCategoryId
              : null);

      debugPrint(
        '[NoteCreateFromUrl] AI 处理完成 - 标题: $aiTitle, 分类: $finalCategoryId',
      );

      // 7. 创建笔记
      final noteId = await OpenNoteTools.createNote(
        title: aiTitle,
        content: aiContent,
        category: finalCategoryId,
        tags: allTags.toList(),
        sourceUrl: processedUrl,
        autoGenerateSummary: aiSummary == null, // 如果AI没有生成摘要，则自动生成
        preGeneratedSummary: aiSummary,
        preGeneratedKeywords: aiKeywords,
      );

      if (noteId == null) {
        return SkillResult.error('笔记创建失败');
      }

      final createdNote = await OpenNoteTools.getNoteById(noteId);

      return SkillResult.ok(
        message: '已从URL创建笔记"$aiTitle"',
        referencedNotes: createdNote != null ? [createdNote] : [],
        metadata: {
          'noteId': noteId,
          'title': aiTitle,
          'categoryId': finalCategoryId,
          'summary': aiSummary,
          'keywords': aiKeywords,
          'tags': allTags.toList(),
          'sourceUrl': processedUrl,
        },
      );
    } catch (e) {
      debugPrint('[NoteCreateFromUrl] 异常: $e');
      return SkillResult.error('从URL创建笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_create_from_url", "args": {"url": "https://example.com/article"}}';
  }
}
