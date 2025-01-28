import 'package:get_it/get_it.dart';

import 'api_provider.dart';
import 'api_endpoints.dart';

final locator = GetIt.instance;

void setUpLocator() {
  locator.registerLazySingleton<ApiEndpoints>(() => ApiEndpoints());
  locator.registerLazySingleton<ApiProvider>(() => ApiProvider());
}