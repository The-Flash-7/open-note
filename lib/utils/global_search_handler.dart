// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notes_provider.dart';
import '../widgets/search_dialog.dart';

class GlobalSearchHandler {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void openSearchDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notesProvider = context.read<NotesProvider>();

    showDialog(
      context: context,
      builder: (context) => SearchDialog(notesProvider: notesProvider),
    );
  }
}
