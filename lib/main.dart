import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:jura/config/api_config.dart';
import 'package:jura/home_page.dart';
import 'package:jura/login_page.dart';
import 'package:jura/navigation.dart';
import 'package:jura/routes.dart';
import 'package:jura/services/auth_service.dart';
import 'package:jura/state/auth_state.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jura/utils/theme.dart';
import 'package:jura/utils/util.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  // Initialize API configuration
  ApiConfig.initialize();
  // Initialize Gemini API
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  if (apiKey.isNotEmpty) {
    Gemini.init(apiKey: apiKey);
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AuthState _authState;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _authState = AuthState(AuthService());
    _initFuture = _authState.initializeAuth();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Rubik", "Poppins");
    MaterialTheme theme = MaterialTheme(textTheme);

    // auth 
    log('Auth State: isAuthenticated=${_authState.isAuthenticated}');
    return MaterialApp(
      title: 'Jura',
      debugShowCheckedModeBanner: false,
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      navigatorKey: navigatorKey,
      home: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return ListenableBuilder(
            listenable: _authState,
            builder: (context, child) {
              return _authState.isAuthenticated
                  ? const HomePage()
                  : const LoginPage();
            },
          );
        },
      ),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
