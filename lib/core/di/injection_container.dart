import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../auth/clerk_auth_service.dart';
import '../auth/clerk_config.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/presentation/cubit/login/login_cubit.dart';
import '../../features/auth/presentation/cubit/register/register_cubit.dart';
import '../../Presentation/utils/api_endpoints.dart';
import '../../Presentation/utils/api_provider.dart';
import '../../features/auth/domain/usecases/forgot_password_usecase.dart';
import '../../features/auth/domain/usecases/reset_password_usecase.dart';
import '../../features/auth/domain/usecases/change_password_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/cubit/profile/auth_profile_cubit.dart';
import '../../features/auth/presentation/cubit/password/password_cubit.dart';
import '../../features/linkedin/data/datasources/linkedin_remote_datasource.dart';
import '../../features/linkedin/data/repositories/linkedin_repository_impl.dart';
import '../../features/linkedin/domain/repositories/linkedin_repository.dart';
import '../../features/linkedin/domain/usecases/connect_linkedin_usecase.dart';
import '../../features/linkedin/domain/usecases/disconnect_linkedin_usecase.dart';
import '../../features/linkedin/presentation/cubit/linkedin_cubit.dart';
import '../../features/cv/data/datasources/cv_remote_datasource.dart';
import '../../features/cv/data/repositories/cv_repository_impl.dart';
import '../../features/cv/domain/repositories/cv_repository.dart';
import '../../features/cv/domain/usecases/analyze_cv_usecase.dart';
import '../../features/cv/domain/usecases/delete_skill_usecase.dart';
import '../../features/cv/domain/usecases/update_skills_usecase.dart';
import '../../features/cv/domain/usecases/upload_cv_usecase.dart';
import '../../features/cv/presentation/cubit/cv_cubit.dart';
import '../../features/simulation/data/datasources/interview_remote_datasource.dart';
import '../../features/simulation/data/repositories/interview_repository_impl.dart';
import '../../features/simulation/domain/repositories/interview_repository.dart';
import '../../features/simulation/domain/usecases/finish_interview_usecase.dart';
import '../../features/simulation/domain/usecases/get_interview_report_usecase.dart';
import '../../features/simulation/domain/usecases/get_simulations_history_usecase.dart';
import '../../features/simulation/domain/usecases/start_interview_by_job_description_usecase.dart';
import '../../features/simulation/domain/usecases/start_interview_by_job_usecase.dart';
import '../../features/simulation/domain/usecases/submit_answer_usecase.dart';
import '../../features/simulation/presentation/cubit/interview_cubit.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/share_interview_result_usecase.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  // Cubits
  sl.registerFactory(
    () => LoginCubit(
      loginWithEmailUseCase: sl(),
      loginWithLinkedInUseCase: sl(),
      registerWithLinkedInUseCase: sl(),
      clerkAuthService: sl(),
      secureStorageService: sl(),
    ),
  );
  sl.registerFactory(
    () => RegisterCubit(
      registerWithEmailUseCase: sl(),
      registerWithLinkedInUseCase: sl(),
      clerkAuthService: sl(),
      secureStorageService: sl(),
    ),
  );

  sl.registerFactory(
    () => AuthProfileCubit(
      getCurrentUserUseCase: sl(),
      changePasswordUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => PasswordCubit(
      forgotPasswordUseCase: sl(),
      resetPasswordUseCase: sl(),
    ),
  );
  // Use cases - Login
  sl.registerLazySingleton(() => LoginWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithLinkedInUseCase(sl()));

  // Use cases - Register
  sl.registerLazySingleton(() => RegisterWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => RegisterWithLinkedInUseCase(sl()));

  // Use cases - Auth Extras
  sl.registerLazySingleton(() => ForgotPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  //! Features - LinkedIn
  // Cubit
  sl.registerFactory(
    () => LinkedInCubit(
      connectLinkedInUseCase: sl(),
      disconnectLinkedInUseCase: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => ConnectLinkedInUseCase(sl()));
  sl.registerLazySingleton(() => DisconnectLinkedInUseCase(sl()));

  // Repository
  sl.registerLazySingleton<LinkedInRepository>(
    () => LinkedInRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<LinkedInRemoteDataSource>(
    () => LinkedInRemoteDataSourceImpl(client: sl()),
  );

  //! Features - CV
  // Cubit
  sl.registerFactory(
    () => CvCubit(
      uploadCvUseCase: sl(),
      analyzeCvUseCase: sl(),
      updateSkillsUseCase: sl(),
      deleteSkillUseCase: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => UploadCvUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeCvUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSkillsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSkillUseCase(sl()));

  // Repository
  sl.registerLazySingleton<CvRepository>(
    () => CvRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<CvRemoteDataSource>(
    () => CvRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Interview
  // Cubit
  sl.registerFactory(
    () => InterviewCubit(
      startInterviewByJobUseCase: sl(),
      startInterviewByJobDescriptionUseCase: sl(),
      submitAnswerUseCase: sl(),
      finishInterviewUseCase: sl(),
      getInterviewReportUseCase: sl(),
      getSimulationsHistoryUseCase: sl(),
    ),
  );

  // Usecases
  sl.registerLazySingleton(() => StartInterviewByJobUseCase(sl()));
  sl.registerLazySingleton(() => StartInterviewByJobDescriptionUseCase(sl()));
  sl.registerLazySingleton(() => SubmitAnswerUseCase(sl()));
  sl.registerLazySingleton(() => FinishInterviewUseCase(sl()));
  sl.registerLazySingleton(() => GetInterviewReportUseCase(sl()));
  sl.registerLazySingleton(() => GetSimulationsHistoryUseCase(sl()));

  // Repository
  sl.registerLazySingleton<InterviewRepository>(
    () => InterviewRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<InterviewRemoteDataSource>(
    () => InterviewRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Home
  // Cubit
  sl.registerFactory(
    () => HomeCubit(shareInterviewResultUseCase: sl()),
  );

  // Usecases
  sl.registerLazySingleton(() => ShareInterviewResultUseCase(sl()));

  // Repository
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(client: sl()),
  );

  //! Core
  // Clerk Auth Service
  sl.registerLazySingleton<ClerkAuthService>(
    () => ClerkConfig.isConfigured
        ? ClerkAuthServiceImpl()
        : MockClerkAuthService(),
  );

  // Storage
  sl.registerLazySingleton(() => SecureStorageService());

  // Network
  sl.registerLazySingleton(() => DioClient(storage: sl()));

  // Keep existing utils if needed for other features
  sl.registerLazySingleton(() => ApiEndpoints());
  sl.registerLazySingleton(() => ApiProvider());
}
