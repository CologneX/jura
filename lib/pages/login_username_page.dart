import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/services/auth_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LoginUsernamePage extends StatefulWidget {
  final String? prefillUsername;
  const LoginUsernamePage({super.key, this.prefillUsername});

  @override
  State<LoginUsernamePage> createState() => _LoginUsernamePageState();
}

class _LoginUsernamePageState extends State<LoginUsernamePage> {
  final TextEditingController _usernameController = TextEditingController();
  final _authService = GetIt.I<AuthService>();
  final _formKey = GlobalKey<ShadFormState>();

  @override
  void initState() {
    super.initState();
    _authService.init();
    if (widget.prefillUsername != null) {
      _usernameController.text = widget.prefillUsername!;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _continueToPin() {
    if (_formKey.currentState!.saveAndValidate()) {
      final username = _usernameController.text.trim();
      context.go('/login/pin', extra: username);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authService,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ShadForm(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: 48),
                      ..._buildUsernameStep(theme),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jura',
          style: theme.textTheme.h1,
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue',
          style: theme.textTheme.muted,
        ),
      ],
    );
  }

  List<Widget> _buildUsernameStep(ShadThemeData theme) {
    return [
      ShadInputFormField(
        id: 'username',
        label: const Text('Username'),
        placeholder: const Text('Enter your username'),
        initialValue: _usernameController.text,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.person, size: 18),
        ),
        textInputAction: TextInputAction.next,
        autofocus: true,
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter your username';
          }
          return null;
        },
        onSaved: (value) {
          _usernameController.text = value ?? '';
        },
        onSubmitted: (_) => _continueToPin(),
      ),
      const SizedBox(height: 32),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadButton(onPressed: _continueToPin, child: const Text('Continue')),
        ],
      ),
      const SizedBox(height: 24),
      _buildSignUpLink(theme),
    ];
  }

  Widget _buildSignUpLink(ShadThemeData theme) {
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: theme.textTheme.muted,
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: ShadButton.link(
                textStyle: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  context.go('/register');
                },
                padding: EdgeInsets.zero,
                child: const Text('Sign up'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
