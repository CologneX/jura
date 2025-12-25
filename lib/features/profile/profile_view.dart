import 'package:get_it/get_it.dart';
import 'package:jura/features/profile/profile_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'profile_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<ProfileViewModel>();
    _viewModel.addListener(_onStateChanged);
    _viewModel.loadUser();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _viewModel.state;
    return Scaffold(
      headers: [
        AppBar(title: const Text('Your Profile').h3),
        const Divider(),
      ],
      child: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state) {
    if (state is ProfileLoaded || state is ProfileUpdating) {
      final user = state is ProfileLoaded
          ? state.user
          : (state as ProfileUpdating).user;

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserProfileCard(user: user),
            const SizedBox(height: 24),
            CurrencySelector(
              currentCurrency: user.primaryCurrency,
              onCurrencyChanged: (currency) {
                _viewModel.updateCurrency(currency);
              },
            ),
            const SizedBox(height: 24),
            LogoutButton(
              onLogout: () {
                _viewModel.logout();
              },
            ),
          ],
        ),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
