import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
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

  // Use cases - Login
  sl.registerLazySingleton(() => LoginWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => LoginWithLinkedInUseCase(sl()));

  // Use cases - Register
  sl.registerLazySingleton(() => RegisterWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => RegisterWithLinkedInUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
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

  // Keep existing utils if needed for other features
  sl.registerLazySingleton(() => ApiEndpoints());
  sl.registerLazySingleton(() => ApiProvider());

  //! External
  sl.registerLazySingleton(() => http.Client());
}
