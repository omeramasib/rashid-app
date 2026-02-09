import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../../core/storage/secure_storage_service.dart';
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
  // Bloc
  sl.registerFactory(
    () => LoginCubit(
      loginUseCase: sl(),
      secureStorageService: sl(),
    ),
  );
  sl.registerFactory(
    () => RegisterCubit(
      registerUseCase: sl(),
      secureStorageService: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );

  //! Core
  // Storage
  sl.registerLazySingleton(() => SecureStorageService());

  // Keep existing utils if needed for other features
  sl.registerLazySingleton(() => ApiEndpoints());
  sl.registerLazySingleton(() => ApiProvider());

  //! External
  sl.registerLazySingleton(() => http.Client());
}
