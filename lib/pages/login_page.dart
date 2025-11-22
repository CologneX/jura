import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:jura/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String? prefillEmail;
  const LoginPage({super.key, this.prefillEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = GetIt.I<AuthService>();
  bool _showPassword = false;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _authService.init();
    if (widget.prefillEmail != null) {
      _emailController.text = widget.prefillEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter your email'),
      ).show(context);
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter a valid email'),
      ).show(context);
      return;
    }

    if (_passwordController.text.isEmpty) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter your password'),
      ).show(context);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
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
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 32),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildSignUpLink(),
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
          'Welcome Back',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'your@email.com',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Column(
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
    );
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
