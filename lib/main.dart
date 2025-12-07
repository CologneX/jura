import 'package:flutter/material.dart';
import 'package:jura/app.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jura/services/protected_api.dart';
import 'package:jura/services/tab_navigation_service.dart';
import 'package:jura/services/user_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // load ENV
  await dotenv.load(fileName: ".env");
  // Initialize Configs
  ApiConfig.init();
  // Initialize singleton services
  getIt.registerSingleton<AuthService>(AuthService()..init());
  getIt.registerSingleton<UserService>(UserService()..init());
  getIt.registerSingleton<TabNavigationService>(TabNavigationService());
  getIt.registerSingleton<ProtectedApiClient>(ProtectedApiClient());
  // RUN APP
  runApp(App());
}
