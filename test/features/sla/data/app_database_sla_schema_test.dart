import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/database/app_database.dart';
import 'package:path/path.dart' as path_util;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late String databasePath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppDatabase.close();
    databasePath = path_util.join(
      await databaseFactory.getDatabasesPath(),
      AppDatabase.databaseName,
    );
    await databaseFactory.deleteDatabase(databasePath);
  });

  tearDown(() async {
    await AppDatabase.close();
    await databaseFactory.deleteDatabase(databasePath);
  });

  test(
    'fresh version 14 schema contains SLA columns, events, and defaults',
    () async {
      final database = await AppDatabase.instance;

      expect(AppDatabase.databaseVersion, 14);
      final ticketColumns = await _columnNames(
        database,
        AppDatabase.ticketsTable,
      );
      expect(
        ticketColumns,
        containsAll([
          'firstRespondedAt',
          'responseDueAt',
          'resolutionDueAt',
          'slaCompletedAt',
          'slaBreachedAt',
          'slaExceptionReason',
          'slaExceptionApprovedBy',
        ]),
      );
      expect(
        await _columnNames(database, AppDatabase.prioritiesTable),
        contains('responseSlaHours'),
      );
      final tables = await AppDatabase.tableNames;
      expect(tables, contains(AppDatabase.slaEventsTable));

      final priorities = await database.query(
        AppDatabase.prioritiesTable,
        columns: ['name', 'responseSlaHours', 'slaHours'],
        orderBy: 'level DESC',
      );
      expect(
        priorities,
        contains(
          predicate<Map<String, Object?>>(
            (row) =>
                row['name'] == 'Critical' &&
                row['responseSlaHours'] == 1 &&
                row['slaHours'] == 4,
          ),
        ),
      );
      expect(
        priorities,
        contains(
          predicate<Map<String, Object?>>(
            (row) =>
                row['name'] == 'High' &&
                row['responseSlaHours'] == 4 &&
                row['slaHours'] == 24,
          ),
        ),
      );
      expect(
        priorities,
        contains(
          predicate<Map<String, Object?>>(
            (row) =>
                row['name'] == 'Medium' &&
                row['responseSlaHours'] == 8 &&
                row['slaHours'] == 48,
          ),
        ),
      );
      expect(
        priorities,
        contains(
          predicate<Map<String, Object?>>(
            (row) =>
                row['name'] == 'Low' &&
                row['responseSlaHours'] == 24 &&
                row['slaHours'] == 72,
          ),
        ),
      );

      final seededTickets = await database.query(
        AppDatabase.ticketsTable,
        where: "title LIKE '[Seed]%'",
      );
      expect(seededTickets, isNotEmpty);
      for (final ticket in seededTickets) {
        expect(ticket['responseDueAt'], isNotNull);
        expect(ticket['resolutionDueAt'], isNotNull);
        expect(ticket['firstRespondedAt'], isNotNull);
      }
    },
  );

  test(
    'version 12 migration backfills SLA deadlines and terminal data',
    () async {
      final legacyDatabase = await databaseFactory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: 12,
          onCreate: (database, _) async {
            await database.execute(_legacyPrioritiesSql);
            await database.execute(_legacyTicketsSql);
            final createdAt = DateTime(2026, 7, 20, 8);
            await database.insert(AppDatabase.prioritiesTable, {
              'id': 1,
              'name': 'Medium',
              'level': 2,
              'slaHours': 48,
              'isActive': 1,
              'createdAt': createdAt.toIso8601String(),
            });
            await database.insert(AppDatabase.ticketsTable, {
              'id': 1,
              'title': 'Legacy resolved ticket',
              'description': 'Created before SLA migration',
              'issueType': 'Software',
              'priority': 'Medium',
              'status': 'Resolved',
              'priorityId': 1,
              'resolvedAt': createdAt
                  .add(const Duration(hours: 4))
                  .toIso8601String(),
              'createdAt': createdAt.toIso8601String(),
            });
            await database.insert(AppDatabase.ticketsTable, {
              'id': 2,
              'title': 'Legacy cancelled ticket',
              'description': 'Cancelled before SLA migration',
              'issueType': 'Software',
              'priority': 'Medium',
              'status': 'Cancelled',
              'priorityId': 1,
              'createdAt': createdAt.toIso8601String(),
            });
          },
        ),
      );
      await legacyDatabase.close();

      final migrated = await AppDatabase.instance;
      final resolved = (await migrated.query(
        AppDatabase.ticketsTable,
        where: 'id = ?',
        whereArgs: [1],
      )).single;
      final cancelled = (await migrated.query(
        AppDatabase.ticketsTable,
        where: 'id = ?',
        whereArgs: [2],
      )).single;

      expect(
        resolved['responseDueAt'],
        DateTime(2026, 7, 20, 16).toIso8601String(),
      );
      expect(
        resolved['resolutionDueAt'],
        DateTime(2026, 7, 22, 8).toIso8601String(),
      );
      expect(resolved['slaCompletedAt'], resolved['resolvedAt']);
      expect(cancelled['slaExceptionReason'], 'Legacy cancelled ticket');
    },
  );
}

Future<Set<String>> _columnNames(Database database, String table) async {
  final rows = await database.rawQuery('PRAGMA table_info($table)');
  return rows.map((row) => row['name'] as String).toSet();
}

const _legacyPrioritiesSql =
    '''
  CREATE TABLE ${AppDatabase.prioritiesTable} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    level INTEGER NOT NULL,
    slaHours INTEGER,
    colorHex TEXT,
    isActive INTEGER NOT NULL DEFAULT 1,
    createdAt TEXT NOT NULL,
    updatedAt TEXT
  )
''';

const _legacyTicketsSql =
    '''
  CREATE TABLE ${AppDatabase.ticketsTable} (
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
    updatedAt TEXT
  )
''';
