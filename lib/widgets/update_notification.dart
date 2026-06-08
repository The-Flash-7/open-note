// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.g.dart';
import '../../providers/update_provider.dart';
import '../../theme/design_tokens.dart';

class UpdateNotification extends StatefulWidget {
  const UpdateNotification({super.key});

  @override
  State<UpdateNotification> createState() => _UpdateNotificationState();
}

class _UpdateNotificationState extends State<UpdateNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    if (mounted) {
      context.read<UpdateProvider>().dismissUpdate();
    }
  }

  void _skipVersion() async {
    await _controller.reverse();
    if (mounted) {
      await context.read<UpdateProvider>().skipVersion();
    }
  }

  void _update() {
    context.read<UpdateProvider>().downloadUpdate();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Consumer<UpdateProvider>(
      builder: (context, provider, child) {
        if (provider.state != UpdateState.updateAvailable ||
            provider.latestRelease == null) {
          return const SizedBox.shrink();
        }

        final release = provider.latestRelease!;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Positioned(
          top: 16,
          right: 16,
          width: 360,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.4 : 0.15,
                        ),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? DesignTokens.darkBorder
                          : DesignTokens.gray200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: DesignTokens.success.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.system_update,
                                color: DesignTokens.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.update_newVersionFound,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? DesignTokens.darkTextPrimary
                                          : DesignTokens.gray900,
                                    ),
                                  ),
                                  Text(
                                    'v${release.version}',
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (release.releaseNotes.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 120),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : DesignTokens.gray50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                release.releaseNotes
                                    .split('\n')
                                    .take(8)
                                    .join('\n'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? DesignTokens.darkTextSecondary
                                      : DesignTokens.gray500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _skipVersion,
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? DesignTokens.darkTextSecondary
                                    : DesignTokens.gray500,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(t.update_skipThisVersion),
                            ),
                            TextButton(
                              onPressed: _dismiss,
                              style: TextButton.styleFrom(
                                foregroundColor: isDark
                                    ? DesignTokens.darkTextSecondary
                                    : DesignTokens.gray500,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(t.update_remindLater),
                            ),
                            ElevatedButton(
                              onPressed: _update,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DesignTokens.primary500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(t.update_update),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
