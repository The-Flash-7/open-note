// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

class DartScraperService {
  Dio? _dio;
  HttpClient? _httpClient;

  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  Future<Map<String, dynamic>?> scrapeUrl(String url) async {
    _httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;

    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'User-Agent': _userAgent,
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          'Cache-Control': 'max-age=0',
        },
      ),
    );

    (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      // 如果 _httpClient 已经存在且配置好，可以直接返回它
      if (_httpClient != null) {
        // 确保回调已设置
        _httpClient!.badCertificateCallback = (cert, host, port) => true;
        return _httpClient!;
      }
      // 否则创建新的
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    try {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        debugPrint('Invalid URL: $url');
        return null;
      }

      debugPrint('Fetching URL: $url');

      final response = await _dio!.getUri(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response length: ${response.data?.length ?? 0}');

      if (response.statusCode != 200) {
        debugPrint('HTTP error: ${response.statusCode}');
        return null;
      }

      final body = response.data as String;
      if (body.isEmpty) {
        debugPrint('Empty response body');
        return null;
      }

      final document = parser.parse(body);

      final title = _extractTitle(document);
      final content = _extractContent(document);
      final author = _extractAuthor(document);
      final publishDate = _extractPublishDate(document);

      debugPrint('Extracted title: $title');
      debugPrint('Content length: ${content.length}');

      return {
        'title': title,
        'content': content,
        'markdown': content,
        'author': author,
        'publish_date': publishDate,
        'url': url,
      };
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      return _createErrorResult('请求超时，网站响应过慢');
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.type} - ${e.message}');
      return _createErrorResult('网络连接失败: ${e.message}');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return _createErrorResult('提取失败: $e');
    } finally {
      _dio?.close();
      _httpClient?.close();
    }
  }

  Map<String, dynamic> _createErrorResult(String error) {
    return {'title': '提取失败', 'content': error, 'error': error};
  }

  String _extractTitle(dom.Document document) {
    final selectors = [
      'meta[property="og:title"]',
      'meta[name="twitter:title"]',
      'h1',
      'title',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        if (element.localName == 'meta') {
          final content = element.attributes['content'];
          if (content != null && content.isNotEmpty) {
            return _cleanText(content);
          }
        } else {
          final text = element.text;
          if (text.isNotEmpty) {
            return _cleanText(text);
          }
        }
      }
    }

    return 'Untitled';
  }

  String _extractContent(dom.Document document) {
    final removeSelectors = [
      'script',
      'style',
      'nav',
      'header',
      'footer',
      'aside',
      'form',
      'iframe',
      'noscript',
      '.sidebar',
      '.navigation',
      '.menu',
      '.comment',
      '.ads',
      '.advertisement',
      '.social-share',
      '.related-posts',
    ];

    for (final selector in removeSelectors) {
      document
          .querySelectorAll(selector)
          .forEach((element) => element.remove());
    }

    final contentSelectors = [
      'article',
      '[role="main"]',
      'main',
      '.article-content',
      '.content',
      '.post-content',
      '.entry-content',
      '#content',
      '#main',
    ];

    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final text = _extractTextFromElement(element);
        if (text.length > 200) {
          return _formatAsMarkdown(text);
        }
      }
    }

    final paragraphs = document.querySelectorAll('p');
    final textParts = paragraphs
        .map((p) => _cleanText(p.text))
        .where((t) => t.length > 30)
        .toList();

    if (textParts.isNotEmpty) {
      return _formatAsMarkdown(textParts.join('\n\n'));
    }

    final body = document.querySelector('body');
    if (body != null) {
      final text = _cleanText(body.text);
      if (text.length > 100) {
        return _formatAsMarkdown(text);
      }
    }

    return '未能提取到有效内容';
  }

  String _extractTextFromElement(dom.Element element) {
    final buffer = StringBuffer();

    element.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach((heading) {
      final level = int.parse(heading.localName!.substring(1));
      final prefix = '#' * level;
      buffer.writeln('$prefix ${_cleanText(heading.text)}\n');
    });

    element.querySelectorAll('p').forEach((p) {
      final text = _cleanText(p.text);
      if (text.isNotEmpty && text.length > 20) {
        buffer.writeln('$text\n');
      }
    });

    element.querySelectorAll('ul, ol').forEach((list) {
      final isOrdered = list.localName == 'ol';
      var index = 1;
      list.querySelectorAll('li').forEach((li) {
        final prefix = isOrdered ? '$index.' : '-';
        buffer.writeln('$prefix ${_cleanText(li.text)}');
        if (isOrdered) index++;
      });
      buffer.writeln();
    });

    element.querySelectorAll('blockquote').forEach((quote) {
      final text = _cleanText(quote.text);
      if (text.isNotEmpty) {
        buffer.writeln('> $text\n');
      }
    });

    element.querySelectorAll('pre, code').forEach((code) {
      final text = code.text;
      if (text.isNotEmpty) {
        buffer.writeln('```\n$text\n```\n');
      }
    });

    return buffer.toString();
  }

  String? _extractAuthor(dom.Document document) {
    final selectors = [
      'meta[name="author"]',
      'meta[property="article:author"]',
      '.author-name',
      '.author',
      '[rel="author"]',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        if (element.localName == 'meta') {
          final content = element.attributes['content'];
          if (content != null && content.isNotEmpty) {
            return _cleanText(content);
          }
        } else {
          final text = element.text;
          if (text.isNotEmpty) {
            return _cleanText(text);
          }
        }
      }
    }

    return null;
  }

  String? _extractPublishDate(dom.Document document) {
    final selectors = [
      'meta[property="article:published_time"]',
      'meta[name="date"]',
      'meta[name="publish-date"]',
      'time[datetime]',
      '.publish-date',
      '.date',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        if (element.localName == 'meta') {
          final content = element.attributes['content'];
          if (content != null && content.isNotEmpty) {
            return content;
          }
        } else if (element.localName == 'time') {
          final datetime = element.attributes['datetime'];
          if (datetime != null) {
            return datetime;
          }
        } else {
          final text = element.text;
          if (text.isNotEmpty) {
            return _cleanText(text);
          }
        }
      }
    }

    return null;
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n+'), ' ')
        .trim();
  }

  String _formatAsMarkdown(String content) {
    final lines = content.split('\n');
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        buffer.writeln();
        continue;
      }

      if (trimmed.length < 60 &&
          !trimmed.endsWith('.') &&
          !trimmed.endsWith(',')) {
        buffer.writeln('\n## $trimmed\n');
      } else {
        buffer.writeln(trimmed);
      }
    }

    return buffer.toString();
  }

  void dispose() {
    _dio?.close();
    _httpClient?.close();
  }
}
