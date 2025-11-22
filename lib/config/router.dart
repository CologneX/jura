import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/pages/home_page.dart';
import 'package:jura/pages/login_page.dart';
import 'package:jura/pages/register_page.dart';
import 'package:jura/pages/transactions_page.dart';
import 'package:jura/services/auth_service.dart';

GoRouter createRouter() {
  final authService = GetIt.I<AuthService>();
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: authService,

    routes: [
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        name: 'transactions',
        path: '/transactions',
        builder: (context, state) => const TransactionsPage(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
    ],

    redirect: (BuildContext context, GoRouterState state) {
      final status = authService.status;
      final isLoggingIn = state.uri.toString() == '/login';
      final isRegistering = state.uri.toString() == '/register';
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
}
