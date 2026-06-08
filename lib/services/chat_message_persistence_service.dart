// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/note.dart';
import 'sqlite_database_service.dart';

class ChatMessagePersistenceService {
  static final ChatMessagePersistenceService _instance =
      ChatMessagePersistenceService._internal();
  final SQLiteDatabaseService _db = SQLiteDatabaseService();
  final StreamController<ChatMessage> _onNewMessageSaved =
      StreamController<ChatMessage>.broadcast();

  factory ChatMessagePersistenceService() => _instance;

  ChatMessagePersistenceService._internal();

  final StreamController<void> _onCleared = StreamController<void>.broadcast();

  Stream<ChatMessage> get onNewMessageSaved => _onNewMessageSaved.stream;

  Stream<void> get onCleared => _onCleared.stream;

  static const int _defaultPageSize = 20;

  Future<void> saveMessage(ChatMessage message) async {
    try {
      await _db.saveChatMessage(message.toMap());
      _onNewMessageSaved.add(message);
    } catch (e) {
      debugPrint('保存聊天消息失败: $e');
    }
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    for (final message in messages) {
      await saveMessage(message);
    }
  }

  Future<List<ChatMessage>> loadRecentMessages({
    int limit = _defaultPageSize,
    required Future<Note?> Function(String noteId) loadNote,
  }) async {
    try {
      final entries = await _db.getRecentChatMessages(limit: limit);
      return await _parseMessages(entries, loadNote);
    } catch (e) {
      debugPrint('加载最近消息失败: $e');
      return [];
    }
  }

  Future<List<ChatMessage>> loadMoreMessages({
    required int offset,
    int limit = _defaultPageSize,
    required Future<Note?> Function(String noteId) loadNote,
  }) async {
    try {
      final entries = await _db.getChatMessagesPaginated(
        offset: offset,
        limit: limit,
      );
      return await _parseMessages(entries, loadNote);
    } catch (e) {
      debugPrint('加载更多消息失败: $e');
      return [];
    }
  }

  /// 加载更多历史消息（更早的消息）
  Future<List<ChatMessage>> loadEarlierMessages({
    required String beforeTimestamp,
    int limit = _defaultPageSize,
    required Future<Note?> Function(String noteId) loadNote,
  }) async {
    try {
      final entries = await _db.loadEarlierMessages(
        beforeTimestamp: beforeTimestamp,
        limit: limit,
      );
      return await _parseMessages(entries, loadNote);
    } catch (e) {
      debugPrint('加载更多历史消息失败: $e');
      return [];
    }
  }

  /// 更新消息的已回复状态
  Future<void> updateMessageRepliedStatus(
    String messageId,
    bool isReplied,
  ) async {
    await _db.updateMessageRepliedStatus(messageId, isReplied);
  }

  Future<int> getTotalMessageCount() async {
    try {
      final entries = await _db.getAllChatMessages();
      return entries.length;
    } catch (e) {
      debugPrint('获取消息总数失败: $e');
      return 0;
    }
  }

  Future<void> clearAllMessages() async {
    try {
      await _db.clearAllChatMessages();
      _onCleared.add(null);
    } catch (e) {
      debugPrint('清空消息失败: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.deleteChatMessage(messageId);
    } catch (e) {
      debugPrint('删除消息失败: $e');
    }
  }

  Future<List<ChatMessage>> _parseMessages(
    List<Map<String, dynamic>> maps,
    Future<Note?> Function(String noteId) loadNote,
  ) async {
    final messages = <ChatMessage>[];

    for (final map in maps) {
      try {
        // Convert SQLite types to Dart types
        final parsedMap = Map<String, dynamic>.from(map);

        // Convert isError from int to bool
        if (parsedMap['isError'] is int) {
          parsedMap['isError'] = (parsedMap['isError'] as int) == 1;
        }
        // Convert isFrozen from int to bool
        if (parsedMap['isFrozen'] is int) {
          parsedMap['isFrozen'] = (parsedMap['isFrozen'] as int) == 1;
        }
        // Convert isReplied from int to bool
        if (parsedMap['isReplied'] is int) {
          parsedMap['isReplied'] = (parsedMap['isReplied'] as int) == 1;
        }

        // Parse timestamp
        if (parsedMap['timestamp'] is String) {
          parsedMap['timestamp'] = DateTime.parse(
            parsedMap['timestamp'] as String,
          );
        }

        // Parse JSON strings back to lists
        List<ToolCall> toolCalls = [];
        if (parsedMap['toolCalls'] != null) {
          if (parsedMap['toolCalls'] is String) {
            final decoded =
                jsonDecode(parsedMap['toolCalls'] as String) as List<dynamic>;
            toolCalls = decoded
                .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
                .toList();
          } else if (parsedMap['toolCalls'] is List) {
            toolCalls = (parsedMap['toolCalls'] as List<dynamic>)
                .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
                .toList();
          }
        }

        List<ToolExecutionEntry>? toolExecutions;
        if (parsedMap['toolExecutions'] != null) {
          if (parsedMap['toolExecutions'] is String) {
            final decoded =
                jsonDecode(parsedMap['toolExecutions'] as String)
                    as List<dynamic>;
            toolExecutions = decoded
                .map(
                  (e) => ToolExecutionEntry.fromMap(e as Map<String, dynamic>),
                )
                .toList();
          } else if (parsedMap['toolExecutions'] is List) {
            toolExecutions = (parsedMap['toolExecutions'] as List<dynamic>)
                .map(
                  (e) => ToolExecutionEntry.fromMap(e as Map<String, dynamic>),
                )
                .toList();
          }
        }

        final List<String> noteIds = [];
        if (parsedMap['referencedNoteIds'] != null) {
          if (parsedMap['referencedNoteIds'] is String) {
            final decoded =
                jsonDecode(parsedMap['referencedNoteIds'] as String)
                    as List<dynamic>;
            noteIds.addAll(decoded.cast<String>());
          } else if (parsedMap['referencedNoteIds'] is List) {
            final ids = parsedMap['referencedNoteIds'] as List<dynamic>;
            noteIds.addAll(ids.cast<String>());
          }
        }

        final message = ChatMessage(
          id: parsedMap['id'] as String,
          role: parsedMap['role'] as String,
          content: parsedMap['content'] as String? ?? '',
          timestamp: parsedMap['timestamp'] is DateTime
              ? parsedMap['timestamp'] as DateTime
              : DateTime.now(),
          isError: parsedMap['isError'] as bool? ?? false,
          messageType: parsedMap['messageType'] != null
              ? CiciMessageType.values.byName(
                  parsedMap['messageType'] as String,
                )
              : CiciMessageType.assistant,
          toolCalls: toolCalls,
          toolExecutions: toolExecutions,
          searchMode: parsedMap['searchMode'] as String?,
          isFrozen: parsedMap['isFrozen'] as bool? ?? false,
          isReplied: parsedMap['isReplied'] as bool? ?? false,
          referencedNotes: const [],
        );

        if (noteIds.isNotEmpty) {
          final notes = <Note>[];
          for (final noteId in noteIds) {
            final note = await loadNote(noteId);
            if (note != null) {
              notes.add(note);
            }
          }
          final newMessage = message.copyWith(referencedNotes: notes);
          messages.add(newMessage);
        } else {
          messages.add(message);
        }
      } catch (e, st) {
        debugPrint('解析消息失败: $e');
        debugPrint('Stack trace: $st');
      }
    }

    return messages;
  }
}
