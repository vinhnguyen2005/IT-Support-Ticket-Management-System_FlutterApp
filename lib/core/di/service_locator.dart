import 'package:sqflite/sqflite.dart';

import '../../features/tickets/data/datasources/i_ticket_local_data_source.dart';
import '../../features/tickets/data/datasources/ticket_local_data_source_impl.dart';
import '../database/app_database.dart';

class ServiceLocator {
  ServiceLocator._();

  static Future<Database> get database {
    return AppDatabase.instance;
  }

  static Future<ITicketLocalDataSource> get ticketLocalDataSource async {
    return TicketLocalDataSourceImpl(await database);
  }
}
