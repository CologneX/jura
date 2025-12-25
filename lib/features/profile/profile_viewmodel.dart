import 'package:flutter/foundation.dart';
import 'package:jura/core/models/user.dart';
import 'package:jura/core/services/user_service.dart';
import 'package:jura/core/services/auth_service.dart';
import 'profile_service.dart';

/// Profile States
abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;

  const ProfileLoaded({required this.user});
}

class ProfileUpdating extends ProfileState {
  final User user;

  const ProfileUpdating({required this.user});
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});
}

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _service;
  final UserService _userService;
  final AuthService _authService;

  ProfileViewModel(this._service, this._userService, this._authService) {
    _userService.addListener(_onUserServiceChanged);
  }

  ProfileState _state = ProfileInitial();
  ProfileState get state => _state;

  void _onUserServiceChanged() {
    loadUser();
  }

  void _updateState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

  void loadUser() {
    final user = _userService.currentUser;
    if (user != null) {
      _updateState(ProfileLoaded(user: user));
    } else {
      _updateState(const ProfileError(message: 'User not found'));
    }
  }

  Future<void> updateCurrency(String currency) async {
    final currentUser = _userService.currentUser;
    if (currentUser == null) {
      _updateState(const ProfileError(message: 'User not found'));
      return;
    }

    _updateState(ProfileUpdating(user: currentUser));

    try {
      await _service.updateCurrency(currency);

      final updatedUser = _userService.currentUser;
      if (updatedUser != null) {
        _updateState(ProfileLoaded(user: updatedUser));
      }
    } catch (e) {
      _updateState(ProfileError(message: e.toString()));
      _updateState(ProfileLoaded(user: currentUser));
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      _updateState(ProfileError(message: e.toString()));
    }
  }

  @override
  void dispose() {
    _userService.removeListener(_onUserServiceChanged);
    super.dispose();
  }
}
