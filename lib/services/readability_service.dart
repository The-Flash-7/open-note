// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:reader_mode/reader_mode.dart';
import 'package:charset/charset.dart';
import 'package:brotli/brotli.dart';
import '../models/article_data.dart';

class ReadabilityService {
  Dio? _dio;
  HttpClient? _httpClient;

  static const String _userAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  Future<ArticleData?> extractFromUrl(String url) async {
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
          'Referer': url,
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'cross-site',
          'Sec-Fetch-User': '?1',
          'Sec-CH-UA':
              '"Chromium";v="120", "Google Chrome";v="120", "Not-A.Brand";v="99"',
          'Sec-CH-UA-Mobile': '?0',
          'Sec-CH-UA-Platform': '"macOS"',
          'Sec-CH-UA-Platform-Version': '"10.15.7"',
          'Sec-CH-UA-Arch': '"x86"',
          'Sec-CH-UA-Full-Version-List':
              '"Chromium";v="120.0.0.0", "Google Chrome";v="120.0.0.0", "Not-A.Brand";v="99.0.0.0"',
        },
      ),
    );

    (_dio!.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      if (_httpClient != null) {
        _httpClient!.badCertificateCallback = (cert, host, port) => true;
        return _httpClient!;
      }
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

      debugPrint('ReadabilityService: Fetching URL: $url');

      final response = await _dio!.getUri(
        uri,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('ReadabilityService: Response status: ${response.statusCode}');
      debugPrint(
        'ReadabilityService: Response length: ${response.data.length}',
      );

      if (response.statusCode != 200) {
        debugPrint('ReadabilityService: HTTP error: ${response.statusCode}');
        return null;
      }

      List<int> bytes = response.data as List<int>;
      if (bytes.isEmpty) {
        debugPrint('ReadabilityService: Empty response body');
        return null;
      }

      final contentEncoding = response.headers.value('content-encoding');
      debugPrint('ReadabilityService: Content-Encoding: $contentEncoding');

      if (contentEncoding != null) {
        if (contentEncoding.contains('br')) {
          try {
            debugPrint('ReadabilityService: Decompressing Brotli content...');
            final brotliBytes = Uint8List.fromList(bytes);
            final decodedBytes = brotli.decode(brotliBytes);
            bytes = decodedBytes.toList();
            debugPrint(
              'ReadabilityService: Brotli decompressed (${bytes.length} bytes)',
            );
          } catch (e) {
            debugPrint('ReadabilityService: Brotli decompression failed: $e');
          }
        } else if (contentEncoding.contains('gzip')) {
          try {
            debugPrint('ReadabilityService: Decompressing GZIP content...');
            final decodedBytes = gzip.decode(bytes);
            bytes = decodedBytes.toList();
            debugPrint(
              'ReadabilityService: GZIP decompressed (${bytes.length} bytes)',
            );
          } catch (e) {
            debugPrint('ReadabilityService: GZIP decompression failed: $e');
          }
        } else if (contentEncoding.contains('deflate')) {
          try {
            debugPrint('ReadabilityService: Decompressing Deflate content...');
            final decodedBytes = zlib.decode(bytes);
            bytes = decodedBytes.toList();
            debugPrint(
              'ReadabilityService: Deflate decompressed (${bytes.length} bytes)',
            );
          } catch (e) {
            debugPrint('ReadabilityService: Deflate decompression failed: $e');
          }
        }
      }

      String htmlContent;
      String? httpCharset;
      final contentType = response.headers.value('content-type');
      if (contentType != null) {
        final charsetMatch = RegExp(
          r'charset=([^\s;]+)',
          caseSensitive: false,
        ).firstMatch(contentType);
        if (charsetMatch != null) {
          httpCharset = charsetMatch.group(1)?.toLowerCase();
          debugPrint(
            'ReadabilityService: HTTP Content-Type charset: $httpCharset',
          );
        }
      }

      try {
        if (httpCharset != null) {
          if (httpCharset == 'gbk' ||
              httpCharset == 'gb2312' ||
              httpCharset == 'gb18030') {
            htmlContent = gbk.decode(bytes);
            debugPrint('ReadabilityService: Decoded using HTTP charset (GBK)');
          } else if (httpCharset == 'utf-8' || httpCharset == 'utf8') {
            htmlContent = utf8.decode(bytes);
            debugPrint(
              'ReadabilityService: Decoded using HTTP charset (UTF-8)',
            );
          } else {
            htmlContent = utf8.decode(bytes, allowMalformed: true);
            debugPrint(
              'ReadabilityService: Decoded with fallback for charset: $httpCharset',
            );
          }
        } else {
          htmlContent = utf8.decode(bytes);

          if (htmlContent.contains('charset=gbk') ||
              htmlContent.contains('charset=GB2312') ||
              htmlContent.contains('charset=gb2312')) {
            debugPrint('ReadabilityService: Found GBK charset in HTML meta');
            htmlContent = gbk.decode(bytes);
          }

          debugPrint('ReadabilityService: Successfully decoded as UTF-8');
        }
      } catch (utf8Error) {
        debugPrint(
          'ReadabilityService: UTF-8 decode failed, trying GBK: $utf8Error',
        );
        try {
          htmlContent = gbk.decode(bytes);
          debugPrint('ReadabilityService: Successfully decoded as GBK');
        } catch (gbkError) {
          debugPrint('ReadabilityService: GBK decode also failed: $gbkError');
          htmlContent = utf8.decode(bytes, allowMalformed: true);
          debugPrint('ReadabilityService: Using malformed UTF-8 as fallback');
        }
      }

      htmlContent = _preprocessHtml(htmlContent);

      Article? article;

      debugPrint('ReadabilityService: Trying JSDOMParser...');
      article = parse(htmlContent, baseUri: url, parser: ParserType.jsdom);

      if (article == null || article.textContent.length < 200) {
        debugPrint(
          'ReadabilityService: JSDOMParser failed or content too short, trying html parser...',
        );
        article = parse(htmlContent, baseUri: url, parser: ParserType.html);
      }

      if (article == null) {
        debugPrint('ReadabilityService: All parsers returned null');
        return null;
      }

      debugPrint('ReadabilityService: Title: ${article.title}');
      debugPrint(
        'ReadabilityService: Text length: ${article.textContent.length}',
      );
      debugPrint(
        'ReadabilityService: Parser used: ${article.textContent.length >= 200 ? "JSDOMParser" : "html parser"}',
      );

      if (article.textContent.length < 200) {
        debugPrint(
          'ReadabilityService: Content too short (${article.textContent.length} chars)',
        );
        return null;
      }

      return ArticleData(
        title: article.title,
        textContent: article.textContent,
        htmlContent: article.content,
        author: article.byline,
        publishDate: article.publishedTime,
        excerpt: article.excerpt,
        url: url,
      );
    } on TimeoutException catch (e) {
      debugPrint('ReadabilityService: Timeout error: $e');
      return null;
    } on DioException catch (e) {
      debugPrint('ReadabilityService: Dio error: ${e.type} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('ReadabilityService: Unexpected error: $e');
      return null;
    } finally {
      _dio?.close();
      _httpClient?.close();
    }
  }

  String _preprocessHtml(String html) {
    debugPrint(
      'ReadabilityService: Preprocessing HTML (original length: ${html.length})',
    );

    html = html.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      '',
    );

    html = html.replaceAll(
      RegExp(r'<style[^>]*>.*?</style>', caseSensitive: false, dotAll: true),
      '',
    );

    html = html.replaceAll(
      RegExp(
        r'<noscript[^>]*>.*?</noscript>',
        caseSensitive: false,
        dotAll: true,
      ),
      '',
    );

    html = html.replaceAll(
      RegExp(r'<svg[^>]*>.*?</svg>', caseSensitive: false, dotAll: true),
      '',
    );

    html = html.replaceAll(
      RegExp(r'<math[^>]*>.*?</math>', caseSensitive: false, dotAll: true),
      '',
    );

    html = html.replaceAll(
      RegExp(r'<!--.*?-->', caseSensitive: false, dotAll: true),
      '',
    );

    html = html.replaceAll('&nbsp;', ' ');
    html = html.replaceAll('&amp;', '&');
    html = html.replaceAll('&lt;', '<');
    html = html.replaceAll('&gt;', '>');
    html = html.replaceAll('&quot;', '"');
    html = html.replaceAll('&#39;', "'");
    html = html.replaceAll(RegExp(r'&#\d+;'), ''); // 移除数字实体（如 &#123;）

    html = html.replaceAll(
      RegExp(
        r'<(div|span|p|a|font|i|b|u|em|strong)[^>]*>\s*</\1>',
        caseSensitive: false,
      ),
      '',
    );

    debugPrint(
      'ReadabilityService: Preprocessing done (new length: ${html.length})',
    );
    return html;
  }

  void dispose() {
    _dio?.close();
    _httpClient?.close();
  }
}
