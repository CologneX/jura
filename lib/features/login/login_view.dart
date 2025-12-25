import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/core/widgets/toast.dart';
import 'package:jura/features/login/login_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'login_viewmodel.dart';

class LoginView extends StatefulWidget {
  final String? prefillUsername;

  const LoginView({super.key, this.prefillUsername});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  late LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<LoginViewModel>();
    _viewModel.addListener(_onStateChanged);
    _viewModel.initialize(prefillUsername: widget.prefillUsername);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _usernameController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;

    final state = _viewModel.state;

    switch (state) {
      case LoginError():
        showAppToast(
          title: 'Login Error',
          subtitle: state.message,
          type: ToastType.destructive,
        );
        break;
      case LoginSuccess():
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go("/");
          }
        });
        break;
      default:
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = _viewModel.state;
    return Scaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBody(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LoginState state) {
    if (state is LoginUsernameInput) {
      return LoginUsernameWidget(
        usernameController: _usernameController,
        onContinue: () {
          _viewModel.submitUsername(_usernameController.text);
        },
        onNavigateToRegister: () => context.go('/register'),
      );
    }

    if (state is LoginPinInput || state is LoginLoading) {
      final isLoading = state is LoginLoading;
      final username = state is LoginPinInput
          ? state.username
          : _usernameController.text;

      return LoginPinWidget(
        pinController: _pinController,
        pinFocusNode: _pinFocusNode,
        isLoading: isLoading,
        onLogin: () {
          _viewModel.submitPin(username, _pinController.text);
        },
        onBackToUsername: () {
          _viewModel.backToUsername();
        },
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
