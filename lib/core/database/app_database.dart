import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../enums/issue_type.dart';
import '../enums/priority_level.dart';
import '../enums/ticket_status.dart';
import '../security/password_hasher.dart';

class AppDatabase {
  AppDatabase._();

  static const String databaseName = 'it_support.db';
  static const int databaseVersion = 8;

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
    if (oldVersion < 5) {
      await _migrateUsersV4ToV5(database);
    }
    if (oldVersion < 6) {
      await _migrateTicketsV5ToV6(database);
    }
    if (oldVersion < 7) {
      await _migrateCategoryDepartmentsV6ToV7(database);
    }
    if (oldVersion < 8) {
      await _migrateTicketsV7ToV8(database);
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
        failedLoginAttempts INTEGER NOT NULL DEFAULT 0,
        lockedUntil TEXT,
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
        attachmentUrl TEXT,
        solutionSummary TEXT,
        createdByUserId INTEGER,
        assignedStaffId INTEGER,
        categoryId INTEGER,
        priorityId INTEGER,
        departmentId INTEGER,
        resolvedAt TEXT,
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

  static Future<void> _migrateUsersV4ToV5(Database database) async {
    final existingColumns = await _getColumnNames(database, usersTable);
    final columnsToAdd = <String, String>{
      'failedLoginAttempts': 'INTEGER NOT NULL DEFAULT 0',
      'lockedUntil': 'TEXT',
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

  static Future<void> _migrateTicketsV5ToV6(Database database) async {
    final existingColumns = await _getColumnNames(database, ticketsTable);
    final columnsToAdd = <String, String>{
      'solutionSummary': 'TEXT',
      'resolvedAt': 'TEXT',
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

  static Future<void> _migrateCategoryDepartmentsV6ToV7(
    Database database,
  ) async {
    await _syncCategoryDepartments(database, DateTime.now().toIso8601String());
  }

  static Future<void> _migrateTicketsV7ToV8(Database database) async {
    final existingColumns = await _getColumnNames(database, ticketsTable);
    if (!existingColumns.contains('attachmentUrl')) {
      await database.execute(
        'ALTER TABLE $ticketsTable ADD COLUMN attachmentUrl TEXT',
      );
    }
  }

  static Future<void> _syncCategoryDepartments(
    DatabaseExecutor executor,
    String now,
  ) async {
    await executor.rawInsert(
      '''
      INSERT OR IGNORE INTO $categoriesTable (
        name,
        description,
        departmentId,
        createdAt
      )
      VALUES (
        ?,
        ?,
        (SELECT id FROM $departmentsTable WHERE name = ? LIMIT 1),
        ?
      )
      ''',
      [
        'General Support',
        'General IT support requests that do not fit another category',
        'IT Support',
        now,
      ],
    );

    final categoryDepartments = <String, String>{
      'General Support': 'IT Support',
      'Network Issue': 'Network',
      'Hardware Issue': 'Hardware',
      'Software Issue': 'IT Support',
    };

    for (final entry in categoryDepartments.entries) {
      await executor.rawUpdate(
        '''
        UPDATE $categoriesTable
        SET
          departmentId = (
            SELECT id
            FROM $departmentsTable
            WHERE name = ?
            LIMIT 1
          ),
          updatedAt = ?
        WHERE name = ?
        ''',
        [entry.value, now, entry.key],
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
      await transaction.insert(departmentsTable, {
        'name': 'IT Support',
        'description': 'General technical support team',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(departmentsTable, {
        'name': 'Network',
        'description': 'Network and connectivity support',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(departmentsTable, {
        'name': 'Hardware',
        'description': 'Device, printer, and hardware support',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(categoriesTable, {
        'name': 'Network Issue',
        'description': 'Internet, Wi-Fi, VPN, or LAN problems',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(categoriesTable, {
        'name': 'Hardware Issue',
        'description': 'Laptop, monitor, printer, or peripheral problems',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(categoriesTable, {
        'name': 'Software Issue',
        'description': 'Application installation, crash, or access problems',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await _syncCategoryDepartments(transaction, now);

      await transaction.insert(prioritiesTable, {
        'name': 'Low',
        'level': 1,
        'slaHours': 72,
        'colorHex': '#2E7D32',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(prioritiesTable, {
        'name': 'Medium',
        'level': 2,
        'slaHours': 48,
        'colorHex': '#F9A825',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(prioritiesTable, {
        'name': 'High',
        'level': 3,
        'slaHours': 24,
        'colorHex': '#EF6C00',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(prioritiesTable, {
        'name': 'Critical',
        'level': 4,
        'slaHours': 4,
        'colorHex': '#C62828',
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(usersTable, {
        'fullName': 'Super Administrator',
        'username': 'superadmin',
        'email': 'superadmin@example.com',
        'passwordHash': PasswordHasher.hash('Super@123'),
        'role': 'super_admin',
        'isActive': 1,
        'mustChangePassword': 0,
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(usersTable, {
        'fullName': 'System Administrator',
        'username': 'admin',
        'email': 'admin@example.com',
        'passwordHash': PasswordHasher.hash('Admin@123'),
        'role': 'admin',
        'isActive': 1,
        'mustChangePassword': 0,
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.update(
        usersTable,
        {'mustChangePassword': 0, 'updatedAt': now},
        where: 'username IN (?, ?)',
        whereArgs: ['superadmin', 'admin'],
      );

      await transaction.insert(usersTable, {
        'fullName': 'Support Staff',
        'username': 'staff',
        'email': 'staff@example.com',
        'passwordHash': PasswordHasher.hash('Staff@123'),
        'role': 'staff',
        'departmentId': 1,
        'isActive': 1,
        'mustChangePassword': 1,
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await transaction.insert(usersTable, {
        'fullName': 'Support Staff',
        'username': 'staff',
        'email': 'staff@example.com',
        'passwordHash': PasswordHasher.hash('Staff@123'),
        'role': 'staff',
        'isActive': 1,
        'mustChangePassword': 1,
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      final adminId = await _findSeedRowId(
        transaction,
        usersTable,
        'username',
        'admin',
      );
      final staffId = await _findSeedRowId(
        transaction,
        usersTable,
        'username',
        'staff',
      );

      await transaction.insert(usersTable, {
        'fullName': 'Demo Employee',
        'username': 'employee',
        'email': 'employee@example.com',
        'passwordHash': PasswordHasher.hash('User@123'),
        'role': 'user',
        'departmentId': 1,
        'isActive': 1,
        'mustChangePassword': 1,
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'createdAt': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      final employeeId = await _findSeedRowId(
        transaction,
        usersTable,
        'username',
        'employee',
      );
      final itSupportDepartmentId = await _findSeedRowId(
        transaction,
        departmentsTable,
        'name',
        'IT Support',
      );
      final networkDepartmentId = await _findSeedRowId(
        transaction,
        departmentsTable,
        'name',
        'Network',
      );
      final hardwareDepartmentId = await _findSeedRowId(
        transaction,
        departmentsTable,
        'name',
        'Hardware',
      );
      final networkCategoryId = await _findSeedRowId(
        transaction,
        categoriesTable,
        'name',
        'Network Issue',
      );
      final hardwareCategoryId = await _findSeedRowId(
        transaction,
        categoriesTable,
        'name',
        'Hardware Issue',
      );
      final softwareCategoryId = await _findSeedRowId(
        transaction,
        categoriesTable,
        'name',
        'Software Issue',
      );
      final criticalPriorityId = await _findSeedRowId(
        transaction,
        prioritiesTable,
        'name',
        'Critical',
      );
      final highPriorityId = await _findSeedRowId(
        transaction,
        prioritiesTable,
        'name',
        'High',
      );
      final mediumPriorityId = await _findSeedRowId(
        transaction,
        prioritiesTable,
        'name',
        'Medium',
      );

      if (staffId != null) {
        final vpnTicketId = await _insertSeedTicketIfAbsent(
          transaction,
          title: '[Seed] VPN disconnects during payroll',
          description:
              'Finance team cannot keep VPN connected while submitting payroll.',
          issueType: IssueType.network.value,
          priority: PriorityLevel.critical.value,
          status: TicketStatus.processing.value,
          createdByUserId: employeeId,
          staffId: staffId,
          categoryId: networkCategoryId,
          priorityId: criticalPriorityId,
          departmentId: networkDepartmentId ?? 1,
          createdAt: now,
        );

        final printerTicketId = await _insertSeedTicketIfAbsent(
          transaction,
          title: '[Seed] Printer on floor 3 shows paper jam',
          description:
              'Shared printer reports a paper jam after every restart.',
          issueType: IssueType.hardware.value,
          priority: PriorityLevel.high.value,
          status: TicketStatus.assigned.value,
          createdByUserId: employeeId,
          staffId: staffId,
          categoryId: hardwareCategoryId,
          priorityId: highPriorityId,
          departmentId: hardwareDepartmentId ?? 1,
          createdAt: now,
        );

        final emailTicketId = await _insertSeedTicketIfAbsent(
          transaction,
          title: '[Seed] Outlook cannot sync shared mailbox',
          description:
              'User can sign in but the accounting shared mailbox never syncs.',
          issueType: IssueType.software.value,
          priority: PriorityLevel.medium.value,
          status: TicketStatus.pending.value,
          createdByUserId: employeeId,
          staffId: staffId,
          categoryId: softwareCategoryId,
          priorityId: mediumPriorityId,
          departmentId: itSupportDepartmentId ?? 1,
          createdAt: now,
        );

        await _insertSeedAssignmentIfAbsent(
          transaction,
          ticketId: vpnTicketId,
          staffId: staffId,
          assignedByUserId: adminId,
          note: 'Seed assignment for staff queue testing.',
          createdAt: now,
        );
        await _insertSeedAssignmentIfAbsent(
          transaction,
          ticketId: printerTicketId,
          staffId: staffId,
          assignedByUserId: adminId,
          note: 'Seed assignment for staff queue testing.',
          createdAt: now,
        );
        await _insertSeedAssignmentIfAbsent(
          transaction,
          ticketId: emailTicketId,
          staffId: staffId,
          assignedByUserId: adminId,
          note: 'Seed assignment for staff queue testing.',
          createdAt: now,
        );

        await _insertSeedProgressUpdateIfAbsent(
          transaction,
          ticketId: vpnTicketId,
          staffId: staffId,
          message: 'Confirmed issue and started checking VPN gateway logs.',
          createdAt: now,
        );
        await _insertSeedProgressUpdateIfAbsent(
          transaction,
          ticketId: emailTicketId,
          staffId: staffId,
          message: 'Waiting for mailbox permission refresh to complete.',
          createdAt: now,
        );
      }
    });
  }

  static Future<int?> _findSeedRowId(
    Transaction transaction,
    String table,
    String column,
    Object value,
  ) async {
    final rows = await transaction.query(
      table,
      columns: ['id'],
      where: '$column = ?',
      whereArgs: [value],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['id'] as int;
  }

  static Future<int> _insertSeedTicketIfAbsent(
    Transaction transaction, {
    required String title,
    required String description,
    required String issueType,
    required String priority,
    required String status,
    required int? createdByUserId,
    required int staffId,
    required int? categoryId,
    required int? priorityId,
    required int departmentId,
    required String createdAt,
  }) async {
    final existingId = await _findSeedRowId(
      transaction,
      ticketsTable,
      'title',
      title,
    );
    if (existingId != null) {
      await transaction.update(
        ticketsTable,
        {
          'status': status,
          'assignedStaffId': staffId,
          'categoryId': categoryId,
          'priorityId': priorityId,
          'departmentId': departmentId,
          'updatedAt': createdAt,
        },
        where: 'id = ?',
        whereArgs: [existingId],
      );
      return existingId;
    }

    return transaction.insert(ticketsTable, {
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'status': status,
      'createdByUserId': createdByUserId,
      'assignedStaffId': staffId,
      'categoryId': categoryId,
      'priorityId': priorityId,
      'departmentId': departmentId,
      'createdAt': createdAt,
    });
  }

  static Future<void> _insertSeedAssignmentIfAbsent(
    Transaction transaction, {
    required int ticketId,
    required int staffId,
    required int? assignedByUserId,
    required String note,
    required String createdAt,
  }) async {
    final rows = await transaction.query(
      ticketAssignmentsTable,
      columns: ['id'],
      where: 'ticketId = ? AND staffId = ?',
      whereArgs: [ticketId, staffId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }

    await transaction.insert(ticketAssignmentsTable, {
      'ticketId': ticketId,
      'staffId': staffId,
      'assignedByUserId': assignedByUserId,
      'assignedAt': createdAt,
      'note': note,
      'isActive': 1,
      'createdAt': createdAt,
    });
  }

  static Future<void> _insertSeedProgressUpdateIfAbsent(
    Transaction transaction, {
    required int ticketId,
    required int staffId,
    required String message,
    required String createdAt,
  }) async {
    final rows = await transaction.query(
      progressUpdatesTable,
      columns: ['id'],
      where: 'ticketId = ? AND staffId = ? AND message = ?',
      whereArgs: [ticketId, staffId, message],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      return;
    }

    await transaction.insert(progressUpdatesTable, {
      'ticketId': ticketId,
      'staffId': staffId,
      'message': message,
      'createdAt': createdAt,
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
