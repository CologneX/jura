import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:jura/services/auth_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class RegisterPage extends StatefulWidget {
  final String username;
  const RegisterPage({super.key, required this.username});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();
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
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _goBackToUsername() {
    context.go('/register');
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        username: widget.username,
        passcode: _pinController.text.trim(),
      );
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Registration Successful'),
            description: const Text('You can now log in with your credentials'),
          ),
        );
        context.go('/login', extra: widget.username);
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Registration Failed'),
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
          'Create Your Passcode',
          style: theme.textTheme.h1,
        ),
        const SizedBox(height: 8),
        Text(
          'Create a 6-character passcode to secure your account',
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

    return [
      _PinFormFieldWidget(
        pinController: _pinController,
        confirmPinController: _confirmPinController,
        pinFocusNode: _pinFocusNode,
        confirmPinFocusNode: _confirmPinFocusNode,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
      ),
      const SizedBox(height: 32),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Account'),
          ),
        ],
      ),
    ];
  }
}

class _PinFormFieldWidget extends StatelessWidget {
  final TextEditingController pinController;
  final TextEditingController confirmPinController;
  final FocusNode pinFocusNode;
  final FocusNode confirmPinFocusNode;
  final PinTheme defaultPinTheme;
  final PinTheme focusedPinTheme;
  final PinTheme submittedPinTheme;

  const _PinFormFieldWidget({
    required this.pinController,
    required this.confirmPinController,
    required this.pinFocusNode,
    required this.confirmPinFocusNode,
    required this.defaultPinTheme,
    required this.focusedPinTheme,
    required this.submittedPinTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ShadFormBuilderField<String>(
      id: 'passcode',
      initialValue: pinController.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Passcode is required';
        }
        if (value.length != 6) {
          return 'Passcode must be exactly 6 characters';
        }
        if (value != confirmPinController.text) {
          return 'Passcodes do not match';
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
                  confirmPinFocusNode.requestFocus();
                },
                onChanged: (value) {
                  field.didChange(value);
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Alphanumeric uppercase only',
                style: theme.textTheme.muted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Confirm Passcode',
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Pinput(
                controller: confirmPinController,
                focusNode: confirmPinFocusNode,
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
                onChanged: (value) {
                  field.didChange(value);
                },
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  field.errorText ?? 'Invalid passcode',
                  style: theme.textTheme.muted.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
