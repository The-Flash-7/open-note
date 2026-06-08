// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../models/note.dart';
import '../services/ai_service.dart';
import 'notes_provider.dart';

enum BackgroundSummaryStatus { idle, running, paused }

class BackgroundSummaryProvider extends ChangeNotifier {
  BackgroundSummaryStatus _status = BackgroundSummaryStatus.idle;
  int _totalPending = 0;
  int _processedCount = 0;
  String? _currentProcessingNoteId;
  Timer? _periodicTimer;
  Timer? _idleTimer;
  bool _isAppInBackground = false;

  NotesProvider? _notesProvider;
  AIService? _aiService;

  BackgroundSummaryStatus get status => _status;
  bool get isRunning => _status == BackgroundSummaryStatus.running;
  bool get isPaused => _status == BackgroundSummaryStatus.paused;
  bool get isIdle => _status == BackgroundSummaryStatus.idle;
  int get totalPending => _totalPending;
  int get processedCount => _processedCount;
  String? get currentProcessingNoteId => _currentProcessingNoteId;
  bool get hasPending => _totalPending > 0;

  String get progressText {
    if (_totalPending == 0) return '';
    return '正在生成摘要... $_processedCount/$totalPending';
  }

  void setProviders(NotesProvider notesProvider, AIService aiService) {
    _notesProvider = notesProvider;
    _aiService = aiService;
  }

  Future<void> startBackgroundGeneration() async {
    if (_notesProvider == null || _aiService == null) return;
    if (!_aiService!.hasConfig()) return;
    if (_status == BackgroundSummaryStatus.running) return;

    _processedCount = 0;
    _status = BackgroundSummaryStatus.running;
    notifyListeners();

    await _processPendingNotes();

    _startPeriodicTimer();
    _startIdleTimer();
  }

  void pauseGeneration() {
    if (_status != BackgroundSummaryStatus.running) return;

    _status = BackgroundSummaryStatus.paused;
    _periodicTimer?.cancel();
    notifyListeners();
  }

  void resumeGeneration() async {
    if (_status != BackgroundSummaryStatus.paused) return;

    _status = BackgroundSummaryStatus.running;
    notifyListeners();

    await _processPendingNotes();
    _startPeriodicTimer();
  }

  void stopGeneration() {
    _status = BackgroundSummaryStatus.idle;
    _totalPending = 0;
    _processedCount = 0;
    _currentProcessingNoteId = null;
    _periodicTimer?.cancel();
    _idleTimer?.cancel();
    notifyListeners();
  }

  void onAppStateChanged(AppLifecycleState state) {
    _isAppInBackground =
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive;

    if (_isAppInBackground && _status == BackgroundSummaryStatus.idle) {
      _checkAndStartInBackground();
    }
  }

  Future<void> _checkAndStartInBackground() async {
    if (_notesProvider == null || _aiService == null) return;
    if (!_aiService!.hasConfig()) return;

    await _updatePendingCount();

    if (_totalPending > 0) {
      await startBackgroundGeneration();
    }
  }

  Future<void> _processPendingNotes() async {
    if (_notesProvider == null || _aiService == null) return;

    final notesToProcess = await _getNotesToProcess();
    _totalPending = notesToProcess.length;

    if (_totalPending == 0) {
      _status = BackgroundSummaryStatus.idle;
      notifyListeners();
      return;
    }

    notifyListeners();

    for (final note in notesToProcess) {
      if (_status != BackgroundSummaryStatus.running) break;

      _currentProcessingNoteId = note.id;
      notifyListeners();

      try {
        final plainText = _notesProvider!.extractPlainText(note.content);
        if (plainText.isNotEmpty) {
          final result = await _aiService!.generateSummaryAndKeywords(
            plainText,
          );
          final summary = result['summary'];
          final keywords = result['keywords'];

          final updatedNote = note.copyWith(
            summary: summary,
            keywords: keywords,
          );
          await _notesProvider!.updateNote(updatedNote);
        }
      } catch (e) {
        debugPrint(
          'Background summary generation error for note ${note.id}: $e',
        );
      }

      _processedCount++;
      _currentProcessingNoteId = null;
      notifyListeners();

      await Future.delayed(const Duration(seconds: 2));
    }

    if (_status == BackgroundSummaryStatus.running) {
      _status = BackgroundSummaryStatus.idle;
      _totalPending = 0;
      _processedCount = 0;
      notifyListeners();
    }
  }

  Future<List<Note>> _getNotesToProcess() async {
    if (_notesProvider == null) return [];

    await _notesProvider!.loadNotes();

    final currentEditingId = _notesProvider!.currentEditingNoteId;

    return _notesProvider!.notes
        .where(
          (note) =>
              (note.summary == null || note.summary!.isEmpty) &&
              note.content.isNotEmpty &&
              note.id != currentEditingId,
        )
        .toList();
  }

  Future<void> _updatePendingCount() async {
    final notesToProcess = await _getNotesToProcess();
    _totalPending = notesToProcess.length;
    notifyListeners();
  }

  void _startPeriodicTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      if (_status == BackgroundSummaryStatus.idle) {
        await _updatePendingCount();
        if (_totalPending > 0) {
          await startBackgroundGeneration();
        }
      }
    });
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 5), () async {
      if (_isAppInBackground && _status == BackgroundSummaryStatus.idle) {
        await _checkAndStartInBackground();
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }
}
