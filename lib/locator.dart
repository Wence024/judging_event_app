import 'package:get_it/get_it.dart';
import 'services/auth_service.dart';
import 'services/event_service.dart';
import 'services/score_service.dart';
import 'services/user_service.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => EventService());
  locator.registerLazySingleton(() => ScoreService());
  locator.registerLazySingleton(() => UserService());
}
