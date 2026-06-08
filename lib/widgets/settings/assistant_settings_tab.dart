// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/memory_settings_provider.dart';
import '../../models/agent_memory.dart';
import '../../theme/design_tokens.dart';
import '../../l10n/strings.g.dart';

class AssistantSettingsTab extends StatefulWidget {
  const AssistantSettingsTab({super.key});

  @override
  State<AssistantSettingsTab> createState() => _AssistantSettingsTabState();
}

class _AssistantSettingsTabState extends State<AssistantSettingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MemorySettingsProvider>().refreshMemoryCounts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Consumer<MemorySettingsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context: context,
                title: t.assistant_memoryCapability,
                child: _buildMemorySystemToggle(context, provider, t),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context: context,
                title: t.assistant_aiModelSelection,
                child: _buildAiModelSelector(context, provider, t),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context: context,
                title: t.assistant_memoryInjectionControl,
                child: _buildInjectionToggles(context, provider, t),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context: context,
                title: t.assistant_clearMemory,
                child: _buildClearButtons(context, provider, t),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context: context,
                title: t.assistant_roleControl,
                child: _buildComingSoonCard(context, t),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
    );
  }

  Widget _buildMemorySystemToggle(
    BuildContext context,
    MemorySettingsProvider provider,
    Translations t,
  ) {
    final canEnable = provider.canEnableMemorySystem;

    return SwitchListTile(
      title: Text(t.assistant_enableLongTermMemory),
      subtitle: Text(
        canEnable
            ? t.assistant_memoryDisabledHint
            : t.assistant_configureAIModelFirst,
      ),
      value: provider.memorySystemEnabled,
      onChanged: canEnable
          ? (value) => provider.toggleMemorySystem(value)
          : null,
      activeThumbColor: DesignTokens.primary500,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAiModelSelector(
    BuildContext context,
    MemorySettingsProvider provider,
    Translations t,
  ) {
    final providers = provider.availableProviders;

    if (providers.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(width: 8),
              Text(
                t.assistant_configureAIModelsFirst,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.assistant_noAvailableModels,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final currentProvider = providers.firstWhere(
      (p) => p.id == provider.memoryAiProviderId,
      orElse: () => providers.first,
    );

    final allModels = <String>[];
    for (final p in providers) {
      for (final m in p.models) {
        allModels.add('${p.displayName} / $m');
      }
    }

    final currentLabel =
        '${currentProvider.displayName} / ${provider.memoryAiModel.isEmpty ? currentProvider.defaultModel : provider.memoryAiModel}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: currentLabel,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: allModels
              .map(
                (label) => DropdownMenuItem(value: label, child: Text(label)),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) {
              final parts = selected.split(' / ');
              if (parts.length == 2) {
                final providerName = parts[0];
                final modelName = parts[1];
                final matchedProvider = providers.firstWhere(
                  (p) => p.displayName == providerName,
                  orElse: () => providers.first,
                );
                provider.setMemoryAiModel(matchedProvider.id, modelName);
              }
            }
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: DesignTokens.success500,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              t.assistant_availableModelsCount(count: providers.length),
              style: TextStyle(
                fontSize: 13,
                color: DesignTokens.success500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInjectionToggles(
    BuildContext context,
    MemorySettingsProvider provider,
    Translations t,
  ) {
    final isEnabled = provider.memorySystemEnabled;

    return Column(
      children: [
        SwitchListTile(
          title: Text(t.assistant_profileMemory),
          subtitle: Text(t.assistant_profileMemorySubtitle),
          value: provider.profileInjectionEnabled,
          onChanged: isEnabled
              ? (v) => provider.toggleProfileInjection(v)
              : null,
          activeThumbColor: DesignTokens.primary500,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: Text(t.assistant_factPreferenceMemory),
          subtitle: Text(t.assistant_factPreferenceSubtitle),
          value: provider.factInjectionEnabled,
          onChanged: isEnabled ? (v) => provider.toggleFactInjection(v) : null,
          activeThumbColor: DesignTokens.primary500,
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(height: 1),
        SwitchListTile(
          title: Text(t.assistant_experienceSummaryMemory),
          subtitle: Text(t.assistant_experienceSummarySubtitle),
          value: provider.experienceInjectionEnabled,
          onChanged: isEnabled
              ? (v) => provider.toggleExperienceInjection(v)
              : null,
          activeThumbColor: DesignTokens.primary500,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildClearButtons(
    BuildContext context,
    MemorySettingsProvider provider,
    Translations t,
  ) {
    final profileCount = provider.getMemoryCount(MemoryType.profile);
    final factCount = provider.getMemoryCount(MemoryType.fact);
    final experienceCount = provider.getMemoryCount(MemoryType.experience);
    final totalCount = profileCount + factCount + experienceCount;

    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => _confirmClearMemory(
                context,
                provider,
                MemoryType.profile,
                t.assistant_profileMemory,
              ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: Text(t.assistant_clearProfileMemory(count: profileCount)),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmClearMemory(
                context,
                provider,
                MemoryType.fact,
                t.assistant_factPreferenceMemory,
              ),
              icon: const Icon(Icons.favorite_outline, size: 18),
              label: Text(t.assistant_clearFactMemory(count: factCount)),
            ),
            OutlinedButton.icon(
              onPressed: () => _confirmClearMemory(
                context,
                provider,
                MemoryType.experience,
                t.assistant_experienceSummaryMemory,
              ),
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: Text(
                t.assistant_clearExperienceMemory(count: experienceCount),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _confirmClearAllMemory(context, provider),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: Text(t.assistant_clearAllMemory(count: totalCount)),
          style: OutlinedButton.styleFrom(
            foregroundColor: DesignTokens.error500,
          ),
        ),
      ],
    );
  }

  Widget _buildComingSoonCard(BuildContext context, Translations t) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            const Icon(Icons.construction, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              t.common_comingSoon,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.assistant_roleCustomizationInDevelopment,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearMemory(
    BuildContext context,
    MemorySettingsProvider provider,
    MemoryType type,
    String typeName,
  ) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.common_confirmDelete),
        content: Text(
          t.assistant_confirmClearMemoryContent(typeName: typeName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearMemoryByType(type);
              Navigator.pop(ctx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.assistant_clearedMemory(typeName: typeName)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error500,
            ),
            child: Text(t.common_clear),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllMemory(
    BuildContext context,
    MemorySettingsProvider provider,
  ) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.common_confirmClear),
        content: Text(t.assistant_confirmClearAllMemoryContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearAllMemories();
              Navigator.pop(ctx);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.assistant_clearedAllMemory),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error500,
            ),
            child: Text(t.assistant_clearAll),
          ),
        ],
      ),
    );
  }
}
