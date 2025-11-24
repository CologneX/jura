import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jura/services/auth_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  // get AuthService instance from GetIt
  final _authService = GetIt.I<AuthService>();
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
