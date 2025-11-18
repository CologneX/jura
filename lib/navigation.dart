import 'package:flutter/widgets.dart';
import 'package:jura/routes.dart';

/// Global navigator key for programmatic navigation from outside widgets
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Navigation service class for app-wide navigation operations
class NavigationService {
  /// Get the current navigator state
  static NavigatorState? get _navigator => navigatorKey.currentState;

  /// Check if navigator is available
  static bool get isNavigatorReady => _navigator != null;

  /// Push a named route onto the navigator
  static Future<dynamic>? pushNamed(String routeName, {Object? arguments}) {
    return _navigator?.pushNamed(routeName, arguments: arguments);
  }

  /// Push a replacement named route
  static Future<dynamic>? pushReplacementNamed(
    String routeName, {
    Object? arguments,
    Object? result,
  }) {
    return _navigator?.pushReplacementNamed(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  /// Pop the current route
  static void pop<T extends Object?>({T? result}) {
    _navigator?.pop(result);
  }

  /// Pop until a specific route
  static void popUntil(String routeName) {
    _navigator?.popUntil(ModalRoute.withName(routeName));
  }

  /// Navigate to home and clear the stack
  static Future<dynamic>? navigateToHome() {
    return _navigator?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Navigate to login and clear the stack
  static Future<dynamic>? navigateToLogin() {
    return _navigator?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  /// Navigate to register
  static Future<dynamic>? navigateToRegister() {
    return pushNamed(AppRoutes.register);
  }

  /// Check if the navigator can pop
  static bool canPop() => _navigator?.canPop() ?? false;

  /// Get the current route name
  static String? getCurrentRouteName() {
    String? routeName;
    _navigator?.popUntil((route) {
      routeName = route.settings.name;
      return true;
    });
    return routeName;
  }
}
