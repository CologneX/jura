import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class LoginUsernameWidget extends StatelessWidget {
  final TextEditingController usernameController;
  final VoidCallback onContinue;
  final VoidCallback onNavigateToRegister;

  const LoginUsernameWidget({
    super.key,
    required this.usernameController,
    required this.onContinue,
    required this.onNavigateToRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 48),
        TextField(
          controller: usernameController,
          placeholder: const Text('Enter your username'),
          onSubmitted: (_) => onContinue(),
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(onPressed: onContinue, child: const Text('Continue')),
          ],
        ),
        const SizedBox(height: 24),
        _buildSignUpLink(theme),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jura').h3,
        const SizedBox(height: 8),
        Text(
          'Sign in to your account to continue',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: "Don't have an account? ",
              style: TextStyle(color: theme.colorScheme.mutedForeground),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: onNavigateToRegister,
                child: Text(
                  'Sign up',
                  style: TextStyle(color: theme.colorScheme.primary),
                ).semiBold,
              ),
            ),
          ],
        ),
      ).small,
    );
  }
}

class LoginPinWidget extends StatelessWidget {
  final TextEditingController pinController;
  final FocusNode pinFocusNode;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onBackToUsername;

  const LoginPinWidget({
    super.key,
    required this.pinController,
    required this.pinFocusNode,
    required this.isLoading,
    required this.onLogin,
    required this.onBackToUsername,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          density: ButtonDensity.compact,
          onPressed: onBackToUsername,
          leading: const Icon(RadixIcons.arrowLeft, color: Colors.purple),
          child: const Text(
            'Back to Username',
            style: TextStyle(color: Colors.purple),
          ),
        ),
        const SizedBox(height: 12),
        _buildHeader(theme),
        const SizedBox(height: 48),
        _buildPinField(
          theme,
          defaultPinTheme,
          focusedPinTheme,
          submittedPinTheme,
        ),
        const SizedBox(height: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PrimaryButton(
              onPressed: isLoading ? null : onLogin,
              // enabled: pinController.length >= 6,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter Your Passcode', style: theme.typography.h3),
        const SizedBox(height: 8),
        Text(
          'Enter your 6-character Passcode to sign in',
          style: TextStyle(color: theme.colorScheme.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildPinField(
    ThemeData theme,
    PinTheme defaultPinTheme,
    PinTheme focusedPinTheme,
    PinTheme submittedPinTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Passcode',
          style: theme.typography.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Center(
          child: Pinput(
            closeKeyboardWhenCompleted: false,
            hapticFeedbackType: HapticFeedbackType.lightImpact,
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
          ),
        ),
      ],
    );
  }
}
