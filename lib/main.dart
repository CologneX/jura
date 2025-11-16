import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jura/home_page.dart';
import 'package:jura/login_page.dart';
import 'package:jura/register_page.dart';
import 'package:jura/services/auth_service.dart';
import 'package:jura/state/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ThemeData? externalTheme;
  try {
    final raw = await rootBundle.loadString('theme.json');
    final Map<String, dynamic> map = json.decode(raw) as Map<String, dynamic>;
    externalTheme = _themeDataFromJson(map);
  } catch (e) {
    print('Failed to load theme.json: $e');
  }

  runApp(MyApp(theme: externalTheme));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.theme});

  final ThemeData? theme;

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
    return MaterialApp(
      title: 'Jura',
      debugShowCheckedModeBanner: false,
      theme: widget.theme ?? ThemeData(useMaterial3: true),
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
              return _authState.isAuthenticated ? const HomePage() : const LoginPage();
            },
          );
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

ThemeData _themeDataFromJson(Map<String, dynamic> json) {
  Color parseColor(String? hex, [Color fallback = Colors.deepPurple]) {
    if (hex == null) return fallback;
    final h = hex.replaceFirst('#', '');
    final withAlpha = (h.length == 6) ? 'ff$h' : h;
    return Color(int.parse(withAlpha, radix: 16));
  }

  final cs = json['colorScheme'] as Map<String, dynamic>?;
  final primary = parseColor(cs?['primary'] as String?, Colors.deepPurple);
  final brightnessStr = (json['brightness'] as String?)?.toLowerCase();
  final brightness = brightnessStr == 'dark'
      ? Brightness.dark
      : Brightness.light;

  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: brightness,
  );

  return ThemeData.from(colorScheme: colorScheme).copyWith(
    scaffoldBackgroundColor: json['scaffoldBackgroundColor'] != null
        ? parseColor(json['scaffoldBackgroundColor'] as String)
        : null,
  );
}
