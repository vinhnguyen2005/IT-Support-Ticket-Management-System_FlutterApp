import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._();

  static const String databaseName = 'it_support.db';
  static const int databaseVersion = 3;

  static const String usersTable = 'users';
  static const String departmentsTable = 'departments';
  static const String categoriesTable = 'categories';
  static const String prioritiesTable = 'priorities';
  static const String ticketsTable = 'tickets';
  static const String ticketAssignmentsTable = 'ticket_assignments';
  static const String progressUpdatesTable = 'progress_updates';
  static const String ticketCommentsTable = 'ticket_comments';
  static const String ticketAttachmentsTable = 'ticket_attachments';
  static const String ticketStatusHistoriesTable = 'ticket_status_histories';
  static const String feedbackTable = 'feedback';

  static Database? _database;

  static Future<Database> get instance async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    final database = await openDatabase(
      path,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _database = database;
    return database;
  }

  static Future<void> _onConfigure(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database database, int version) async {
    await _createSchema(database);
    await _createIndexes(database);
    await seedReferenceData(databaseOverride: database);
  }

  static Future<void> _onUpgrade(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    await _createSchema(database);
    if (oldVersion < 2) {
      await _migrateTicketsV1ToV2(database);
    }
    if (oldVersion < 3) {
      await _migrateUsersV2ToV3(database);
    }
    await _createIndexes(database);
    await seedReferenceData(databaseOverride: database);
  }

  static Future<void> _createSchema(Database database) async {
    final batch = database.batch();

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $departmentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        passwordHash TEXT,
        role TEXT NOT NULL,
        departmentId INTEGER,
        phoneNumber TEXT,
        avatarUrl TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        mustChangePassword INTEGER NOT NULL DEFAULT 1,
        lastLoginAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (departmentId) REFERENCES $departmentsTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        departmentId INTEGER,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (departmentId) REFERENCES $departmentsTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $prioritiesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        level INTEGER NOT NULL,
        slaHours INTEGER,
        colorHex TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $ticketsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        issueType TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        createdByUserId INTEGER,
        assignedStaffId INTEGER,
        categoryId INTEGER,
        priorityId INTEGER,
        departmentId INTEGER,
        closedAt TEXT,
        reopenedAt TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (createdByUserId) REFERENCES $usersTable(id),
        FOREIGN KEY (assignedStaffId) REFERENCES $usersTable(id),
        FOREIGN KEY (categoryId) REFERENCES $categoriesTable(id),
        FOREIGN KEY (priorityId) REFERENCES $prioritiesTable(id),
        FOREIGN KEY (departmentId) REFERENCES $departmentsTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $ticketAssignmentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId INTEGER NOT NULL,
        staffId INTEGER NOT NULL,
        assignedByUserId INTEGER,
        assignedAt TEXT NOT NULL,
        note TEXT,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (ticketId) REFERENCES $ticketsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (staffId) REFERENCES $usersTable(id),
        FOREIGN KEY (assignedByUserId) REFERENCES $usersTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $progressUpdatesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId INTEGER NOT NULL,
        staffId INTEGER NOT NULL,
        message TEXT NOT NULL,
        progressPercent INTEGER,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (ticketId) REFERENCES $ticketsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (staffId) REFERENCES $usersTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $ticketCommentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId INTEGER NOT NULL,
        authorId INTEGER NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (ticketId) REFERENCES $ticketsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (authorId) REFERENCES $usersTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $ticketAttachmentsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId INTEGER NOT NULL,
        uploadedByUserId INTEGER NOT NULL,
        fileName TEXT NOT NULL,
        filePath TEXT NOT NULL,
        contentType TEXT,
        fileSizeBytes INTEGER,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (ticketId) REFERENCES $ticketsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (uploadedByUserId) REFERENCES $usersTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $ticketStatusHistoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId INTEGER NOT NULL,
        changedByUserId INTEGER,
        fromStatus TEXT,
        toStatus TEXT NOT NULL,
        note TEXT,
        changedAt TEXT NOT NULL,
        FOREIGN KEY (ticketId) REFERENCES $ticketsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (changedByUserId) REFERENCES $usersTable(id)
      )
    ''');

    batch.execute('''
      CREATE TABLE IF NOT EXISTS $feedbackTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticketId INTEGER NOT NULL UNIQUE,
        userId INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        comment TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (ticketId) REFERENCES $ticketsTable(id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES $usersTable(id)
      )
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> _createIndexes(Database database) async {
    final batch = database.batch();

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_users_role
      ON $usersTable(role)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_tickets_status
      ON $ticketsTable(status)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_tickets_created_by
      ON $ticketsTable(createdByUserId)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_tickets_assigned_staff
      ON $ticketsTable(assignedStaffId)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_progress_updates_ticket
      ON $progressUpdatesTable(ticketId)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket
      ON $ticketCommentsTable(ticketId)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_ticket_status_histories_ticket
      ON $ticketStatusHistoriesTable(ticketId)
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS idx_feedback_ticket
      ON $feedbackTable(ticketId)
    ''');

    await batch.commit(noResult: true);
  }

  static Future<void> _migrateTicketsV1ToV2(Database database) async {
    final existingColumns = await _getColumnNames(database, ticketsTable);
    final columnsToAdd = <String, String>{
      'createdByUserId': 'INTEGER',
      'assignedStaffId': 'INTEGER',
      'categoryId': 'INTEGER',
      'priorityId': 'INTEGER',
      'departmentId': 'INTEGER',
      'closedAt': 'TEXT',
      'reopenedAt': 'TEXT',
    };

    for (final entry in columnsToAdd.entries) {
      if (existingColumns.contains(entry.key)) {
        continue;
      }

      await database.execute(
        'ALTER TABLE $ticketsTable ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
  }

  static Future<void> _migrateUsersV2ToV3(Database database) async {
    final existingColumns = await _getColumnNames(database, usersTable);
    final columnsToAdd = <String, String>{
      'mustChangePassword': 'INTEGER NOT NULL DEFAULT 1',
      'lastLoginAt': 'TEXT',
    };

    for (final entry in columnsToAdd.entries) {
      if (existingColumns.contains(entry.key)) {
        continue;
      }

      await database.execute(
        'ALTER TABLE $usersTable ADD COLUMN ${entry.key} ${entry.value}',
      );
    }
  }

  static Future<Set<String>> _getColumnNames(
    Database database,
    String tableName,
  ) async {
    final rows = await database.rawQuery('PRAGMA table_info($tableName)');
    return rows.map((row) => row['name'] as String).toSet();
  }

  static Future<void> seedReferenceData({Database? databaseOverride}) async {
    final database = databaseOverride ?? await instance;
    final now = DateTime.now().toIso8601String();

    await database.transaction((transaction) async {
      await transaction.insert(
        departmentsTable,
        {
          'name': 'IT Support',
          'description': 'General technical support team',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        departmentsTable,
        {
          'name': 'Network',
          'description': 'Network and connectivity support',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        departmentsTable,
        {
          'name': 'Hardware',
          'description': 'Device, printer, and hardware support',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        categoriesTable,
        {
          'name': 'Network Issue',
          'description': 'Internet, Wi-Fi, VPN, or LAN problems',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        categoriesTable,
        {
          'name': 'Hardware Issue',
          'description': 'Laptop, monitor, printer, or peripheral problems',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        categoriesTable,
        {
          'name': 'Software Issue',
          'description': 'Application installation, crash, or access problems',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        prioritiesTable,
        {
          'name': 'Low',
          'level': 1,
          'slaHours': 72,
          'colorHex': '#2E7D32',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        prioritiesTable,
        {
          'name': 'Medium',
          'level': 2,
          'slaHours': 48,
          'colorHex': '#F9A825',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        prioritiesTable,
        {
          'name': 'High',
          'level': 3,
          'slaHours': 24,
          'colorHex': '#EF6C00',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        prioritiesTable,
        {
          'name': 'Critical',
          'level': 4,
          'slaHours': 4,
          'colorHex': '#C62828',
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      await transaction.insert(
        usersTable,
        {
          'fullName': 'System Administrator',
          'username': 'admin',
          'email': 'admin@example.com',
          'passwordHash': PasswordHasher.hash('Admin@123'),
          'role': 'admin',
          'isActive': 1,
          'mustChangePassword': 1,
          'createdAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
  }

  static Future<List<String>> get tableNames async {
    final database = await instance;
    final rows = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

    return rows.map((row) => row['name'] as String).toList();
  }

  static Future<void> resetForDevelopment() async {
    final database = await instance;
    final batch = database.batch();

    batch.execute('DROP TABLE IF EXISTS $feedbackTable');
    batch.execute('DROP TABLE IF EXISTS $ticketStatusHistoriesTable');
    batch.execute('DROP TABLE IF EXISTS $ticketAttachmentsTable');
    batch.execute('DROP TABLE IF EXISTS $ticketCommentsTable');
    batch.execute('DROP TABLE IF EXISTS $progressUpdatesTable');
    batch.execute('DROP TABLE IF EXISTS $ticketAssignmentsTable');
    batch.execute('DROP TABLE IF EXISTS $ticketsTable');
    batch.execute('DROP TABLE IF EXISTS $prioritiesTable');
    batch.execute('DROP TABLE IF EXISTS $categoriesTable');
    batch.execute('DROP TABLE IF EXISTS $usersTable');
    batch.execute('DROP TABLE IF EXISTS $departmentsTable');

    await batch.commit(noResult: true);
    await _createSchema(database);
    await _createIndexes(database);
    await seedReferenceData(databaseOverride: database);
  }

  static Future<void> close() async {
    final database = _database;
    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}
