import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:jura/services/auth_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LoginPage extends StatefulWidget {
  final String username;
  const LoginPage({super.key, required this.username});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final _authService = GetIt.I<AuthService>();
  final _formKey = GlobalKey<ShadFormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService.init();
    // Focus PIN field after a short delay to ensure UI is updated
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _pinFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _goBackToUsername() {
    context.go('/login');
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    final pin = _pinController.text.trim();

    setState(() => _isLoading = true);
    try {
      await _authService.login(username: widget.username, passcode: pin);
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Login Failed'),
            description: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      ShadButton.link(
                        onPressed: _goBackToUsername,
                        leading: const Icon(Icons.arrow_back),
                        padding: EdgeInsets.zero,
                        child: const Text('Back to Username'),
                      ),
                      const SizedBox(height: 12),
                      _buildHeader(theme),
                      const SizedBox(height: 48),
                      ..._buildPinStep(theme),
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
          'Enter Your Passcode',
          style: theme.textTheme.h1,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your 6-character Passcode to sign in',
          style: theme.textTheme.muted,
        ),
      ],
    );
  }

  List<Widget> _buildPinStep(ShadThemeData theme) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.input),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: theme.colorScheme.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: theme.colorScheme.accent,
      ),
    );

    final widgets = <Widget>[
      _PinFormFieldWidget(
        pinController: _pinController,
        pinFocusNode: _pinFocusNode,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
      ),
      const SizedBox(height: 32),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sign In'),
          ),
        ],
      ),
    ];
    return widgets;
  }
}

class _PinFormFieldWidget extends StatelessWidget {
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final PinTheme defaultPinTheme;
  final PinTheme focusedPinTheme;
  final PinTheme submittedPinTheme;

  const _PinFormFieldWidget({
    required this.pinController,
    required this.pinFocusNode,
    required this.defaultPinTheme,
    required this.focusedPinTheme,
    required this.submittedPinTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ShadFormBuilderField<String>(
      id: 'pin',
      initialValue: pinController.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Passcode is required';
        }
        if (value.length != 6) {
          return 'Passcode must be exactly 6 characters';
        }
        return null;
      },
      onSaved: (value) {
        pinController.text = value ?? '';
      },
      builder: (field) {
        final theme = ShadTheme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passcode',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Pinput(
                controller: pinController,
                focusNode: pinFocusNode,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
                obscureText: true,
                obscuringCharacter: '●',
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    return TextEditingValue(
                      text: newValue.text.toUpperCase(),
                      selection: newValue.selection,
                    );
                  }),
                ],
                onCompleted: (value) {
                  field.didChange(value);
                },
                onChanged: (value) {
                  field.didChange(value);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
