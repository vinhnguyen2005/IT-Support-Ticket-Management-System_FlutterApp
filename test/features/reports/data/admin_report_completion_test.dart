import 'package:flutter_test/flutter_test.dart';
import 'package:it_ticket_support_management/core/database/app_database.dart';
import 'package:it_ticket_support_management/core/enums/sla_status.dart';
import 'package:it_ticket_support_management/features/reports/data/datasources/report_local_data_source_impl.dart';
import 'package:it_ticket_support_management/features/reports/domain/entities/report_filter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database database;
  late ReportLocalDataSourceImpl dataSource;

  setUp(() async {
    database = await _openReportDatabase();
    dataSource = ReportLocalDataSourceImpl(database: database);
    await _seedReferences(database);
  });

  tearDown(() => database.close());

  test('totalActionable excludes cancelled and SLA-exempt tickets', () async {
    final now = DateTime.now();
    await _insertTicket(database, id: 1, createdAt: now);
    await _insertTicket(database, id: 2, status: 'Cancelled', createdAt: now);
    await _insertTicket(
      database,
      id: 3,
      createdAt: now,
      slaExceptionReason: 'Approved maintenance window',
    );

    final report = await dataSource.getSlaSummaryReport(_date(now), _date(now));

    expect(report.totalActionable, 1);
    expect(report.exempt, 2);
  });

  test(
    'processing and staff reports use resolvedAt and assignedAt dates',
    () async {
      final now = DateTime.now();
      await _insertTicket(
        database,
        id: 1,
        status: 'Resolved',
        createdAt: now.subtract(const Duration(days: 10)),
        resolvedAt: now,
        slaCompletedAt: now,
      );
      await database.insert(AppDatabase.ticketAssignmentsTable, {
        'id': 1,
        'ticketId': 1,
        'staffId': 2,
        'assignedAt': now.toIso8601String(),
        'createdAt': now.toIso8601String(),
      });

      final processing = await dataSource.getProcessingTimeReport(
        _date(now),
        _date(now),
      );
      final staff = await dataSource.getStaffPerformanceReport(
        _date(now),
        _date(now),
      );

      expect(processing, hasLength(1));
      expect(processing.single.completedTickets, 1);
      expect(processing.single.averageHours, closeTo(240, 0.1));
      expect(staff, hasLength(1));
      expect(staff.single.assignedTickets, 1);
      expect(staff.single.resolvedTickets, 1);
    },
  );

  test(
    'SLA attention and feedback honor admin filters and date range',
    () async {
      final now = DateTime.now();
      await _insertTicket(
        database,
        id: 1,
        title: 'Critical network outage',
        priority: 'High',
        status: 'Processing',
        createdAt: now.subtract(const Duration(days: 2)),
        resolutionDueAt: now.subtract(const Duration(hours: 1)),
      );
      await _insertTicket(
        database,
        id: 2,
        title: 'Normal request',
        priority: 'Low',
        status: 'Closed',
        categoryId: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        resolutionDueAt: now.add(const Duration(hours: 1)),
        closedAt: now,
      );
      await _insertTicket(
        database,
        id: 3,
        title: 'Closed network incident',
        priority: 'High',
        status: 'Closed',
        createdAt: now.subtract(const Duration(days: 3)),
        resolutionDueAt: now.subtract(const Duration(days: 1)),
        slaCompletedAt: now.subtract(const Duration(hours: 12)),
        closedAt: now,
      );
      await database.insert(AppDatabase.feedbackTable, {
        'id': 1,
        'ticketId': 3,
        'userId': 1,
        'rating': 1,
        'comment': 'Too slow',
        'createdAt': now.subtract(const Duration(days: 10)).toIso8601String(),
      });
      await database.insert(AppDatabase.feedbackTable, {
        'id': 2,
        'ticketId': 2,
        'userId': 1,
        'rating': 5,
        'comment': 'Great',
        'createdAt': now.toIso8601String(),
      });

      const filter = ReportFilter(
        priority: 'High',
        categoryId: 1,
        staffId: 2,
        slaStatus: SlaStatus.breached,
      );
      final attention = await dataSource.getSlaAttentionReport(filter: filter);
      const feedbackFilter = ReportFilter(
        priority: 'High',
        categoryId: 1,
        staffId: 2,
      );
      final feedback = await dataSource.getFeedbackSummaryReport(
        _date(now),
        _date(now),
        filter: feedbackFilter,
      );
      final lowRatings = await dataSource.getLowRatingFeedbackReport(
        _date(now),
        _date(now),
        filter: feedbackFilter,
      );

      expect(attention.map((item) => item.ticketId), [1]);
      expect(feedback.closedTickets, 1);
      expect(feedback.totalFeedback, 1);
      expect(feedback.averageRating, 1);
      expect(feedback.lowRatingCount, 1);
      expect(lowRatings.map((item) => item.ticketId), [3]);
    },
  );
}

String _date(DateTime value) => value.toIso8601String().substring(0, 10);

Future<Database> _openReportDatabase() {
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE ${AppDatabase.usersTable} (
            id INTEGER PRIMARY KEY,
            fullName TEXT NOT NULL,
            username TEXT NOT NULL,
            role TEXT NOT NULL,
            departmentId INTEGER,
            isActive INTEGER NOT NULL DEFAULT 1,
            lastLoginAt TEXT
          )
        ''');
        await database.execute('''
          CREATE TABLE ${AppDatabase.categoriesTable} (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE ${AppDatabase.ticketsTable} (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            priority TEXT NOT NULL,
            status TEXT NOT NULL,
            createdByUserId INTEGER,
            assignedStaffId INTEGER,
            categoryId INTEGER,
            resolvedAt TEXT,
            closedAt TEXT,
            firstRespondedAt TEXT,
            responseDueAt TEXT,
            resolutionDueAt TEXT,
            slaCompletedAt TEXT,
            slaBreachedAt TEXT,
            slaExceptionReason TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE ${AppDatabase.ticketAssignmentsTable} (
            id INTEGER PRIMARY KEY,
            ticketId INTEGER NOT NULL,
            staffId INTEGER NOT NULL,
            assignedAt TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE ${AppDatabase.feedbackTable} (
            id INTEGER PRIMARY KEY,
            ticketId INTEGER NOT NULL UNIQUE,
            userId INTEGER NOT NULL,
            rating INTEGER NOT NULL,
            comment TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE ${AppDatabase.slaEventsTable} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticketId INTEGER NOT NULL,
            eventType TEXT NOT NULL,
            newDueAt TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    ),
  );
}

Future<void> _seedReferences(Database database) async {
  await database.insert(AppDatabase.usersTable, {
    'id': 1,
    'fullName': 'Alice User',
    'username': 'alice',
    'role': 'user',
  });
  await database.insert(AppDatabase.usersTable, {
    'id': 2,
    'fullName': 'Sam Staff',
    'username': 'sam',
    'role': 'staff',
  });
  await database.insert(AppDatabase.categoriesTable, {
    'id': 1,
    'name': 'Network',
  });
  await database.insert(AppDatabase.categoriesTable, {
    'id': 2,
    'name': 'Software',
  });
}

Future<void> _insertTicket(
  Database database, {
  required int id,
  String title = 'Test ticket',
  String priority = 'High',
  String status = 'Processing',
  int categoryId = 1,
  required DateTime createdAt,
  DateTime? resolvedAt,
  DateTime? closedAt,
  DateTime? resolutionDueAt,
  DateTime? slaCompletedAt,
  String? slaExceptionReason,
}) {
  return database.insert(AppDatabase.ticketsTable, {
    'id': id,
    'title': title,
    'priority': priority,
    'status': status,
    'createdByUserId': 1,
    'assignedStaffId': 2,
    'categoryId': categoryId,
    'resolvedAt': resolvedAt?.toIso8601String(),
    'closedAt': closedAt?.toIso8601String(),
    'resolutionDueAt':
        (resolutionDueAt ?? createdAt.add(const Duration(days: 5)))
            .toIso8601String(),
    'slaCompletedAt': slaCompletedAt?.toIso8601String(),
    'slaExceptionReason': slaExceptionReason,
    'createdAt': createdAt.toIso8601String(),
  });
}
