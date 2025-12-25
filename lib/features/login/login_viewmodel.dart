import 'package:flutter/foundation.dart';
import 'package:jura/core/services/auth_service.dart';
import 'package:jura/core/services/user_service.dart';
import 'login_service.dart';

/// Login States
abstract class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {}

class LoginUsernameInput extends LoginState {
  final String? prefillUsername;

  const LoginUsernameInput({this.prefillUsername});
}

class LoginPinInput extends LoginState {
  final String username;

  const LoginPinInput({required this.username});
}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginError extends LoginState {
  final String message;

  const LoginError({required this.message});
}

class LoginViewModel extends ChangeNotifier {
  final LoginService _service;
  final AuthService _authService;
  final UserService _userService;

  LoginViewModel(this._service, this._authService, this._userService);

  LoginState _state = LoginInitial();
  LoginState get state => _state;

  void _updateState(LoginState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initialize({String? prefillUsername}) async {
    await _authService.init();
    _updateState(LoginUsernameInput(prefillUsername: prefillUsername));
  }

  void submitUsername(String username) {
    if (username.trim().isEmpty) {
      _updateState(const LoginError(message: 'Username is required'));
      _updateState(LoginUsernameInput(prefillUsername: username));
      return;
    }
    _updateState(LoginPinInput(username: username));
  }

  Future<void> submitPin(String username, String pin) async {
    final trimmedPin = pin.trim();

    if (trimmedPin.isEmpty) {
      _updateState(const LoginError(message: 'Passcode is required'));
      _updateState(LoginPinInput(username: username));
      return;
    }

    if (trimmedPin.length != 6) {
      _updateState(
        const LoginError(message: 'Passcode must be exactly 6 characters'),
      );
      _updateState(LoginPinInput(username: username));
      return;
    }

    _updateState(LoginLoading());

    try {
      final loginResponse = await _service.login(
        username: username,
        passcode: trimmedPin,
      );

      await _authService.init();
      await _userService.setUser(loginResponse.user);

      _updateState(LoginSuccess());
    } catch (e) {
      _updateState(LoginError(message: e.toString()));
      _updateState(LoginPinInput(username: username));
    }
  }

  void backToUsername() {
    final currentState = _state;
    if (currentState is LoginPinInput) {
      _updateState(LoginUsernameInput(prefillUsername: currentState.username));
    } else {
      _updateState(const LoginUsernameInput());
    }
  }
}
