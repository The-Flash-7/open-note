// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.g.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../models/ai_provider_config.dart';
import '../utils/ai_provider_templates.dart';
import '../theme/design_tokens.dart';
import 'model_management_dialog.dart';
import '../utils/app_info.dart';
import 'settings/preferences_tab.dart';
import 'settings/knowledge_base_tab.dart';
import 'settings/assistant_settings_tab.dart';
import 'cli_install_dialog.dart';
import '../services/cli_install_service.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _selectedIndex = 0;

  List<_SettingsItem> _buildSettingsItems(Translations t) {
    return [
      _SettingsItem(
        title: t.settings_preferences,
        icon: Icons.settings,
        enabled: true,
      ),
      _SettingsItem(
        title: t.settings_aiService,
        icon: Icons.smart_toy,
        enabled: true,
      ),
      _SettingsItem(
        title: t.settings_appearance,
        icon: Icons.palette,
        enabled: true,
      ),
      _SettingsItem(
        title: t.settings_knowledgeBase,
        icon: Icons.library_books_outlined,
        enabled: true,
      ),
      _SettingsItem(
        title: t.settings_assistant,
        icon: Icons.psychology,
        enabled: true,
      ),
      _SettingsItem(
        title: t.settings_cliTools,
        icon: Icons.terminal,
        enabled: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width * 0.65;
    final dialogHeight = screenSize.height * 0.75;
    final settingsItems = _buildSettingsItems(t);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildLeftPanel(context, t, settingsItems),
            Container(width: 1, color: Theme.of(context).dividerColor),
            Expanded(child: _buildRightPanel(context, t, settingsItems)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(
    BuildContext context,
    Translations t,
    List<_SettingsItem> settingsItems,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.settings_title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(settingsItems.length, (index) {
            final item = settingsItems[index];
            final isSelected = _selectedIndex == index;
            return _buildNavItem(context, item, index, isSelected, t);
          }),
          const Spacer(),
          _buildGitHubLink(context),
          const SizedBox(height: 4),
          _buildOfficialLink(context),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: _getVersionString(),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Text(
                  snapshot.data ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<String> _getVersionString() async {
    final info = AppInfo.instance;
    return 'Version ${info.version}';
  }

  Widget _buildGitHubLink(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? DesignTokens.darkTextSecondary
        : DesignTokens.gray900;
    final textColor = isDark
        ? DesignTokens.darkTextSecondary
        : DesignTokens.gray900;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final url = Uri.parse('https://github.com/The-Flash-7/open-note');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/settings/github.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            const SizedBox(width: 6),
            Text(
              '@open-note',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialLink(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? DesignTokens.darkTextSecondary
        : DesignTokens.gray900;

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () async {
        final url = Uri.parse('http://opennote.zsdn.net');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? DesignTokens.darkSurface
                      : DesignTokens.gray300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset(
                'assets/images/app_icon@200h.png',
                width: 17,
                height: 17,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'OpenNote',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    _SettingsItem item,
    int index,
    bool isSelected,
    Translations t,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? DesignTokens.darkTextSecondary : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.enabled
            ? () {
                setState(() {
                  _selectedIndex = index;
                });
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: item.enabled
                    ? (isSelected ? Colors.white : unselectedColor)
                    : Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: item.enabled
                            ? (isSelected ? Colors.white : unselectedColor)
                            : Theme.of(context).disabledColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (!item.enabled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).disabledColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.common_comingSoon,
                          style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    Translations t,
    List<_SettingsItem> settingsItems,
  ) {
    return Column(
      children: [
        _buildHeader(context, t, settingsItems),
        Expanded(child: _buildContent(context, t)),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Translations t,
    List<_SettingsItem> settingsItems,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            settingsItems[_selectedIndex].title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: t.common_close,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, Translations t) {
    switch (_selectedIndex) {
      case 0:
        return const PreferencesTab();
      case 1:
        return _buildAIProviderSettings(context, t);
      case 2:
        return _buildAppearanceSettings(context, t);
      case 3:
        return const KnowledgeBaseTab();
      case 4:
        return const AssistantSettingsTab();
      case 5:
        return _buildCLISettings(context, t);
      default:
        return Center(
          child: Text(
            t.settings_featureInDevelopment,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
        );
    }
  }

  Widget _buildAIProviderSettings(BuildContext context, Translations t) {
    return Consumer<SettingsProvider>(
      builder: (context, provider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickAddSection(context, provider, isDark, t),
                  const SizedBox(height: 16),
                  _buildConfigsList(context, provider, isDark, t),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _showCustomConfigDialog(context, t),
                icon: const Icon(Icons.add),
                label: Text(t.settings_customConfig),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppearanceSettings(BuildContext context, Translations t) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeCard(
                context,
                isDark,
                themeProvider,
                ThemeMode.system,
                t.common_followSystem,
                Icons.brightness_auto,
                t.settings_autoFollowSystemTheme,
              ),
              const SizedBox(height: 16),
              _buildThemeCard(
                context,
                isDark,
                themeProvider,
                ThemeMode.light,
                t.common_lightMode,
                Icons.light_mode,
                t.settings_alwaysUseLightTheme,
              ),
              const SizedBox(height: 16),
              _buildThemeCard(
                context,
                isDark,
                themeProvider,
                ThemeMode.dark,
                t.common_darkMode,
                Icons.dark_mode,
                t.settings_alwaysUseDarkTheme,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    bool isDark,
    ThemeProvider provider,
    ThemeMode mode,
    String title,
    IconData icon,
    String description,
  ) {
    final isSelected = provider.themeMode == mode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final selectedIconColor = isDark ? DesignTokens.primary200 : primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (isDark ? DesignTokens.primary400 : primaryColor)
              : (isDark ? DesignTokens.darkBorder : DesignTokens.gray200),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => provider.setThemeMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? selectedIconColor
                  : (isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: selectedIconColor, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCLISettings(BuildContext context, Translations t) {
    return FutureBuilder(
      future: Future.wait([
        CLIInstallService.checkEnvironment(),
        CLIInstallService.isCLIInstalled(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final envCheck = snapshot.data![0] as EnvCheckResult;
        final isInstalled = snapshot.data![1] as bool;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCLICard(
                context,
                t.cli_envStatus,
                isDark,
                _buildEnvStatus(context, envCheck, isInstalled, isDark, t),
              ),
              const SizedBox(height: 16),
              _buildCLICard(
                context,
                t.cli_installCLI,
                isDark,
                _buildInstallContent(context, envCheck, isDark, t),
              ),
              const SizedBox(height: 16),
              _buildCLICard(
                context,
                t.cli_usage,
                isDark,
                _buildUsageContent(isDark, t),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCLICard(
    BuildContext context,
    String title,
    bool isDark,
    Widget child,
  ) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEnvStatus(
    BuildContext context,
    EnvCheckResult envCheck,
    bool isInstalled,
    bool isDark,
    Translations t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEnvRow(
          context,
          t.cli_cliStatus,
          isInstalled ? t.cli_installed : t.cli_notInstalled,
          isInstalled,
        ),
        const SizedBox(height: 8),
        _buildEnvRow(
          context,
          'Python',
          envCheck.pythonVersion ?? t.cli_notDetected,
          envCheck.available && envCheck.pythonVersion != null,
        ),
        const SizedBox(height: 8),
        _buildEnvRow(
          context,
          'pip',
          envCheck.pipVersion ?? t.cli_notDetected,
          envCheck.available && envCheck.pipVersion != null,
        ),
      ],
    );
  }

  Widget _buildInstallContent(
    BuildContext context,
    EnvCheckResult envCheck,
    bool isDark,
    Translations t,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.cli_installDescription,
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: envCheck.available
              ? () => showDialog(
                  context: context,
                  builder: (_) => const CLIInstallDialog(),
                )
              : null,
          icon: const Icon(Icons.download, size: 18),
          label: Text(t.cli_installCLI),
        ),
        if (!envCheck.available) ...[
          const SizedBox(height: 12),
          Text(
            _translateEnvError(envCheck.errorKey ?? 'envCheckError', t),
            style: TextStyle(fontSize: 13, color: DesignTokens.error500),
          ),
        ],
      ],
    );
  }

  String _translateEnvError(String errorKey, Translations t) {
    switch (errorKey) {
      case 'pythonNotInstalled':
        return t.cli_pythonNotInstalled;
      case 'pipNotInstalled':
        return t.cli_pipNotInstalled;
      default:
        return t.cli_envNotMet;
    }
  }

  Widget _buildUsageContent(bool isDark, Translations t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : DesignTokens.gray50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        t.cli_helpText,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }

  Widget _buildEnvRow(
    BuildContext context,
    String label,
    String value,
    bool isValid,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          isValid ? Icons.check : Icons.close,
          size: 16,
          color: isValid ? DesignTokens.success : DesignTokens.error500,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddSection(
    BuildContext context,
    SettingsProvider provider,
    bool isDark,
    Translations t,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.settings_quickAddPresets,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.settings_quickAddDescription,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AIProviderTemplates.templates
                .where((t) => t.name != '自定义')
                .map((template) {
                  return ActionChip(
                    label: Text(template.displayName),
                    onPressed: () =>
                        _showQuickAddDialog(context, provider, template, t),
                  );
                })
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigsList(
    BuildContext context,
    SettingsProvider provider,
    bool isDark,
    Translations t,
  ) {
    if (provider.providerConfigs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.cloud_off,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: 8),
              Text(
                t.settings_noAIConfig,
                style: TextStyle(
                  color: isDark
                      ? DesignTokens.darkTextPrimary
                      : DesignTokens.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.settings_clickToAddPreset,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              t.settings_configured,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              t.settings_configCount(count: provider.providerConfigs.length),
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...provider.providerConfigs.map(
          (config) => _buildConfigCard(context, provider, config, isDark, t),
        ),
      ],
    );
  }

  Widget _buildConfigCard(
    BuildContext context,
    SettingsProvider provider,
    AIProviderConfig config,
    bool isDark,
    Translations t,
  ) {
    final isActive = provider.activeProvider?.id == config.id;
    final hasValidConfig = config.hasValidConfig();

    final activeColor = isDark
        ? DesignTokens.primary200
        : DesignTokens.primary500;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? (isDark ? DesignTokens.primary400 : activeColor)
              : (isDark ? DesignTokens.darkBorder : DesignTokens.gray200),
          width: isActive ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Icon(
          isActive ? Icons.check_circle : Icons.circle,
          color: isActive
              ? activeColor
              : (hasValidConfig ? Colors.orange : Colors.grey),
        ),
        title: Text(config.displayName),
        subtitle: Text(
          '${config.models.length}${t.settings_modelCount}',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t.settings_current,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Builder(
              builder: (buttonContext) => PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'activate':
                      provider.setActiveProvider(config.id);
                      break;
                    case 'edit':
                      _showEditConfigDialog(buttonContext, provider, config, t);
                      break;
                    case 'manage_models':
                      await Future.delayed(const Duration(milliseconds: 100));
                      if (buttonContext.mounted) {
                        _showModelManagementDialog(
                          buttonContext,
                          provider,
                          config,
                        );
                      }
                      break;
                    case 'test':
                      _showTestConnectionDialog(
                        buttonContext,
                        provider,
                        config,
                      );
                      break;
                    case 'delete':
                      _confirmDelete(buttonContext, provider, config, t);
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isActive)
                    PopupMenuItem(
                      value: 'activate',
                      child: ListTile(
                        leading: const Icon(Icons.check),
                        title: Text(t.settings_setModelFirst),
                      ),
                    ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: const Icon(Icons.edit),
                      title: Text(t.common_edit),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'manage_models',
                    child: ListTile(
                      leading: const Icon(Icons.list),
                      title: Text(t.dialog_manageModelsTitle(providerName: '')),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'test',
                    child: ListTile(
                      leading: const Icon(Icons.wifi_find),
                      title: Text(t.settings_testConnection),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete),
                      title: Text(t.common_delete),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                context,
                isDark,
                t.settings_baseUrl,
                config.baseUrl ?? t.common_notConfigured,
              ),
              _buildInfoRow(
                context,
                isDark,
                t.settings_apiKey,
                config.apiKey != null && config.apiKey!.isNotEmpty
                    ? t.settings_configured
                    : t.common_notConfigured,
              ),
              _buildInfoRow(
                context,
                isDark,
                t.settings_defaultModel,
                config.defaultModel,
              ),
              const SizedBox(height: 8),
              Text(
                t.settings_modelList,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? DesignTokens.darkTextPrimary
                      : DesignTokens.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: config.models.map((model) {
                  final isDefault = model == config.defaultModel;
                  return Chip(
                    label: Text(
                      model,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isDefault
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    backgroundColor: isDefault
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    bool isDark,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isDark
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
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickAddDialog(
    BuildContext context,
    SettingsProvider provider,
    AIProviderTemplate template,
    Translations t,
  ) {
    final apiKeyController = TextEditingController();
    bool testing = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(t.settings_addProvider(name: template.displayName)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.description),
                  const SizedBox(height: 12),
                  if (template.baseUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            t.settings_apiAddress,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              template.baseUrl,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    t.settings_presetsModels(
                      models: template.models.join(", "),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: apiKeyController,
                    decoration: InputDecoration(
                      labelText: t.settings_apiKey,
                      hintText: t.settings_enterApiKey,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_paste),
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            apiKeyController.text = data!.text!;
                          }
                        },
                        tooltip: t.common_paste,
                      ),
                    ),
                    obscureText: true,
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: testing ? null : () => Navigator.pop(ctx),
                child: Text(t.common_cancel),
              ),
              ElevatedButton(
                onPressed: testing
                    ? null
                    : () async {
                        if (apiKeyController.text.isEmpty &&
                            template.name != 'Ollama本地') {
                          setDialogState(() {
                            errorMsg = t.settings_enterApiKeyError;
                          });
                          return;
                        }

                        setDialogState(() {
                          testing = true;
                          errorMsg = null;
                        });

                        final tempConfig = AIProviderConfig(
                          id: 'temp',
                          name: template.name,
                          displayName: template.displayName,
                          baseUrl: template.baseUrl.isNotEmpty
                              ? template.baseUrl
                              : null,
                          apiKey: apiKeyController.text.isEmpty
                              ? null
                              : apiKeyController.text,
                          models: template.models,
                          defaultModel: template.models.isNotEmpty
                              ? template.models.first
                              : '',
                          createdAt: DateTime.now(),
                        );

                        final success = await provider.testConnection(
                          tempConfig,
                        );

                        if (!success) {
                          setDialogState(() {
                            testing = false;
                            errorMsg = provider.errorMessage ?? '连接测试失败';
                          });
                          return;
                        }

                        await provider.createProviderFromTemplate(
                          template,
                          apiKeyController.text,
                          true,
                        );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                child: testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.common_add),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCustomConfigDialog(BuildContext context, Translations t) {
    final provider = context.read<SettingsProvider>();
    final nameController = TextEditingController();
    final baseUrlController = TextEditingController();
    final apiKeyController = TextEditingController();
    final modelsController = TextEditingController();
    bool testing = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(t.settings_customConfig),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: t.settings_vendorName,
                      hintText: t.settings_vendorNameHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: baseUrlController,
                    decoration: InputDecoration(
                      labelText: t.settings_baseUrl,
                      hintText: t.settings_baseUrlHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: apiKeyController,
                    decoration: InputDecoration(
                      labelText: t.settings_apiKey,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelsController,
                    decoration: InputDecoration(
                      labelText: t.settings_modelList,
                      hintText: t.settings_modelListHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: testing ? null : () => Navigator.pop(ctx),
                child: Text(t.common_cancel),
              ),
              ElevatedButton(
                onPressed: testing
                    ? null
                    : () async {
                        if (nameController.text.isEmpty) {
                          setDialogState(() {
                            errorMsg = t.settings_enterVendorName;
                          });
                          return;
                        }

                        final models = modelsController.text
                            .split(',')
                            .map((m) => m.trim())
                            .where((m) => m.isNotEmpty)
                            .toList();

                        if (models.isEmpty) {
                          setDialogState(() {
                            errorMsg = t.settings_enterAtLeastOneModel;
                          });
                          return;
                        }

                        setDialogState(() {
                          testing = true;
                          errorMsg = null;
                        });

                        final tempConfig = AIProviderConfig(
                          id: 'temp',
                          name: nameController.text,
                          displayName: nameController.text,
                          baseUrl: baseUrlController.text.isEmpty
                              ? null
                              : baseUrlController.text,
                          apiKey: apiKeyController.text.isEmpty
                              ? null
                              : apiKeyController.text,
                          models: models,
                          defaultModel: models.first,
                          createdAt: DateTime.now(),
                        );

                        final success = await provider.testConnection(
                          tempConfig,
                        );

                        if (!success) {
                          setDialogState(() {
                            testing = false;
                            errorMsg = provider.errorMessage ?? '连接测试失败';
                          });
                          return;
                        }

                        final config = AIProviderConfig(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          displayName: nameController.text,
                          baseUrl: baseUrlController.text.isEmpty
                              ? null
                              : baseUrlController.text,
                          apiKey: apiKeyController.text.isEmpty
                              ? null
                              : apiKeyController.text,
                          models: models,
                          defaultModel: models.first,
                          createdAt: DateTime.now(),
                        );

                        await provider.updateProvider(config);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                child: testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.common_add),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditConfigDialog(
    BuildContext context,
    SettingsProvider provider,
    AIProviderConfig config,
    Translations t,
  ) {
    final displayNameController = TextEditingController(
      text: config.displayName,
    );
    final baseUrlController = TextEditingController(text: config.baseUrl ?? '');
    final apiKeyController = TextEditingController(text: config.apiKey ?? '');
    bool testing = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(t.common_edit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: displayNameController,
                    decoration: InputDecoration(
                      labelText: t.settings_displayName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: baseUrlController,
                    decoration: InputDecoration(
                      labelText: t.settings_baseUrl,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: apiKeyController,
                    decoration: InputDecoration(
                      labelText: t.settings_apiKey,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        errorMsg!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: testing ? null : () => Navigator.pop(ctx),
                child: Text(t.common_cancel),
              ),
              ElevatedButton(
                onPressed: testing
                    ? null
                    : () async {
                        final updatedConfig = config.copyWith(
                          displayName: displayNameController.text,
                          baseUrl: baseUrlController.text.isEmpty
                              ? null
                              : baseUrlController.text,
                          apiKey: apiKeyController.text.isEmpty
                              ? null
                              : apiKeyController.text,
                        );

                        setDialogState(() {
                          testing = true;
                          errorMsg = null;
                        });

                        final success = await provider.testConnection(
                          updatedConfig,
                        );

                        if (!success) {
                          setDialogState(() {
                            testing = false;
                            errorMsg = provider.errorMessage ?? '连接测试失败';
                          });
                          return;
                        }

                        await provider.updateProvider(updatedConfig);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                child: testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.common_save),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showModelManagementDialog(
    BuildContext context,
    SettingsProvider provider,
    AIProviderConfig config,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => ModelManagementDialog(config: config),
    );
  }

  Future<void> _showTestConnectionDialog(
    BuildContext context,
    SettingsProvider provider,
    AIProviderConfig config,
  ) {
    return showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) =>
          _TestConnectionDialogContent(config: config, provider: provider),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SettingsProvider provider,
    AIProviderConfig config,
    Translations t,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.common_confirmDelete),
        content: Text(t.settings_confirmDeleteConfig(name: config.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.deleteProvider(config.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: Text(t.common_delete),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem {
  final String title;
  final IconData icon;
  final bool enabled;

  _SettingsItem({
    required this.title,
    required this.icon,
    required this.enabled,
  });
}

class _TestConnectionDialogContent extends StatefulWidget {
  final AIProviderConfig config;
  final SettingsProvider provider;

  const _TestConnectionDialogContent({
    required this.config,
    required this.provider,
  });

  @override
  State<_TestConnectionDialogContent> createState() =>
      _TestConnectionDialogContentState();
}

class _TestConnectionDialogContentState
    extends State<_TestConnectionDialogContent> {
  bool _testing = true;
  bool? _success;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runTest();
    });
  }

  Future<void> _runTest() async {
    final t = Translations.of(context);
    try {
      final success = await widget.provider.testConnection(widget.config);
      if (mounted) {
        setState(() {
          _testing = false;
          _success = success;
          _message = success
              ? t.settings_connectionSuccess(name: widget.config.displayName)
              : (widget.provider.errorMessage ?? t.settings_unknownError);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testing = false;
          _success = false;
          _message = t.settings_testException(error: e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return AlertDialog(
      title: _testing
          ? Text(t.settings_testConnection)
          : Icon(
              _success == true ? Icons.check_circle : Icons.error,
              color: _success == true ? Colors.green : Colors.red,
              size: 48,
            ),
      content: _testing
          ? Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(t.settings_testingConnection),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _success == true
                      ? t.settings_connectionSuccessful
                      : t.settings_connectionFailed,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_message ?? '', textAlign: TextAlign.center),
              ],
            ),
      actions: _testing
          ? null
          : [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text(t.common_ok),
              ),
            ],
    );
  }
}
