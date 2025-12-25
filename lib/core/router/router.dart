import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/core/services/auth_service.dart';
import 'package:jura/features/chat/chat_view.dart';
import 'package:jura/features/login/login_view.dart';
import 'package:jura/features/journal/journal_view.dart';
import 'package:jura/features/register/register_view.dart';
import 'package:jura/features/profile/profile_view.dart';
import 'package:jura/core/widgets/footer.dart';
import 'package:jura/core/router/navigator_key.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

final authService = GetIt.I<AuthService>();

final router = GoRouter(
  refreshListenable: authService,
  navigatorKey: rootNavigatorKey,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          footers: [
            Divider(),
            Footer(navigationShell: navigationShell),
          ],
          child: navigationShell,
        );
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'journal',
              path: '/journal',
              builder: (context, state) => const JournalView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'ai_page',
              path: '/',
              builder: (context, state) => const ChatView(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'profile',
              path: '/profile',
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      name: 'login',
      path: '/login',
      builder: (context, state) =>
          LoginView(prefillUsername: state.extra as String?),
    ),
    GoRoute(
      name: 'register',
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/splash',
      builder: (context, state) =>
          const Scaffold(child: Center(child: CircularProgressIndicator())),
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
