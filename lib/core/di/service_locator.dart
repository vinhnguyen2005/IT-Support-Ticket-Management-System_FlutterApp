import 'package:sqflite/sqflite.dart';

import '../../features/assignment/application/services/assignment_service_impl.dart';
import '../../features/attachments/application/services/attachment_service_impl.dart';
import '../../features/attachments/application/services/i_attachment_service.dart';
import '../../features/attachments/data/datasources/attachment_local_data_source_impl.dart';
import '../../features/attachments/data/datasources/i_attachment_local_data_source.dart';
import '../../features/attachments/data/mappers/attachment_mapper.dart';
import '../../features/attachments/data/repositories/attachment_repository_impl.dart';
import '../../features/attachments/domain/repositories/i_attachment_repository.dart';
import '../../features/attachments/presentation/viewmodels/attachment_view_model.dart';
import '../../features/comments/application/services/comment_service_impl.dart';
import '../../features/comments/application/services/i_comment_service.dart';
import '../../features/comments/data/datasources/comment_local_data_source_impl.dart';
import '../../features/comments/data/datasources/i_comment_local_data_source.dart';
import '../../features/comments/data/mappers/comment_mapper.dart';
import '../../features/comments/data/repositories/comment_repository_impl.dart';
import '../../features/comments/domain/repositories/i_comment_repository.dart';
import '../../features/comments/presentation/viewmodels/comment_view_model.dart';
import '../../features/feedback/application/services/feedback_service_impl.dart';
import '../../features/feedback/application/services/i_feedback_service.dart';
import '../../features/feedback/data/datasources/feedback_local_data_source_impl.dart';
import '../../features/feedback/data/datasources/i_feedback_local_data_source.dart';
import '../../features/feedback/data/mappers/feedback_mapper.dart';
import '../../features/feedback/data/repositories/feedback_repository_impl.dart';
import '../../features/feedback/domain/repositories/i_feedback_repository.dart';
import '../../features/feedback/presentation/viewmodels/feedback_view_model.dart';
import '../../features/assignment/application/services/i_assignment_service.dart';
import '../../features/assignment/data/datasources/assignment_local_data_source_impl.dart';
import '../../features/assignment/data/datasources/i_assignment_local_data_source.dart';
import '../../features/assignment/data/mappers/assignment_mapper.dart';
import '../../features/assignment/data/mappers/progress_update_mapper.dart';
import '../../features/assignment/data/repositories/assignment_repository_impl.dart';
import '../../features/assignment/domain/repositories/i_assignment_repository.dart';
import '../../features/auth/application/services/auth_service_impl.dart';
import '../../features/auth/application/services/i_auth_service.dart';
import '../../features/auth/data/datasources/auth_local_data_source_impl.dart';
import '../../features/auth/data/datasources/i_auth_local_data_source.dart';
import '../../features/auth/data/mappers/user_mapper.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/i_auth_repository.dart';
import '../../features/auth/presentation/viewmodels/login_view_model.dart';
import '../../features/tickets/application/services/i_ticket_service.dart';
import '../../features/tickets/application/services/ticket_service_impl.dart';
import '../../features/tickets/data/datasources/i_ticket_local_data_source.dart';
import '../../features/tickets/data/datasources/ticket_local_data_source_impl.dart';
import '../../features/tickets/data/mappers/ticket_mapper.dart';
import '../../features/tickets/data/repositories/ticket_repository_impl.dart';
import '../../features/tickets/domain/repositories/i_ticket_repository.dart';
import '../../features/user_management/application/services/i_user_management_service.dart';
import '../../features/user_management/application/services/user_management_service_impl.dart';
import '../../features/user_management/data/datasources/i_user_local_data_source.dart';
import '../../features/user_management/data/datasources/user_local_data_source_impl.dart';
import '../../features/user_management/data/mappers/user_mapper.dart';
import '../../features/user_management/data/repositories/user_management_repository_impl.dart';
import '../../features/user_management/domain/repositories/i_user_management_repository.dart';
import '../../features/user_management/presentation/viewmodels/create_user_view_model.dart';
import '../../features/user_management/presentation/viewmodels/update_user_view_model.dart';
import '../../features/user_management/presentation/viewmodels/user_list_view_model.dart';
import '../database/app_database.dart';

class ServiceLocator {
  ServiceLocator._();

  static ITicketLocalDataSource? _ticketLocalDataSource;
  static IAssignmentLocalDataSource? _assignmentLocalDataSource;
  static IAssignmentRepository? _assignmentRepository;
  static IAssignmentService? _assignmentService;
  static ITicketRepository? _ticketRepository;
  static ITicketService? _ticketService;
  static IAuthLocalDataSource? _authLocalDataSource;
  static IAuthRepository? _authRepository;
  static IAuthService? _authService;
  static LoginViewModel? _loginViewModel;
  static IUserLocalDataSource? _userLocalDataSource;
  static IUserManagementRepository? _userManagementRepository;
  static IUserManagementService? _userManagementService;
  static IFeedbackLocalDataSource? _feedbackLocalDataSource;
  static IFeedbackRepository? _feedbackRepository;
  static IFeedbackService? _feedbackService;
  static ICommentLocalDataSource? _commentLocalDataSource;
  static ICommentRepository? _commentRepository;
  static ICommentService? _commentService;
  static IAttachmentLocalDataSource? _attachmentLocalDataSource;
  static IAttachmentRepository? _attachmentRepository;
  static IAttachmentService? _attachmentService;

  static Future<Database> get database {
    return AppDatabase.instance;
  }

  static Future<ITicketLocalDataSource> get ticketLocalDataSource async {
    return _ticketLocalDataSource ??= TicketLocalDataSourceImpl(await database);
  }

  static Future<IAssignmentLocalDataSource>
  get assignmentLocalDataSource async {
    return _assignmentLocalDataSource ??= AssignmentLocalDataSourceImpl(
      await database,
    );
  }

  static Future<IAssignmentRepository> get assignmentRepository async {
    return _assignmentRepository ??= AssignmentRepositoryImpl(
      localDataSource: await assignmentLocalDataSource,
      assignmentMapper: const AssignmentMapper(),
      progressUpdateMapper: const ProgressUpdateMapper(),
    );
  }

  static Future<IAssignmentService> get assignmentService async {
    return _assignmentService ??= AssignmentServiceImpl(
      await assignmentRepository,
    );
  }

  static Future<ITicketRepository> get ticketRepository async {
    return _ticketRepository ??= TicketRepositoryImpl(
      localDataSource: await ticketLocalDataSource,
      mapper: const TicketMapper(),
    );
  }

  static Future<ITicketService> get ticketService async {
    return _ticketService ??= TicketServiceImpl(await ticketRepository);
  }

  static Future<IAuthLocalDataSource> get authLocalDataSource async {
    return _authLocalDataSource ??= AuthLocalDataSourceImpl(await database);
  }

  static Future<IAuthRepository> get authRepository async {
    return _authRepository ??= AuthRepositoryImpl(
      localDataSource: await authLocalDataSource,
      userMapper: const UserMapper(),
    );
  }

  static Future<IAuthService> get authService async {
    return _authService ??= AuthServiceImpl(await authRepository);
  }

  static Future<LoginViewModel> get loginViewModel async {
    return _loginViewModel ??= LoginViewModel(await authService);
  }

  static Future<IUserLocalDataSource> get userLocalDataSource async {
    return _userLocalDataSource ??= UserLocalDataSourceImpl(await database);
  }

  static Future<IUserManagementRepository> get userManagementRepository async {
    return _userManagementRepository ??= UserManagementRepositoryImpl(
      localDataSource: await userLocalDataSource,
      mapper: const UserManagementMapper(),
    );
  }

  static Future<IUserManagementService> get userManagementService async {
    return _userManagementService ??= UserManagementServiceImpl(
      await userManagementRepository,
    );
  }

  static Future<UserListViewModel> get userListViewModel async {
    return UserListViewModel(await userManagementService);
  }

  static Future<CreateUserViewModel> get createUserViewModel async {
    return CreateUserViewModel(await userManagementService);
  }

  static Future<UpdateUserViewModel> get updateUserViewModel async {
    return UpdateUserViewModel(await userManagementService);
  }

  static Future<IFeedbackLocalDataSource> get feedbackLocalDataSource async {
    return _feedbackLocalDataSource ??= FeedbackLocalDataSourceImpl(await database);
  }

  static Future<IFeedbackRepository> get feedbackRepository async {
    return _feedbackRepository ??= FeedbackRepositoryImpl(
      localDataSource: await feedbackLocalDataSource,
      mapper: const FeedbackMapper(),
    );
  }

  static Future<IFeedbackService> get feedbackService async {
    return _feedbackService ??= FeedbackServiceImpl(await feedbackRepository);
  }

  static Future<FeedbackViewModel> feedbackViewModelFactory() async {
    return FeedbackViewModel(await feedbackService);
  }

  static Future<ICommentLocalDataSource> get commentLocalDataSource async {
    return _commentLocalDataSource ??= CommentLocalDataSourceImpl(await database);
  }

  static Future<ICommentRepository> get commentRepository async {
    return _commentRepository ??= CommentRepositoryImpl(
      localDataSource: await commentLocalDataSource,
      mapper: const CommentMapper(),
    );
  }

  static Future<ICommentService> get commentService async {
    return _commentService ??= CommentServiceImpl(await commentRepository);
  }

  static Future<CommentViewModel> commentViewModelFactory() async {
    return CommentViewModel(await commentService);
  }

  static Future<IAttachmentLocalDataSource> get attachmentLocalDataSource async {
    return _attachmentLocalDataSource ??= AttachmentLocalDataSourceImpl(await database);
  }

  static Future<IAttachmentRepository> get attachmentRepository async {
    return _attachmentRepository ??= AttachmentRepositoryImpl(
      localDataSource: await attachmentLocalDataSource,
      mapper: const AttachmentMapper(),
    );
  }

  static Future<IAttachmentService> get attachmentService async {
    return _attachmentService ??= AttachmentServiceImpl(await attachmentRepository);
  }

  static Future<AttachmentViewModel> attachmentViewModelFactory() async {
    return AttachmentViewModel(await attachmentService);
  }
}
