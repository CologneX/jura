import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jura/core/widgets/toast.dart';
import 'package:jura/features/register/register_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'register_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _confirmPinFocusNode = FocusNode();
  late RegisterViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<RegisterViewModel>();
    _viewModel.addListener(_onStateChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    _usernameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _pinFocusNode.dispose();
    _confirmPinFocusNode.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;

    final state = _viewModel.state;

    switch (state) {
      case RegisterError():
        showAppToast(
          title: 'Registration Error',
          subtitle: state.message,
          type: ToastType.destructive,
        );
        break;
      case RegisterSuccess():
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/login', extra: state.username);
          }
        });
        break;
      case RegisterPinInput():
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _pinFocusNode.requestFocus();
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

  Widget _buildBody(BuildContext context, RegisterState state) {
    if (state is RegisterUsernameInput) {
      return RegisterUsernameWidget(
        usernameController: _usernameController,
        onContinue: () {
          _viewModel.submitUsername(_usernameController.text);
        },
        onNavigateToLogin: () => context.go('/login'),
      );
    }

    if (state is RegisterPinInput || state is RegisterLoading) {
      final isLoading = state is RegisterLoading;
      final username = state is RegisterPinInput
          ? state.username
          : _usernameController.text;

      return RegisterPinWidget(
        pinController: _pinController,
        confirmPinController: _confirmPinController,
        pinFocusNode: _pinFocusNode,
        confirmPinFocusNode: _confirmPinFocusNode,
        isLoading: isLoading,
        onRegister: () {
          _viewModel.submitPin(
            username,
            _pinController.text,
            _confirmPinController.text,
          );
        },
        onBackToUsername: () {
          _viewModel.backToUsername();
        },
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
