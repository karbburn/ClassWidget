import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/schedule_event.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 3;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'class_widget_v2.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        professor TEXT,
        section TEXT,
        type TEXT NOT NULL DEFAULT 'class',
        notes TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        is_imported INTEGER NOT NULL DEFAULT 1,
        date TEXT NOT NULL,
        UNIQUE(date, start_time, title) ON CONFLICT IGNORE
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        due_date TEXT,
        related_course TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            due_date TEXT,
            related_course TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 3) {
      // Add new columns to events table safely
      try {
        await db.execute("ALTER TABLE events ADD COLUMN type TEXT NOT NULL DEFAULT 'class'");
      } catch (_) {}
      
      try {
        await db.execute("ALTER TABLE events ADD COLUMN notes TEXT");
      } catch (_) {}
      
      try {
        await db.execute("ALTER TABLE events ADD COLUMN completed INTEGER NOT NULL DEFAULT 0");
      } catch (_) {}
      
      // Migrate existing tasks if any (optional but nice)
      try {
        final List<Map<String, dynamic>> tasks = await db.query('tasks');
        for (var task in tasks) {
          await db.insert('events', {
            'title': task['title'],
            'start_time': '',
            'end_time': '',
            'type': 'task',
            'completed': task['is_completed'],
            'is_imported': 0,
            'date': task['due_date'] ?? '',
            'professor': task['related_course'],
          });
        }
      } catch (_) {
        // Table 'tasks' might not exist or migration already done
      }
    }
  }

  /// Atomic transaction to replace imported schedule
  Future<void> importScheduleTransaction(List<ScheduleEvent> events) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Delete old imported events
      await txn.delete(
        'events',
        where: 'is_imported = ?',
        whereArgs: [1],
      );

      // 2. Insert new events
      for (var event in events) {
        await txn.insert('events', event.toMap());
      }
    });
  }

  Future<int> insertEvent(ScheduleEvent event) async {
    Database db = await database;
    return await db.insert('events', event.toMap());
  }

  Future<List<ScheduleEvent>> getEventsForToday(String date) async {
    return _getSortedEventsByDate(date);
  }

  Future<List<ScheduleEvent>> getEventsForTomorrow(String date) async {
    return _getSortedEventsByDate(date);
  }

  Future<ScheduleEvent?> getNextEvent(String date, String currentTime) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'date = ? AND start_time > ?',
      whereArgs: [date, currentTime],
      orderBy: 'start_time ASC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ScheduleEvent.fromMap(maps.first);
  }

  Future<List<ScheduleEvent>> getEventsForDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC',
    );
    return List.generate(maps.length, (i) => ScheduleEvent.fromMap(maps[i]));
  }

  Future<void> updateEventCompletion(int id, bool completed) async {
    Database db = await database;
    await db.update(
      'events',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEvent(int id) async {
    Database db = await database;
    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteImportedEvents() async {
    Database db = await database;
    await db.delete('events', where: 'is_imported = ?', whereArgs: [1]);
  }

  Future<List<ScheduleEvent>> _getSortedEventsByDate(String date) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'start_time ASC',
    );
    return List.generate(maps.length, (i) => ScheduleEvent.fromMap(maps[i]));
  }
}
