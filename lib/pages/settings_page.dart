import 'package:flutter/material.dart';
import 'package:jura/services/auth_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  // initialize auth service
  // AuthService _authService = AuthService();
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ShadButton(
          onPressed: () => _authService.logout(),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
