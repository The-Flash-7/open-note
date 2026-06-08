// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../models/note.dart';

enum CiciMessageType { user, assistant, system, toolExecution }

enum ToolStatus { calling, completed, failed, cancelled }

class ToolCall {
  final String tool;
  final Map<String, dynamic> args;

  const ToolCall({required this.tool, required this.args});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      tool: json['tool'] as String? ?? '',
      args: (json['args'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {'tool': tool, 'args': args};
  }

  @override
  String toString() {
    return 'ToolCall(tool: $tool, args: $args)';
  }
}

class ToolExecutionEntry {
  final String toolId;
  final String toolName;
  final String icon;
  ToolStatus status;
  String statusLabel;
  List<String> details;
  String? rawArgs;
  bool isExpanded;
  Map<String, dynamic>? resultData;

  ToolExecutionEntry({
    required this.toolId,
    required this.toolName,
    required this.icon,
    required this.statusLabel,
    this.status = ToolStatus.calling,
    this.details = const [],
    this.rawArgs,
    this.isExpanded = false,
    this.resultData,
  });

  ToolExecutionEntry copyWith({
    ToolStatus? status,
    String? statusLabel,
    List<String>? details,
    String? rawArgs,
    bool? isExpanded,
    Map<String, dynamic>? resultData,
  }) {
    return ToolExecutionEntry(
      toolId: toolId,
      toolName: toolName,
      icon: icon,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      details: details ?? List.from(this.details),
      rawArgs: rawArgs ?? this.rawArgs,
      isExpanded: isExpanded ?? this.isExpanded,
      resultData: resultData ?? this.resultData,
    );
  }

  static String iconForTool(String toolName) {
    switch (toolName) {
      case 'note_search':
      case 'note_read':
        return '🔍';
      case 'note_edit_info':
        return '✏️';
      case 'note_delete':
        return '🗑️';
      case 'note_create':
        return '📝';
      default:
        return '⚙️';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'toolId': toolId,
      'toolName': toolName,
      'icon': icon,
      'status': status.name,
      'statusLabel': statusLabel,
      'details': details,
      'rawArgs': rawArgs,
      'isExpanded': isExpanded,
    };
  }

  factory ToolExecutionEntry.fromMap(Map<String, dynamic> map) {
    return ToolExecutionEntry(
      toolId: map['toolId'] as String? ?? '',
      toolName: map['toolName'] as String? ?? '',
      icon: map['icon'] as String? ?? '⚙️',
      status: ToolStatus.values.byName(map['status'] as String? ?? 'calling'),
      statusLabel: map['statusLabel'] as String? ?? '',
      details: (map['details'] as List<dynamic>?)?.cast<String>() ?? [],
      rawArgs: map['rawArgs'] as String?,
      isExpanded: map['isExpanded'] as bool? ?? false,
    );
  }
}

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final DateTime timestamp;
  final List<Note> referencedNotes;
  final List<ToolCall> toolCalls;
  final bool isError;
  final CiciMessageType messageType;
  final List<ToolExecutionEntry>? toolExecutions;
  final String? searchMode;
  final bool isFrozen;
  final bool isReplied;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.referencedNotes = const [],
    this.toolCalls = const [],
    this.isError = false,
    this.messageType = CiciMessageType.assistant,
    this.toolExecutions,
    this.searchMode,
    this.isFrozen = false,
    this.isReplied = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: _generateId(),
      role: 'user',
      content: content,
      messageType: CiciMessageType.user,
      isReplied: false,
    );
  }

  factory ChatMessage.assistant(
    String content, {
    List<Note> referencedNotes = const [],
    List<ToolCall> toolCalls = const [],
    String? searchMode,
  }) {
    return ChatMessage(
      id: _generateId(),
      role: 'assistant',
      content: content,
      referencedNotes: referencedNotes,
      toolCalls: toolCalls,
      messageType: CiciMessageType.assistant,
      searchMode: searchMode,
    );
  }

  factory ChatMessage.system(String content) {
    return ChatMessage(
      id: _generateId(),
      role: 'system',
      content: content,
      messageType: CiciMessageType.system,
    );
  }

  factory ChatMessage.toolExecution({
    required List<ToolExecutionEntry> entries,
  }) {
    return ChatMessage(
      id: _generateId(),
      role: 'system',
      content: '',
      messageType: CiciMessageType.toolExecution,
      toolExecutions: entries,
    );
  }

  factory ChatMessage.error(String message) {
    return ChatMessage(
      id: _generateId(),
      role: 'assistant',
      content: message,
      isError: true,
      messageType: CiciMessageType.system,
    );
  }

  ChatMessage copyWith({
    String? content,
    List<Note>? referencedNotes,
    List<ToolCall>? toolCalls,
    bool? isError,
    List<ToolExecutionEntry>? toolExecutions,
    String? searchMode,
    bool? isFrozen,
    bool? isReplied,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      referencedNotes: referencedNotes ?? this.referencedNotes,
      toolCalls: toolCalls ?? this.toolCalls,
      isError: isError ?? this.isError,
      messageType: messageType,
      toolExecutions: toolExecutions ?? this.toolExecutions,
      searchMode: searchMode ?? this.searchMode,
      isFrozen: isFrozen ?? this.isFrozen,
      isReplied: isReplied ?? this.isReplied,
    );
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'id': id,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError,
      'messageType': messageType.name,
      'isFrozen': isFrozen,
      'isReplied': isReplied,
    };

    if (toolCalls.isNotEmpty) {
      data['toolCalls'] = toolCalls.map((tc) => tc.toJson()).toList();
    }

    if (referencedNotes.isNotEmpty) {
      data['referencedNoteIds'] = referencedNotes.map((n) => n.id).toList();
    }

    if (toolExecutions != null && toolExecutions!.isNotEmpty) {
      data['toolExecutions'] = toolExecutions!.map((e) => e.toMap()).toList();
    }

    if (searchMode != null) {
      data['searchMode'] = searchMode;
    }

    return data;
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final messageType = CiciMessageType.values.byName(
      map['messageType'] as String? ?? 'assistant',
    );

    List<ToolCall> toolCalls = [];
    if (map['toolCalls'] != null) {
      toolCalls = (map['toolCalls'] as List<dynamic>)
          .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
          .toList();
    }

    List<ToolExecutionEntry>? toolExecutions;
    if (map['toolExecutions'] != null) {
      toolExecutions = (map['toolExecutions'] as List<dynamic>)
          .map((e) => ToolExecutionEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }

    return ChatMessage(
      id: map['id'] as String? ?? _generateId(),
      role: map['role'] as String? ?? 'assistant',
      content: map['content'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      isError: map['isError'] as bool? ?? false,
      messageType: messageType,
      toolCalls: toolCalls,
      toolExecutions: toolExecutions,
      searchMode: map['searchMode'] as String?,
      isFrozen: map['isFrozen'] as bool? ?? true,
      isReplied: map['isReplied'] as bool? ?? false,
    );
  }

  List<String> get referencedNoteIds {
    return referencedNotes.map((n) => n.id).toList();
  }
}

class AgentResponse {
  final String text;
  final List<Note> referencedNotes;
  final bool usedTools;
  final List<ToolCall> toolCalls;
  final String? error;
  final String? searchMode;
  final bool isCancelled;
  final Map<String, dynamic>? uiAction;

  const AgentResponse({
    required this.text,
    this.referencedNotes = const [],
    this.usedTools = false,
    this.toolCalls = const [],
    this.error,
    this.searchMode,
    this.isCancelled = false,
    this.uiAction,
  });

  factory AgentResponse.fromError(String message) {
    return AgentResponse(text: message, error: message);
  }

  factory AgentResponse.cancelled() {
    return AgentResponse(text: '操作已被用户中断', isCancelled: true);
  }
}
