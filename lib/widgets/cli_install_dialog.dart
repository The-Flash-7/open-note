// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/strings.g.dart';
import '../theme/design_tokens.dart';
import '../services/cli_install_service.dart';

enum _InstallState { checking, envError, installing, success, installError }

class CLIInstallDialog extends StatefulWidget {
  const CLIInstallDialog({super.key});

  @override
  State<CLIInstallDialog> createState() => _CLIInstallDialogState();
}

class _CLIInstallDialogState extends State<CLIInstallDialog> {
  _InstallState _state = _InstallState.checking;
  String _errorKey = '';
  String _output = '';
  String _errorDetail = '';

  @override
  void initState() {
    super.initState();
    _checkAndInstall();
  }

  Future<void> _checkAndInstall() async {
    final envCheck = await CLIInstallService.checkEnvironment();
    if (!mounted) return;

    if (!envCheck.available) {
      setState(() {
        _state = _InstallState.envError;
        _errorKey = envCheck.errorKey ?? 'envCheckError';
      });
      return;
    }

    setState(() => _state = _InstallState.installing);

    final result = await CLIInstallService.install();
    if (!mounted) return;

    setState(() {
      if (result.success) {
        _state = _InstallState.success;
        _output = result.output;
      } else {
        _state = _InstallState.installError;
        _errorKey = result.errorKey ?? 'installProcessError';
        _errorDetail = result.output;
        _output = result.output;
      }
    });
  }

  String _translateError(Translations t) {
    switch (_errorKey) {
      case 'pythonNotInstalled':
        return t.cli_pythonNotInstalled;
      case 'pythonVersionTooLow':
        return t.cli_pythonVersionTooLow;
      case 'pipNotInstalled':
        return t.cli_pipNotInstalled;
      case 'envCheckError':
        return t.cli_envCheckFailed;
      case 'pythonVersionMismatch':
        return t.cli_pythonVersionMismatch;
      case 'installProcessError':
        return t.cli_installProcessError;
      default:
        return _errorKey;
    }
  }

  String _getEnvInstructions(Translations t) {
    if (Platform.isMacOS) return t.cli_envInstructionsMac;
    if (Platform.isWindows) return t.cli_envInstructionsWindows;
    return t.cli_envInstructionsLinux;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, t),
            const SizedBox(height: 16),
            _buildContent(context, isDark, t),
            const SizedBox(height: 16),
            _buildActions(context, t),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Translations t) {
    IconData icon = Icons.info;
    String title = '';
    Color? iconColor;

    switch (_state) {
      case _InstallState.checking:
        icon = Icons.search;
        title = t.cli_checkingEnv;
        break;
      case _InstallState.envError:
        icon = Icons.warning_amber_rounded;
        title = t.cli_envNotMet;
        iconColor = DesignTokens.error500;
        break;
      case _InstallState.installing:
        icon = Icons.download;
        title = t.cli_installingCLI;
        break;
      case _InstallState.success:
        icon = Icons.check_circle;
        title = t.cli_installSuccess;
        iconColor = Colors.green;
        break;
      case _InstallState.installError:
        icon = Icons.error;
        title = t.cli_installFailed;
        iconColor = DesignTokens.error500;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark, Translations t) {
    if (_state == _InstallState.checking) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_state == _InstallState.envError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _translateError(t),
            style: TextStyle(
              color: DesignTokens.error500,
              fontWeight: DesignTokens.fontWeightMedium,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _getEnvInstructions(t),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
          ),
        ],
      );
    }

    if (_state == _InstallState.installing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.cli_executingPipInstall),
          const SizedBox(height: 12),
          Container(
            height: 150,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(t.cli_installingPleaseWait),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_state == _InstallState.success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.cli_cliInstalledSuccessfully,
            style: const TextStyle(color: Colors.green),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _output.isEmpty ? t.cli_installComplete : _output,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isDark
                      ? DesignTokens.darkTextPrimary
                      : DesignTokens.gray900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.cli_usageMethod,
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _translateError(t),
          style: TextStyle(
            color: DesignTokens.error500,
            fontWeight: DesignTokens.fontWeightMedium,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              _errorDetail,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: DesignTokens.error500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          t.cli_fallbackInstallMethod,
          style: TextStyle(
            fontWeight: DesignTokens.fontWeightSemiBold,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(
            _getEnvInstructions(t),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Translations t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_state == _InstallState.installError) ...[
          ElevatedButton(
            onPressed: _checkAndInstall,
            child: Text(t.common_retry),
          ),
          const SizedBox(width: 8),
        ],
        if (_state == _InstallState.envError) ...[
          ElevatedButton(
            onPressed: () {
              setState(() => _state = _InstallState.checking);
              _checkAndInstall();
            },
            child: Text(t.cli_recheck),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            _state == _InstallState.installing
                ? t.common_cancel
                : t.common_close,
          ),
        ),
      ],
    );
  }
}
