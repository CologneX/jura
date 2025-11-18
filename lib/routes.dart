import 'package:flutter/material.dart';
import 'package:jura/home_page.dart';
import 'package:jura/login_page.dart';
import 'package:jura/register_page.dart';
import 'package:jura/transactions_page.dart';

/// Route names as constants for type-safe navigation
class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String transactions = '/transactions';
  static const String splash = '/';

  /// List of all available routes
  static const List<String> all = [splash, login, register, home, transactions];
}

/// RouteGenerator for handling named route navigation
class RouteGenerator {
  /// Generate routes based on route name
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
          settings: settings,
        );
      case AppRoutes.login:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => LoginPage(prefillEmail: email),
          settings: settings,
        );
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );
      case AppRoutes.transactions:
        return MaterialPageRoute(
          builder: (_) => const TransactionsPage(),
          settings: settings,
        );
      default:
        return _errorRoute();
    }
  }

  /// Build error route for undefined routes
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Route not found')),
      ),
    );
  }
}
