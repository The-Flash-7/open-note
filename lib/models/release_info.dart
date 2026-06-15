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
    String assetExtension, {
    List<String> assetKeywords = const [],
  }) {
    final tagName = (json['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
    final assets = (json['assets'] as List<dynamic>?) ?? [];
    final matchedAsset = _findBestAsset(assets, assetExtension, assetKeywords);
    final downloadUrl =
        matchedAsset?['browser_download_url'] as String? ??
        json['html_url'] as String? ??
        '';

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

  static Map<String, dynamic>? _findBestAsset(
    List<dynamic> assets,
    String assetExtension,
    List<String> assetKeywords,
  ) {
    final normalizedExtension = assetExtension.toLowerCase();
    final candidates = assets
        .whereType<Map<String, dynamic>>()
        .where(
          (asset) => (asset['name'] as String? ?? '').toLowerCase().endsWith(
            normalizedExtension,
          ),
        )
        .toList();

    for (final asset in candidates) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (assetKeywords.every((keyword) => name.contains(keyword))) {
        return asset;
      }
    }

    for (final asset in candidates) {
      final name = (asset['name'] as String? ?? '').toLowerCase();
      if (name.contains('universal')) return asset;
    }

    return candidates.isNotEmpty ? candidates.first : null;
  }

  @override
  String toString() => 'ReleaseInfo(v$version, $releaseName)';
}
