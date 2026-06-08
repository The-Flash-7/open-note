// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/ai_provider_config.dart';
import '../theme/design_tokens.dart';
import '../utils/snackbar_helper.dart';
import '../l10n/strings.g.dart';

class ModelManagementDialog extends StatefulWidget {
  final AIProviderConfig config;

  const ModelManagementDialog({super.key, required this.config});

  @override
  State<ModelManagementDialog> createState() => _ModelManagementDialogState();
}

class _ModelManagementDialogState extends State<ModelManagementDialog> {
  late List<String> _models;
  late String _currentDefault;
  final TextEditingController _newModelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _models = List.from(widget.config.models);
    _currentDefault = widget.config.defaultModel;
  }

  @override
  void dispose() {
    _newModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      elevation: 8,
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        ),
        padding: EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.dialog_manageModelsTitle(
                    providerName: widget.config.displayName,
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newModelController,
                    decoration: InputDecoration(
                      labelText: t.dialog_newModelLabel,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, size: 28),
                  onPressed: () {
                    if (_newModelController.text.trim().isNotEmpty) {
                      setState(() {
                        _models.add(_newModelController.text.trim());
                        _newModelController.clear();
                      });
                    }
                  },
                  tooltip: t.dialog_addModelTooltip,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              t.dialog_currentModelsHeader(count: _models.length),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _models.length,
                itemBuilder: (context, index) {
                  final model = _models[index];
                  final isDefault = model == _currentDefault;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        isDefault ? Icons.star : Icons.label_outline,
                        size: 20,
                        color: isDefault ? Colors.amber : null,
                      ),
                      title: Text(
                        model,
                        style: TextStyle(
                          fontWeight: isDefault
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isDefault)
                            IconButton(
                              icon: const Icon(Icons.star_border, size: 20),
                              onPressed: () {
                                setState(() {
                                  _currentDefault = model;
                                });
                              },
                              tooltip: t.dialog_setDefaultTooltip,
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() {
                                _models.remove(model);
                                if (_currentDefault == model &&
                                    _models.isNotEmpty) {
                                  _currentDefault = _models.first;
                                }
                              });
                            },
                            tooltip: t.common_delete,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.common_cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final newDefault = _models.contains(_currentDefault)
                        ? _currentDefault
                        : (_models.isNotEmpty ? _models.first : '');
                    final updatedConfig = widget.config.copyWith(
                      models: _models,
                      defaultModel: newDefault,
                    );
                    final provider = context.read<SettingsProvider>();
                    await provider.updateProvider(updatedConfig);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    SnackBarHelper.show(context, t.dialog_modelsUpdated);
                  },
                  child: Text(t.common_save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
