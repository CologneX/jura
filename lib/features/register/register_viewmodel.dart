import 'package:flutter/foundation.dart';
import 'package:jura/core/services/auth_service.dart';
import 'register_service.dart';

/// Register States
abstract class RegisterState {
  const RegisterState();
}

class RegisterInitial extends RegisterState {}

class RegisterUsernameInput extends RegisterState {}

class RegisterPinInput extends RegisterState {
  final String username;

  const RegisterPinInput({required this.username});
}

class RegisterLoading extends RegisterState {}

class RegisterSuccess extends RegisterState {
  final String username;

  const RegisterSuccess({required this.username});
}

class RegisterError extends RegisterState {
  final String message;

  const RegisterError({required this.message});
}

class RegisterViewModel extends ChangeNotifier {
  final RegisterService _service;
  final AuthService _authService;

  RegisterViewModel(this._service, this._authService);

  RegisterState _state = RegisterInitial();
  RegisterState get state => _state;

  void _updateState(RegisterState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initialize() async {
    await _authService.init();
    _updateState(RegisterUsernameInput());
  }

  void submitUsername(String username) {
    final trimmedUsername = username.trim();

    if (trimmedUsername.isEmpty || trimmedUsername.length < 3) {
      _updateState(
        const RegisterError(message: 'Username must be at least 3 characters'),
      );
      _updateState(RegisterUsernameInput());
      return;
    }

    _updateState(RegisterPinInput(username: trimmedUsername));
  }

  Future<void> submitPin(String username, String pin, String confirmPin) async {
    final trimmedPin = pin.trim();
    final trimmedConfirmPin = confirmPin.trim();

    if (trimmedPin.isEmpty) {
      _updateState(const RegisterError(message: 'Passcode is required'));
      return;
    }

    if (trimmedPin.length != 6) {
      _updateState(
        const RegisterError(message: 'Passcode must be exactly 6 characters'),
      );
      return;
    }

    if (trimmedPin != trimmedConfirmPin) {
      _updateState(RegisterError(message: 'Passcodes do not match'));
      return;
    }

    _updateState(RegisterLoading());

    try {
      await _service.register(username: username, passcode: trimmedPin);
      _updateState(RegisterSuccess(username: username));
    } catch (e) {
      _updateState(RegisterError(message: e.toString()));
      _updateState(RegisterPinInput(username: username));
    }
  }

  void backToUsername() {
    _updateState(RegisterUsernameInput());
  }
}
