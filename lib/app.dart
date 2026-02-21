import 'package:jura/core/router/router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      scrollBehavior: const ShadcnScrollBehavior(),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorSchemes.lightNeutral.violet,
        radius: 0.75,
        surfaceOpacity: 0.9,
        surfaceBlur: 8.0,
      ),
      routerConfig: router,
    );
  }
}
