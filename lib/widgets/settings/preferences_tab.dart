// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/language_provider.dart';
import '../../utils/app_info.dart';
import '../../theme/design_tokens.dart';
import '../../l10n/strings.g.dart';

class PreferencesTab extends StatefulWidget {
  const PreferencesTab({super.key});

  @override
  State<PreferencesTab> createState() => _PreferencesTabState();
}

class _PreferencesTabState extends State<PreferencesTab> {
  late AppInfo _appInfo;
  List<String> _skippedVersions = [];

  @override
  void initState() {
    super.initState();
    _appInfo = AppInfo.instance;
    _loadSkippedVersions();
  }

  Future<void> _loadSkippedVersions() async {
    final provider = context.read<UpdateProvider>();
    final versions = await provider.getSkippedVersions();
    if (mounted) {
      setState(() => _skippedVersions = versions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<UpdateProvider, LanguageProvider>(
      builder: (context, updateProvider, langProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLanguageCard(context, langProvider, isDark),
              const SizedBox(height: 16),
              _buildVersionCard(context, isDark),
              const SizedBox(height: 16),
              _buildUpdateCard(context, updateProvider, isDark),
              if (updateProvider.isDownloading ||
                  updateProvider.state == UpdateState.downloadComplete) ...[
                const SizedBox(height: 16),
                _buildDownloadCard(context, updateProvider, isDark),
              ],
              if (_skippedVersions.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSkippedVersionsCard(context, updateProvider, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    LanguageProvider langProvider,
    bool isDark,
  ) {
    final t = Translations.of(context);
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.preferences_language,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: langProvider.isSystemLanguage
                ? 'system'
                : langProvider.getLanguageCode(langProvider.locale!),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : DesignTokens.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.gray300,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'system',
                child: Text(t.preferences_followSystem),
              ),
              ...langProvider.availableLanguages.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(langProvider.getLanguageLabel(entry.value)),
                );
              }),
            ],
            onChanged: (value) {
              if (value == 'system') {
                langProvider.setLanguage(null);
              } else {
                langProvider.setLanguage(value);
              }
            },
          ),
          // const SizedBox(height: 8),
          // Text(
          //   t.preferences_languageRestartHint,
          //   style: TextStyle(
          //     fontSize: 12,
          //     color: isDark
          //         ? DesignTokens.darkTextSecondary
          //         : DesignTokens.gray500,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(BuildContext context, bool isDark) {
    final t = Translations.of(context);
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(t.preferences_versionNumber, _appInfo.fullVersionString),
          const SizedBox(height: 8),
          _row(t.preferences_platform, _appInfo.platformArchString),
          const SizedBox(height: 8),
          _row(t.preferences_buildNumber, _appInfo.buildNumber),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(
    BuildContext context,
    UpdateProvider provider,
    bool isDark,
  ) {
    final t = Translations.of(context);
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.preferences_autoCheckUpdate,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? DesignTokens.darkTextPrimary
                      : DesignTokens.gray900,
                ),
              ),
              Switch(
                value: provider.autoCheckUpdate,
                onChanged: (v) => provider.setAutoCheckUpdate(v),
                activeThumbColor: DesignTokens.primary500,
                activeTrackColor: DesignTokens.primary500.withValues(
                  alpha: 0.5,
                ),
                inactiveThumbColor: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray400,
                inactiveTrackColor: isDark
                    ? DesignTokens.darkBorder
                    : DesignTokens.gray300,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed:
                    provider.state == UpdateState.checking ||
                        provider.isDownloading
                    ? null
                    : () => provider.checkForUpdate(),
                icon: provider.state == UpdateState.checking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(
                  provider.state == UpdateState.checking
                      ? t.preferences_checking
                      : provider.state == UpdateState.noUpdate
                      ? t.preferences_latestVersion
                      : provider.state == UpdateState.error
                      ? t.preferences_checkFailedRetry
                      : t.preferences_checkForUpdate,
                ),
              ),
              const SizedBox(width: 12),
              if (provider.state == UpdateState.updateAvailable &&
                  provider.latestRelease != null)
                Text(
                  t.preferences_newVersionFound(
                    version: provider.latestRelease!.version,
                  ),
                  style: TextStyle(
                    color: DesignTokens.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (provider.state == UpdateState.error &&
              provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: TextStyle(color: DesignTokens.error500, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDownloadCard(
    BuildContext context,
    UpdateProvider provider,
    bool isDark,
  ) {
    final t = Translations.of(context);
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            provider.state == UpdateState.downloadComplete
                ? t.preferences_downloadComplete
                : t.preferences_downloadingUpdate,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: provider.downloadProgress,
            backgroundColor: isDark
                ? DesignTokens.darkBorder
                : DesignTokens.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primary500),
          ),
          const SizedBox(height: 8),
          Text(
            '${(provider.downloadProgress * 100).toStringAsFixed(1)}%  ·  ${_formatSpeed(provider.downloadSpeed)}',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
          if (provider.state == UpdateState.downloadComplete) ...[
            const SizedBox(height: 12),
            Text(
              t.preferences_installPrompt,
              style: TextStyle(fontSize: 13, color: DesignTokens.success),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkippedVersionsCard(
    BuildContext context,
    UpdateProvider provider,
    bool isDark,
  ) {
    final t = Translations.of(context);
    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.preferences_skippedVersions,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skippedVersions.map((version) {
              return Chip(
                label: Text('v$version'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () async {
                  await provider.removeSkippedVersion(version);
                  await _loadSkippedVersions();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
        ),
      ],
    );
  }

  String _formatSpeed(double speedMbps) {
    if (speedMbps >= 1.0) {
      return '${speedMbps.toStringAsFixed(1)} MB/s';
    }
    return '${(speedMbps * 1024).toStringAsFixed(0)} KB/s';
  }
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;

  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}
