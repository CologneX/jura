import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:pinput/pinput.dart';
import 'package:jura/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? prefillUsername;
  const LoginPage({super.key, this.prefillUsername});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final _authService = GetIt.I<AuthService>();
  bool _isLoading = false;
  int _currentStep = 0; // 0: username, 1: Passcode


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
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _continueToPin() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter your username'),
      ).show(context);
      return;
    }
    setState(() => _currentStep = 1);
    // Focus Passcode field after a short delay to ensure UI is updated
    Future.delayed(const Duration(milliseconds: 100), () {
      _pinFocusNode.requestFocus();
    });
  }

  void _goBackToUsername() {
    setState(() => _currentStep = 0);
  }


  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final pin = _pinController.text.trim();

    if (pin.length != 6) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Passcode must be exactly 6 characters'),
      ).show(context);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.login(
        username: username,
        passcode: pin,
      );
    } catch (e) {
      if (mounted) {
        MotionToast.error(
          title: const Text('Login Failed'),
          description: Text(e.toString()),
        ).show(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentStep == 1
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBackToUsername,
              ),
              title: const Text('Enter Passcode'),
            )
          : null,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authService,
          builder: (context, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    if (_currentStep == 0) ..._buildUsernameStep(),
                    if (_currentStep == 1) ..._buildPinStep(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentStep == 0 ? 'Welcome Back' : 'Enter Your Passcode',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _currentStep == 0
              ? 'Sign in to your account to continue'
              : 'Enter your 6-character Passcode to sign in',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildUsernameStep() {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Username',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Enter your username',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textInputAction: TextInputAction.next,
            autofocus: true,
            onSubmitted: (_) => _continueToPin(),
          ),
        ],
      ),
      const SizedBox(height: 32),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _continueToPin,
            child: const Text('Continue'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _buildSignUpLink(),
    ];
  }

  List<Widget> _buildPinStep() {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ) ?? const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
      borderRadius: BorderRadius.circular(12),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
    );

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passcode',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Center(
            child: Pinput(
              controller: _pinController,
              focusNode: _pinFocusNode,
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
              onCompleted: (_) => _login(),
              validator: (value) {
                if (value == null || value.length != 6) {
                  return 'Passcode must be 6 characters';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Alphanumeric uppercase only',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
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
  }

  Widget _buildSignUpLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Don\'t have an account? ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Sign up',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.go('/register');
                },
            ),
          ],
        ),
      ),
    );
  }
}
