// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/note.dart';
import '../models/tag.dart';
import '../models/category.dart';

class SQLiteDatabaseService {
  static final SQLiteDatabaseService _instance =
      SQLiteDatabaseService._internal();
  Database? _db;

  factory SQLiteDatabaseService() => _instance;
  SQLiteDatabaseService._internal();

  Database? get db => _db;

  /// Initialize the SQLite database
  Future<void> init() async {
    if (_db != null) return;

    // Initialize FFI for desktop platforms
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
    }

    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'opennote.db');

    // Create directory if it doesn't exist
    await Directory(appDir.path).create(recursive: true);

    final factory = Platform.isMacOS || Platform.isWindows || Platform.isLinux
        ? databaseFactoryFfi
        : databaseFactory;

    _db = await factory.openDatabase(dbPath);

    // Create tables manually since openDatabase doesn't support onCreate for FFI
    final tables = await _db!.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    if (tables.isEmpty) {
      await _createTables(_db!, 1);
    }

    debugPrint('[SQLiteDatabaseService] Database initialized at: $dbPath');
  }

  /// Create all database tables
  Future<void> _createTables(Database db, int version) async {
    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT DEFAULT '',
        format TEXT DEFAULT 'markdown',
        language TEXT,
        summary TEXT,
        keywords TEXT,
        category TEXT,
        tags TEXT,
        source_url TEXT,
        source_type TEXT DEFAULT 'manual',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        word_count INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0,
        deleted_at INTEGER
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE NOT NULL,
        color TEXT,
        usage_count INTEGER DEFAULT 0
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parentId TEXT,
        level INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isVirtual INTEGER DEFAULT 0
      )
    ''');

    // Config table
    await db.execute('''
      CREATE TABLE config (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isError INTEGER DEFAULT 0,
        messageType TEXT DEFAULT 'assistant',
        isFrozen INTEGER DEFAULT 0,
        isReplied INTEGER DEFAULT 0,
        note_references TEXT,
        tool_calls TEXT,
        thinking TEXT
      )
    ''');

    // Agent memories table
    await db.execute('''
      CREATE TABLE agent_memories (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL,
        tags TEXT,
        confidence INTEGER DEFAULT 1,
        frequency INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_accessed TEXT NOT NULL,
        is_expired INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_notes_updated ON notes(updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_notes_favorite ON notes(is_favorite, updated_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_notes_category ON notes(category, is_deleted, updated_at DESC)',
    );
    await db.execute('CREATE INDEX idx_notes_deleted ON notes(is_deleted)');
    await db.execute('CREATE INDEX idx_tags_name ON tags(name)');
  }

  // ==================== Notes CRUD ====================

  /// Save or update a note
  Future<void> saveNote(Note note) async {
    await _db!.insert(
      'notes',
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a note by ID
  Future<Note?> getNoteById(String id) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'notes',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  /// Get a note by ID regardless of deleted status
  Future<Note?> getNoteByIdIncludingDeleted(String id) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  /// Get all notes (optionally filtered)
  Future<List<Note>> getNotes({
    String? categoryId,
    bool? isFavorite,
    int limit = 100,
    int offset = 0,
  }) async {
    String where = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      where += ' AND category = ?';
      whereArgs.add(categoryId);
    }
    if (isFavorite == true) {
      where += ' AND is_favorite = 1';
    }

    final List<Map<String, dynamic>> maps = await _db!.query(
      'notes',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((m) => Note.fromMap(m)).toList();
  }

  /// Search notes by title or content
  Future<List<Note>> searchNotes(String query, {int limit = 20}) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'notes',
      where: 'is_deleted = 0 AND (title LIKE ? OR content LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  /// Delete a note (soft delete)
  Future<void> deleteNote(String id) async {
    await _db!.update(
      'notes',
      {'is_deleted': 1, 'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently delete a note
  Future<void> hardDeleteNote(String id) async {
    await _db!.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  /// Get all deleted notes
  Future<List<Note>> getDeletedNotes() async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'notes',
      where: 'is_deleted = 1',
      orderBy: 'deleted_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  /// Get notes count
  Future<int> getNotesCount({String? categoryId, bool? isFavorite}) async {
    String where = 'is_deleted = 0';
    List<dynamic> whereArgs = [];

    if (categoryId != null) {
      where += ' AND category = ?';
      whereArgs.add(categoryId);
    }
    if (isFavorite == true) {
      where += ' AND is_favorite = 1';
    }

    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE $where',
      whereArgs,
    );
    return result.first['count'] as int;
  }

  // ==================== Tags CRUD ====================

  /// Save or update a tag
  Future<void> saveTag(Tag tag) async {
    await _db!.insert('tags', {
      'id': tag.id,
      'name': tag.name,
      'usage_count': tag.usageCount,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get all tags
  Future<List<Tag>> getTags() async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'tags',
      orderBy: 'usage_count DESC, name ASC',
    );
    return maps.map((m) => Tag.fromMap(m)).toList();
  }

  /// Get all tags with details (alias for getTags)
  Future<List<Tag>> getAllTagsWithDetails() async {
    return getTags();
  }

  /// Get a tag by ID
  Future<Tag?> getTagById(String id) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'tags',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  /// Get a tag by name
  Future<Tag?> getTagByName(String name) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  /// Delete a tag
  Future<void> deleteTag(String id) async {
    await _db!.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Categories CRUD ====================

  /// Save or update a category
  Future<void> saveCategory(Category category) async {
    await _db!.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'categories',
      orderBy: 'level ASC, name ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  /// Get a category by ID
  Future<Category?> getCategoryById(String id) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  /// Get a category by ID (alias)
  Future<Category?> getCategory(String id) async {
    return getCategoryById(id);
  }

  /// Get all categories list (alias)
  Future<List<Category>> getAllCategoriesList() async {
    return getCategories();
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    await _db!.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Config CRUD ====================

  /// Get a config value
  Future<String?> getConfig(String key) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'config',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  /// Set a config value
  Future<void> setConfig(String key, String value) async {
    await _db!.insert('config', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Delete a config value
  Future<void> deleteConfig(String key) async {
    await _db!.delete('config', where: 'key = ?', whereArgs: [key]);
  }

  // ==================== Chat Messages CRUD ====================

  /// Save a chat message
  Future<void> saveChatMessage(Map<String, dynamic> message) async {
    // Convert boolean values to integers for SQLite
    final safeMessage = Map<String, dynamic>.from(message);
    if (safeMessage['isError'] is bool) {
      safeMessage['isError'] = (safeMessage['isError'] as bool) ? 1 : 0;
    }
    if (safeMessage['isFrozen'] is bool) {
      safeMessage['isFrozen'] = (safeMessage['isFrozen'] as bool) ? 1 : 0;
    }
    if (safeMessage['isReplied'] is bool) {
      safeMessage['isReplied'] = (safeMessage['isReplied'] as bool) ? 1 : 0;
    }

    // Convert lists to JSON strings
    if (safeMessage['toolExecutions'] is List) {
      safeMessage['toolExecutions'] = jsonEncode(safeMessage['toolExecutions']);
    }
    if (safeMessage['toolCalls'] is List) {
      safeMessage['toolCalls'] = jsonEncode(safeMessage['toolCalls']);
    }
    if (safeMessage['referencedNoteIds'] is List) {
      safeMessage['referencedNoteIds'] = jsonEncode(
        safeMessage['referencedNoteIds'],
      );
    }

    await _db!.insert(
      'chat_messages',
      safeMessage,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get recent chat messages
  Future<List<Map<String, dynamic>>> getRecentChatMessages({
    int limit = 20,
  }) async {
    final results = await _db!.query(
      'chat_messages',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    // Reverse to return in ascending order (oldest first)
    return results.reversed.toList();
  }

  /// Get paginated chat messages
  Future<List<Map<String, dynamic>>> getChatMessagesPaginated({
    required int offset,
    int limit = 20,
  }) async {
    final results = await _db!.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
      limit: limit,
      offset: offset,
    );
    return results;
  }

  /// 加载更多历史消息（更早的消息）
  /// beforeTimestamp: 上次加载到的最早消息时间戳（获取比这个更早的消息）
  /// limit: 加载数量
  Future<List<Map<String, dynamic>>> loadEarlierMessages({
    required String beforeTimestamp,
    int limit = 20,
  }) async {
    final results = await _db!.rawQuery(
      '''
      SELECT * FROM chat_messages 
      WHERE timestamp < ? 
      ORDER BY timestamp DESC 
      LIMIT ?
    ''',
      [beforeTimestamp, limit],
    );

    return results.reversed.toList();
  }

  /// 更新消息的 isReplied 状态
  Future<void> updateMessageRepliedStatus(
    String messageId,
    bool isReplied,
  ) async {
    await _db!.update(
      'chat_messages',
      {'isReplied': isReplied ? 1 : 0},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// Get all chat messages
  Future<List<Map<String, dynamic>>> getAllChatMessages() async {
    return await _db!.query('chat_messages', orderBy: 'timestamp ASC');
  }

  /// Clear all chat messages
  Future<void> clearAllChatMessages() async {
    await _db!.delete('chat_messages');
  }

  /// Get all chat messages (legacy alias)
  Future<List<Map<String, dynamic>>> getChatMessages({int limit = 100}) async {
    return await _db!.query(
      'chat_messages',
      orderBy: 'timestamp ASC',
      limit: limit,
    );
  }

  /// Delete all chat messages (legacy alias)
  Future<void> clearChatMessages() async {
    await _db!.delete('chat_messages');
  }

  /// Delete a single chat message by ID
  Future<void> deleteChatMessage(String id) async {
    await _db!.delete('chat_messages', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== Agent Memories CRUD ====================

  /// Save an agent memory
  Future<void> saveAgentMemory(Map<String, dynamic> memory) async {
    await _db!.insert(
      'agent_memories',
      memory,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get agent memory by ID
  Future<Map<String, dynamic>?> getAgentMemory(String id) async {
    final List<Map<String, dynamic>> maps = await _db!.query(
      'agent_memories',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isEmpty ? null : maps.first;
  }

  /// Get all agent memories
  Future<List<Map<String, dynamic>>> getAllAgentMemories() async {
    return await _db!.query('agent_memories', orderBy: 'created_at DESC');
  }

  /// Delete an agent memory
  Future<void> deleteAgentMemory(String id) async {
    await _db!.delete('agent_memories', where: 'id = ?', whereArgs: [id]);
  }

  /// Clear all agent memories
  Future<void> clearAllAgentMemories() async {
    await _db!.delete('agent_memories');
  }

  /// Get all agent memories (alias)
  Future<List<Map<String, dynamic>>> getAgentMemories() async {
    return getAllAgentMemories();
  }

  // ==================== Utility Methods ====================

  /// Close the database
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Check if database is initialized
  bool get isInitialized => _db != null;

  /// Run a database transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return _db!.transaction(action);
  }
}
