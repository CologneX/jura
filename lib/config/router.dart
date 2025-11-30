import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/pages/ai_page.dart';
import 'package:jura/pages/login_page.dart';
import 'package:jura/pages/login_username_page.dart';
import 'package:jura/pages/navigation_wrapper.dart';
import 'package:jura/pages/register_page.dart';
import 'package:jura/pages/register_username_page.dart';
import 'package:jura/pages/settings_page.dart';
import 'package:jura/pages/journal_page.dart';
import 'package:jura/services/auth_service.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final authService = GetIt.I<AuthService>();

// GoRouter createRouter() {
final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  refreshListenable: authService,
  navigatorKey: _rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return BottomNavigationWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'journal',
              path: '/journal',
              builder: (context, state) => JournalPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'ai_page',
              path: '/',
              builder: (context, state) => AIPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'profile',
              path: '/profile',
              builder: (context, state) => SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      name: 'login',
      path: '/login',
      builder: (context, state) =>
          LoginUsernamePage(prefillUsername: state.extra as String?),
      routes: [
        GoRoute(
          name: 'login-pin',
          path: 'pin',
          builder: (context, state) {
            final username = state.extra as String? ?? '';
            return LoginPage(username: username);
          },
        ),
      ],
    ),
    GoRoute(
      name: 'register',
      path: '/register',
      builder: (context, state) => RegisterUsernamePage(),
      routes: [
        GoRoute(
          name: 'register-pin',
          path: 'pin',
          builder: (context, state) {
            final username = state.extra as String? ?? '';
            return RegisterPage(username: username);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
  ],

  redirect: (BuildContext context, GoRouterState state) {
    final status = authService.status;
    final isLoggingIn = state.uri.toString().startsWith('/login');
    final isRegistering = state.uri.toString().startsWith('/register');
    final isPublicRoute = isLoggingIn || isRegistering;

    // Case A: App is still checking tokens
    if (status == AuthStatus.initial) {
      return '/splash';
    }

    // Case B: User is NOT authenticated
    if (status == AuthStatus.unauthenticated) {
      // If they are trying to reach a protected page, send to login
      if (!isPublicRoute) return '/login';
      // If they are on the Splash screen, move to login
      if (state.uri.toString() == '/splash') return '/login';
    }

    // Case C: User IS authenticated
    if (status == AuthStatus.authenticated) {
      // If they are on a public page (Login/Register/Splash), send Home
      if (isPublicRoute || state.uri.toString() == '/splash') {
        return '/';
      }
    }
    return null;
  },
);
// }
