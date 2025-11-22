import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/config/router.dart';
import 'package:jura/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jura/services/protected_api.dart';
import 'package:jura/utils/theme.dart';
import 'package:jura/utils/util.dart';
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
  getIt.registerSingleton<ProtectedApiClient>(
    ProtectedApiClient(
      onSessionExpired: () {
        final authService = getIt<AuthService>();
        authService.logout();
      },
    ),
  );
  // RUN APP
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Rubik", "Poppins");
    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp.router(
      title: 'Jura',
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      routerConfig: _router,
    );
  }
}
