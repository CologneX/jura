import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jura/config/router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter();
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      themeMode: ThemeMode.system,
      darkTheme: ShadThemeData(
        colorScheme: const ShadVioletColorScheme.dark(),
        textTheme: ShadTextTheme(
          h1Large: GoogleFonts.rubik(),
          h1: GoogleFonts.rubik(),
          h2: GoogleFonts.rubik(),
          h3: GoogleFonts.rubik(),
          h4: GoogleFonts.rubik(),
          family: GoogleFonts.poppins().fontFamily,
        ),
      ),
      theme: ShadThemeData(
        colorScheme: const ShadVioletColorScheme.light(),
        textTheme: ShadTextTheme(
          h1Large: GoogleFonts.rubik(),
          h1: GoogleFonts.rubik(),
          h2: GoogleFonts.rubik(),
          h3: GoogleFonts.rubik(),
          h4: GoogleFonts.rubik(),
          family: GoogleFonts.poppins().fontFamily,
        ),
      ),
      appBuilder: (context) {
        return MaterialApp.router(
          theme: Theme.of(context),
          debugShowCheckedModeBanner: false,
          routerConfig: _router,
          builder: (context, child) {
            return ShadAppBuilder(child: child);
          },
        );
      },
    );
  }
}
