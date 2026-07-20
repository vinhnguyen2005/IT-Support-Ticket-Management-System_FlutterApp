import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/database/app_database.dart';
import 'package:it_ticket_support_management/core/database/reference_data_service.dart';
import 'package:it_ticket_support_management/core/database/sla_persistence.dart';
import 'package:it_ticket_support_management/core/errors/exceptions.dart';
import 'package:it_ticket_support_management/features/assignment/data/datasources/assignment_local_data_source_impl.dart';
import 'package:it_ticket_support_management/features/reports/data/datasources/report_local_data_source_impl.dart';
import 'package:it_ticket_support_management/features/tickets/data/datasources/ticket_local_data_source_impl.dart';
import 'package:it_ticket_support_management/features/tickets/data/dtos/ticket_dto.dart';
import 'package:it_ticket_support_management/features/tickets/data/dtos/update_ticket_status_dto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database database;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    database = await _openSlaDatabase();
  });

  tearDown(() => database.close());

  group('ticket creation SLA', () {
    test(
      'happy case snapshots priority deadlines and creates Started event',
      () async {
        final source = TicketLocalDataSourceImpl(database);
        final createdAt = DateTime(2026, 7, 20, 8);

        final id = await source.insertTicket(
          TicketDto(
            title: 'Production outage',
            description: 'The payment system is unavailable.',
            priority: 'Critical',
            createdByUserId: 10,
            createdAt: createdAt,
          ),
        );

        final ticket = await _ticketRow(database, id);
        expect(ticket['priorityId'], 1);
        expect(
          ticket['responseDueAt'],
          createdAt.add(const Duration(hours: 1)).toIso8601String(),
        );
        expect(
          ticket['resolutionDueAt'],
          createdAt.add(const Duration(hours: 4)).toIso8601String(),
        );
        final events = await _events(database, id);
        expect(events, hasLength(1));
        expect(events.single['eventType'], 'Started');
        expect(events.single['newDueAt'], ticket['resolutionDueAt']);
      },
    );

    test('happy case preserves an explicitly snapshotted deadline', () async {
      final source = TicketLocalDataSourceImpl(database);
      final createdAt = DateTime(2026, 7, 20, 8);
      final responseDueAt = createdAt.add(const Duration(minutes: 30));
      final resolutionDueAt = createdAt.add(const Duration(hours: 2));

      final id = await source.insertTicket(
        TicketDto(
          title: 'Custom SLA',
          description: 'A ticket with snapshotted deadlines.',
          priority: 'Critical',
          createdAt: createdAt,
          responseDueAt: responseDueAt,
          resolutionDueAt: resolutionDueAt,
        ),
      );

      final ticket = await _ticketRow(database, id);
      expect(ticket['responseDueAt'], responseDueAt.toIso8601String());
      expect(ticket['resolutionDueAt'], resolutionDueAt.toIso8601String());
    });

    test('exception case rejects an unavailable priority', () async {
      final source = TicketLocalDataSourceImpl(database);

      expect(
        () => source.insertTicket(
          TicketDto(
            title: 'Unknown priority',
            description: 'Priority does not exist.',
            priority: 'Emergency',
            createdAt: DateTime(2026, 7, 20),
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('ticket status SLA completion', () {
    test('happy case resolves on time and records Completed', () async {
      final source = TicketLocalDataSourceImpl(database);
      final changedAt = DateTime(2026, 7, 20, 10);
      await _insertTicket(
        database,
        id: 20,
        status: 'Processing',
        resolutionDueAt: changedAt.add(const Duration(hours: 1)),
      );

      await source.updateTicketStatus(
        UpdateTicketStatusDto(
          ticketId: 20,
          oldStatus: 'Processing',
          newStatus: 'Resolved',
          solutionSummary: 'Restarted the gateway.',
          changedByUserId: 2,
          changedAt: changedAt,
        ),
      );

      final ticket = await _ticketRow(database, 20);
      expect(ticket['resolvedAt'], changedAt.toIso8601String());
      expect(ticket['slaCompletedAt'], changedAt.toIso8601String());
      expect(ticket['slaBreachedAt'], isNull);
      expect(ticket['solutionSummary'], 'Restarted the gateway.');
      expect((await _events(database, 20)).single['eventType'], 'Completed');
    });

    test('happy case resolves late and records BreachedResolved', () async {
      final source = TicketLocalDataSourceImpl(database);
      final changedAt = DateTime(2026, 7, 20, 10);
      await _insertTicket(
        database,
        id: 21,
        status: 'Processing',
        resolutionDueAt: changedAt.subtract(const Duration(minutes: 1)),
      );

      await source.updateTicketStatus(
        UpdateTicketStatusDto(
          ticketId: 21,
          oldStatus: 'Processing',
          newStatus: 'Resolved',
          solutionSummary: 'Replaced the router.',
          changedAt: changedAt,
        ),
      );

      final ticket = await _ticketRow(database, 21);
      expect(ticket['slaBreachedAt'], changedAt.toIso8601String());
      expect(
        (await _events(database, 21)).single['eventType'],
        'BreachedResolved',
      );
    });

    test('happy case cancels and records an SLA exemption', () async {
      final source = TicketLocalDataSourceImpl(database);
      final changedAt = DateTime(2026, 7, 20, 10);
      await _insertTicket(database, id: 22, status: 'Submitted');

      await source.updateTicketStatus(
        UpdateTicketStatusDto(
          ticketId: 22,
          oldStatus: 'Submitted',
          newStatus: 'Cancelled',
          note: 'Duplicate request',
          changedByUserId: 1,
          changedAt: changedAt,
        ),
      );

      final ticket = await _ticketRow(database, 22);
      expect(ticket['slaExceptionReason'], 'Duplicate request');
      expect(ticket['slaExceptionApprovedBy'], 1);
      expect((await _events(database, 22)).single['eventType'], 'Exempted');
    });

    test(
      'happy case closing does not overwrite resolution completion',
      () async {
        final source = TicketLocalDataSourceImpl(database);
        final resolvedAt = DateTime(2026, 7, 20, 9);
        final closedAt = DateTime(2026, 7, 20, 10);
        await _insertTicket(
          database,
          id: 23,
          status: 'Resolved',
          resolvedAt: resolvedAt,
          slaCompletedAt: resolvedAt,
        );

        await source.updateTicketStatus(
          UpdateTicketStatusDto(
            ticketId: 23,
            oldStatus: 'Resolved',
            newStatus: 'Closed',
            changedAt: closedAt,
          ),
        );

        final ticket = await _ticketRow(database, 23);
        expect(ticket['resolvedAt'], resolvedAt.toIso8601String());
        expect(ticket['slaCompletedAt'], resolvedAt.toIso8601String());
        expect(ticket['closedAt'], closedAt.toIso8601String());
        expect(await _events(database, 23), isEmpty);
      },
    );

    test(
      'exception case rejects unsupported status without partial writes',
      () async {
        final source = TicketLocalDataSourceImpl(database);
        await _insertTicket(database, id: 24, status: 'Processing');

        expect(
          () => source.updateTicketStatus(
            UpdateTicketStatusDto(ticketId: 24, newStatus: 'Waiting'),
          ),
          throwsA(isA<AppException>()),
        );
        expect((await _ticketRow(database, 24))['status'], 'Processing');
        expect(await _events(database, 24), isEmpty);
      },
    );

    test('exception case rejects a missing ticket', () {
      final source = TicketLocalDataSourceImpl(database);
      expect(
        () => source.updateTicketStatus(
          UpdateTicketStatusDto(ticketId: 999, newStatus: 'Resolved'),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('assignment response and resolution SLA', () {
    test('happy case first assignment records on-time response once', () async {
      final source = AssignmentLocalDataSourceImpl(database);
      await _insertTicket(
        database,
        id: 30,
        status: 'Submitted',
        responseDueAt: DateTime.now().add(const Duration(hours: 1)),
      );

      await source.assignTicket(
        ticketId: 30,
        staffId: 2,
        assignedByUserId: 1,
        note: 'Handle now',
      );

      final ticket = await _ticketRow(database, 30);
      expect(ticket['status'], 'Assigned');
      expect(ticket['firstRespondedAt'], isNotNull);
      final assignments = await database.query(
        AppDatabase.ticketAssignmentsTable,
        where: 'ticketId = ?',
        whereArgs: [30],
      );
      expect(assignments, hasLength(1));
      expect((await _events(database, 30)).single['eventType'], 'Responded');
    });

    test(
      'happy case late assignment records breach and response time',
      () async {
        final source = AssignmentLocalDataSourceImpl(database);
        await _insertTicket(
          database,
          id: 31,
          status: 'Submitted',
          responseDueAt: DateTime.now().subtract(const Duration(minutes: 1)),
        );

        await source.assignTicket(
          ticketId: 31,
          staffId: 2,
          assignedByUserId: 1,
        );

        expect(
          (await _events(database, 31)).map((event) => event['eventType']),
          ['ResponseBreached', 'RespondedLate'],
        );
      },
    );

    test(
      'exception case late assignment does not duplicate an existing breach event',
      () async {
        final source = AssignmentLocalDataSourceImpl(database);
        await _insertTicket(
          database,
          id: 36,
          status: 'Submitted',
          responseDueAt: DateTime.now().subtract(const Duration(minutes: 1)),
          resolutionDueAt: DateTime.now().add(const Duration(hours: 1)),
        );
        await SlaPersistence.refreshBreaches(database);

        await source.assignTicket(
          ticketId: 36,
          staffId: 2,
          assignedByUserId: 1,
        );

        final events = await _events(database, 36);
        expect(
          events.where((event) => event['eventType'] == 'ResponseBreached'),
          hasLength(1),
        );
        expect(
          events.where((event) => event['eventType'] == 'RespondedLate'),
          hasLength(1),
        );
      },
    );

    test(
      'happy case staff resolution writes resolvedAt rather than closedAt',
      () async {
        final source = AssignmentLocalDataSourceImpl(database);
        await _insertTicket(
          database,
          id: 32,
          status: 'Processing',
          assignedStaffId: 2,
          resolutionDueAt: DateTime.now().add(const Duration(hours: 1)),
        );
        await _insertAssignment(database, ticketId: 32, staffId: 2);

        await source.updateTicketStatus(
          ticketId: 32,
          staffId: 2,
          status: 'Resolved',
          solutionSummary: 'Fixed DNS settings.',
        );

        final ticket = await _ticketRow(database, 32);
        expect(ticket['resolvedAt'], isNotNull);
        expect(ticket['slaCompletedAt'], ticket['resolvedAt']);
        expect(ticket['closedAt'], isNull);
        expect((await _events(database, 32)).single['eventType'], 'Completed');
      },
    );

    test('exception case rejects assignment for inactive staff', () async {
      final source = AssignmentLocalDataSourceImpl(database);
      await _insertTicket(database, id: 33, status: 'Submitted');

      expect(
        () =>
            source.assignTicket(ticketId: 33, staffId: 3, assignedByUserId: 1),
        throwsA(isA<AppException>()),
      );
      expect((await _ticketRow(database, 33))['status'], 'Submitted');
    });

    test(
      'exception case only allows Submitted tickets to be assigned',
      () async {
        final source = AssignmentLocalDataSourceImpl(database);
        await _insertTicket(database, id: 34, status: 'Processing');

        expect(
          () => source.assignTicket(
            ticketId: 34,
            staffId: 2,
            assignedByUserId: 1,
          ),
          throwsA(isA<AppException>()),
        );
      },
    );

    test(
      'exception case rejects status update without active assignment',
      () async {
        final source = AssignmentLocalDataSourceImpl(database);
        await _insertTicket(database, id: 35, status: 'Processing');

        expect(
          () => source.updateTicketStatus(
            ticketId: 35,
            staffId: 2,
            status: 'Resolved',
            solutionSummary: 'Not allowed',
          ),
          throwsA(isA<AppException>()),
        );
      },
    );
  });

  group('automatic breach refresh', () {
    test(
      'marks only eligible overdue tickets and remains idempotent',
      () async {
        final now = DateTime.now();
        await _insertTicket(
          database,
          id: 40,
          resolutionDueAt: now.subtract(const Duration(hours: 1)),
          responseDueAt: now.subtract(const Duration(hours: 2)),
        );
        await _insertTicket(
          database,
          id: 41,
          resolutionDueAt: now.add(const Duration(hours: 1)),
          responseDueAt: now.add(const Duration(minutes: 30)),
        );
        await _insertTicket(
          database,
          id: 42,
          status: 'Cancelled',
          resolutionDueAt: now.subtract(const Duration(hours: 1)),
          responseDueAt: now.subtract(const Duration(hours: 1)),
        );
        await _insertTicket(
          database,
          id: 43,
          resolutionDueAt: now.subtract(const Duration(hours: 1)),
          slaExceptionReason: 'Approved exemption',
        );
        await _insertTicket(
          database,
          id: 44,
          status: 'Resolved',
          resolutionDueAt: now.subtract(const Duration(hours: 1)),
          slaCompletedAt: now.subtract(const Duration(hours: 2)),
        );

        await SlaPersistence.refreshBreaches(database);
        await SlaPersistence.refreshBreaches(database);

        expect((await _ticketRow(database, 40))['slaBreachedAt'], isNotNull);
        for (final id in [41, 42, 43, 44]) {
          expect((await _ticketRow(database, id))['slaBreachedAt'], isNull);
        }
        final events = await _events(database, 40);
        expect(
          events.where((event) => event['eventType'] == 'Breached'),
          hasLength(1),
        );
        expect(
          events.where((event) => event['eventType'] == 'ResponseBreached'),
          hasLength(1),
        );
      },
    );
  });

  group('SLA report summary', () {
    test(
      'counts completed, active breach, at-risk, and exempt tickets',
      () async {
        final now = DateTime.now();
        await _insertTicket(
          database,
          id: 50,
          createdAt: now.subtract(const Duration(hours: 2)),
          firstRespondedAt: now.subtract(const Duration(hours: 1)),
          responseDueAt: now,
          resolutionDueAt: now.add(const Duration(hours: 2)),
          slaCompletedAt: now,
          status: 'Resolved',
        );
        await _insertTicket(
          database,
          id: 51,
          createdAt: now.subtract(const Duration(hours: 5)),
          firstRespondedAt: now.subtract(const Duration(hours: 3)),
          responseDueAt: now.subtract(const Duration(hours: 4)),
          resolutionDueAt: now.subtract(const Duration(hours: 2)),
          slaCompletedAt: now.subtract(const Duration(hours: 1)),
          status: 'Resolved',
        );
        await _insertTicket(
          database,
          id: 52,
          createdAt: now.subtract(const Duration(hours: 3)),
          responseDueAt: now.add(const Duration(hours: 1)),
          resolutionDueAt: now.add(const Duration(hours: 1)),
        );
        await _insertTicket(
          database,
          id: 53,
          createdAt: now.subtract(const Duration(hours: 5)),
          responseDueAt: now.subtract(const Duration(hours: 3)),
          resolutionDueAt: now.subtract(const Duration(hours: 1)),
        );
        await _insertTicket(
          database,
          id: 54,
          createdAt: now.subtract(const Duration(hours: 1)),
          status: 'Cancelled',
          slaExceptionReason: 'Duplicate',
        );

        final report = await ReportLocalDataSourceImpl(database: database)
            .getSlaSummaryReport(
              _date(now.subtract(const Duration(days: 1))),
              _date(now.add(const Duration(days: 1))),
            );

        expect(report.totalActionable, 4);
        expect(report.responseMet, 1);
        expect(report.responseBreached, 2);
        expect(report.resolutionMet, 1);
        expect(report.resolutionBreached, 2);
        expect(report.currentlyAtRisk, 1);
        expect(report.currentlyBreached, 1);
        expect(report.exempt, 1);
      },
    );
  });

  group('priority SLA policy', () {
    test('happy case updates active policy', () async {
      final service = ReferenceDataService(database);

      await service.updatePrioritySla(
        priorityId: 2,
        responseHours: 6,
        resolutionHours: 36,
      );

      final rows = await database.query(
        AppDatabase.prioritiesTable,
        where: 'id = ?',
        whereArgs: [2],
      );
      expect(rows.single['responseSlaHours'], 6);
      expect(rows.single['slaHours'], 36);
      expect(rows.single['updatedAt'], isNotNull);
    });

    for (final values in const [(0, 8), (-1, 8), (9, 8)]) {
      test(
        'exception case rejects response=${values.$1}, resolution=${values.$2}',
        () {
          final service = ReferenceDataService(database);
          expect(
            () => service.updatePrioritySla(
              priorityId: 2,
              responseHours: values.$1,
              resolutionHours: values.$2,
            ),
            throwsArgumentError,
          );
        },
      );
    }

    test('exception case rejects missing or inactive policy', () {
      final service = ReferenceDataService(database);
      expect(
        () => service.updatePrioritySla(
          priorityId: 999,
          responseHours: 1,
          resolutionHours: 4,
        ),
        throwsArgumentError,
      );
    });
  });
}

Future<Database> _openSlaDatabase() async {
  final database = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE ${AppDatabase.prioritiesTable} (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            level INTEGER NOT NULL,
            slaHours INTEGER,
            responseSlaHours INTEGER,
            colorHex TEXT,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppDatabase.categoriesTable} (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            departmentId INTEGER,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppDatabase.usersTable} (
            id INTEGER PRIMARY KEY,
            fullName TEXT NOT NULL,
            role TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1
          )
        ''');
        await db.execute('''
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
            firstRespondedAt TEXT,
            responseDueAt TEXT,
            resolutionDueAt TEXT,
            slaCompletedAt TEXT,
            slaBreachedAt TEXT,
            slaExceptionReason TEXT,
            slaExceptionApprovedBy INTEGER,
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppDatabase.ticketAssignmentsTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            staffId INTEGER NOT NULL,
            assignedByUserId INTEGER,
            assignedAt TEXT NOT NULL,
            note TEXT,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppDatabase.progressUpdatesTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            staffId INTEGER NOT NULL,
            message TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppDatabase.ticketStatusHistoriesTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            changedByUserId INTEGER,
            fromStatus TEXT,
            toStatus TEXT NOT NULL,
            note TEXT,
            changedAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ${AppDatabase.slaEventsTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            eventType TEXT NOT NULL,
            oldDueAt TEXT,
            newDueAt TEXT,
            reason TEXT,
            createdByUserId INTEGER,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    ),
  );
  final createdAt = DateTime(2026, 1, 1).toIso8601String();
  await database.insert(AppDatabase.prioritiesTable, {
    'id': 1,
    'name': 'Critical',
    'level': 4,
    'slaHours': 4,
    'responseSlaHours': 1,
    'isActive': 1,
    'createdAt': createdAt,
  });
  await database.insert(AppDatabase.prioritiesTable, {
    'id': 2,
    'name': 'Medium',
    'level': 2,
    'slaHours': 48,
    'responseSlaHours': 8,
    'isActive': 1,
    'createdAt': createdAt,
  });
  await database.insert(AppDatabase.usersTable, {
    'id': 1,
    'fullName': 'Admin',
    'role': 'admin',
    'isActive': 1,
  });
  await database.insert(AppDatabase.usersTable, {
    'id': 2,
    'fullName': 'Active Staff',
    'role': 'staff',
    'isActive': 1,
  });
  await database.insert(AppDatabase.usersTable, {
    'id': 3,
    'fullName': 'Inactive Staff',
    'role': 'staff',
    'isActive': 0,
  });
  return database;
}

Future<void> _insertTicket(
  Database database, {
  required int id,
  String status = 'Submitted',
  DateTime? createdAt,
  DateTime? responseDueAt,
  DateTime? resolutionDueAt,
  DateTime? firstRespondedAt,
  DateTime? resolvedAt,
  DateTime? slaCompletedAt,
  String? slaExceptionReason,
  int? assignedStaffId,
}) {
  final created =
      createdAt ?? DateTime.now().subtract(const Duration(hours: 1));
  return database.insert(AppDatabase.ticketsTable, {
    'id': id,
    'title': 'Ticket $id',
    'description': 'SLA test ticket',
    'issueType': 'Software',
    'priority': 'Medium',
    'status': status,
    'createdAt': created.toIso8601String(),
    'responseDueAt': responseDueAt?.toIso8601String(),
    'resolutionDueAt': resolutionDueAt?.toIso8601String(),
    'firstRespondedAt': firstRespondedAt?.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
    'slaCompletedAt': slaCompletedAt?.toIso8601String(),
    'slaExceptionReason': slaExceptionReason,
    'assignedStaffId': assignedStaffId,
  });
}

Future<void> _insertAssignment(
  Database database, {
  required int ticketId,
  required int staffId,
}) {
  final now = DateTime.now().toIso8601String();
  return database.insert(AppDatabase.ticketAssignmentsTable, {
    'ticketId': ticketId,
    'staffId': staffId,
    'assignedAt': now,
    'isActive': 1,
    'createdAt': now,
  });
}

Future<Map<String, Object?>> _ticketRow(Database database, int id) async {
  final rows = await database.query(
    AppDatabase.ticketsTable,
    where: 'id = ?',
    whereArgs: [id],
  );
  return rows.single;
}

Future<List<Map<String, Object?>>> _events(Database database, int id) {
  return database.query(
    AppDatabase.slaEventsTable,
    where: 'ticketId = ?',
    whereArgs: [id],
    orderBy: 'id ASC',
  );
}

String _date(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
