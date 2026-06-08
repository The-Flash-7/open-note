// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class ReleaseInfo {
  final String version;
  final String releaseName;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime publishedAt;
  final bool isPrerelease;
  final String htmlUrl;

  ReleaseInfo({
    required this.version,
    required this.releaseName,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.publishedAt,
    required this.isPrerelease,
    required this.htmlUrl,
  });

  factory ReleaseInfo.fromJson(
    Map<String, dynamic> json,
    String assetExtension,
  ) {
    final tagName = (json['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
    final assets = (json['assets'] as List<dynamic>?) ?? [];
    String downloadUrl = json['html_url'] as String? ?? '';
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith(assetExtension)) {
        downloadUrl = asset['browser_download_url'] as String;
        break;
      }
    }

    return ReleaseInfo(
      version: tagName,
      releaseName: json['name'] as String? ?? tagName,
      releaseNotes: json['body'] as String? ?? '',
      downloadUrl: downloadUrl,
      publishedAt: DateTime.parse(json['published_at'] as String),
      isPrerelease: json['prerelease'] as bool? ?? false,
      htmlUrl: json['html_url'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ReleaseInfo(v$version, $releaseName)';
}
