import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:jura/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0; // 0: name, 1: email, 2: password
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final _authService = GetIt.I<AuthService>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService.init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.isEmpty) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter your name'),
      ).show(context);
      return;
    }

    if (_currentStep == 1 && _emailController.text.isEmpty) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter your email'),
      ).show(context);
      return;
    }

    if (_currentStep == 1 && !_isValidEmail(_emailController.text)) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter a valid email'),
      ).show(context);
      return;
    }

    if (_currentStep == 2 && _passwordController.text.isEmpty) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Please enter a password'),
      ).show(context);
      return;
    }

    if (_currentStep == 2 && _passwordController.text.length < 6) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Password must be at least 6 characters'),
      ).show(context);
      return;
    }

    if (_currentStep == 2 &&
        _passwordController.text != _confirmPasswordController.text) {
      MotionToast.error(
        title: const Text('Validation Error'),
        description: const Text('Passwords do not match'),
      ).show(context);
      return;
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _register();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _register() async {
    // await _authState.register(
    //   name: _nameController.text,
    //   email: _emailController.text,
    //   password: _passwordController.text,
    // );
    setState(() => _isLoading = true);
    try {
      await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        MotionToast.success(
          title: const Text('Registration Successful'),
          description: const Text('You can now log in with your credentials'),
        ).show(context);
        context.goNamed("login", extra: {'email': _emailController.text});
      }
    } catch (e) {
      if (mounted) {
        MotionToast.error(
          title: const Text('Registration Failed'),
          description: Text(e.toString()),
        ).show(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    // if (mounted && _authState.isAuthenticated) {
    //   context.go('/login?email=${Uri.encodeComponent(_emailController.text)}');
    // } else if (mounted && _authState.hasError) {
    //   MotionToast.error(
    //     title: const Text('Registration Failed'),
    //     description: Text(_authState.error ?? 'Registration failed'),
    //   ).show(context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        automaticallyImplyLeading: _currentStep > 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
      ),
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
                    _buildProgressIndicator(),
                    const SizedBox(height: 32),
                    if (_currentStep == 0) _buildNameStep(),
                    if (_currentStep == 1) _buildEmailStep(),
                    if (_currentStep == 2) _buildPasswordStep(),
                    const SizedBox(height: 32),
                    _buildButtons(),
                    const SizedBox(height: 16),
                    _buildLoginLink(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${_currentStep + 1} of 3',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your name?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textInputAction: TextInputAction.next,
          autofocus: true,
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your email?',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Enter your email address',
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

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create a password',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            hintText: 'At least 6 characters',
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
          textInputAction: TextInputAction.next,
          autofocus: true,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            hintText: 'Confirm your password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          obscureText: !_showConfirmPassword,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_currentStep == 2 ? 'Create Account' : 'Next'),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(
              text: 'Sign in',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  context.go('/login');
                },
            ),
          ],
        ),
      ),
    );
  }
}
