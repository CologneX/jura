---
applyTo: "**"
---

# Project File Structure Standards

This document enforces the **Flat Feature-First** architecture. All developers must adhere strictly to this organization to maintain scalability and reduce cognitive load. Each feature folder acts as a self-contained module. Do not nest files into subfolders (`/services`, `/views`) inside the feature. Instead, use strict file suffixes to distinguish layers.

### Directory Tree

lib/
├── core/ # Global/Shared resources
│ ├── models/ # Shared Entities (User, Config)
│ ├── router/ # GoRouter configuration
│ ├── theme/ # AppTheme, Colors, Type
│ ├── utils/ # Formatters, Validators
│ └── widgets/ # Shared UI Components (Buttons, Inputs)
├── features/
│   ├── login/                # Feature: Login
│   │   ├── login_model.dart
│   │   ├── login_service.dart
│   │   ├── login_view.dart
│   │   └── login_view_model.dart
│   │
│   └── home/                 # Feature: Home
│       ├── home_service.dart
│       ├── home_view.dart
│       └── home_view_model.dart
│
├── app.dart # ShadcnApp/App Config
└── main.dart # Entry Point/DI Init

### Implementation

**1. Service**
**File:** `lib/features/login/login_service.dart`

```dart
class LoginService {
  Future<bool> authenticate(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'admin' && password == '1234') return true;
    throw Exception('Invalid credentials');
  }
}

```

**2. ViewModel**
**File:** `lib/features/login/login_view_model.dart`

```dart
import 'package:flutter/foundation.dart';
import 'login_service.dart'; // Direct import from same folder

class LoginViewModel extends ChangeNotifier {
  final LoginService _service;

  LoginViewModel(this._service);

  bool isLoading = false;
  String? error;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _service.authenticate(email, password);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}

```

**3. View**
**File:** `lib/features/login/login_view.dart`

```dart
import 'package:flutter/material.dart';
import 'login_service.dart';
import 'login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GetIt.I<LoginViewModel>();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => _viewModel.login('admin', '1234'),
              child: const Text('Login'),
            ),
          ),
        );
      },
    );
  }
}

```