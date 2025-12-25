import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:jura/core/utils/api_config.dart';
import 'package:jura/core/utils/storage_keys.dart';
import 'package:jura/core/models/user.dart';

import 'protected_api.dart';

class UserService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage;

  User? _currentUser;
  bool _isLoading = false;

  // Public getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  UserService({required FlutterSecureStorage storage})
    : _secureStorage = storage;

  /// Initialize user from secure storage
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await _secureStorage.read(key: storageKeyUserId);

      if (userId != null) {
        final username = await _secureStorage.read(key: storageKeyUsername);
        final primaryCurrency = await _secureStorage.read(
          key: storageKeyPrimaryCurrency,
        );
        final isPremiumStr = await _secureStorage.read(
          key: storageKeyIsPremium,
        );

        if (username != null &&
            primaryCurrency != null &&
            isPremiumStr != null) {
          _currentUser = User(
            id: userId,
            username: username,
            primaryCurrency: primaryCurrency,
            isPremium: isPremiumStr.toLowerCase() == 'true',
          );
        }
      }
    } catch (e) {
      // Log error but don't crash
      print('Error initializing user: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user after login/token refresh
  Future<void> setUser(User user) async {
    _currentUser = user;
    notifyListeners();
    // User is already stored in auth.dart's storeTokens(), but we can sync here if needed
  }

  /// Clear user data on logout
  Future<void> clearUser() async {
    _currentUser = null;
    notifyListeners();
  }

  /// Update specific user property
  void _updateUserProperty({
    String? username,
    String? primaryCurrency,
    bool? isPremium,
  }) {
    if (_currentUser == null) return;

    _currentUser = User(
      id: _currentUser!.id,
      username: username ?? _currentUser!.username,
      primaryCurrency: primaryCurrency ?? _currentUser!.primaryCurrency,
      isPremium: isPremium ?? _currentUser!.isPremium,
    );

    notifyListeners();
  }

  /// Update user's primary currency via API and sync to secure storage
  Future<void> updateCurrency(String currency) async {
    try {
      final apiClient = GetIt.I<ProtectedApiClient>();
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/currency');
      final body = {'currency': currency};

      final response = await apiClient.put(uri, body: body);

      if (response.statusCode != 200) {
        throw Exception('Failed to update currency: ${response.statusCode}');
      }

      // Update secure storage
      await _secureStorage.write(
        key: storageKeyPrimaryCurrency,
        value: currency,
      );

      // Update in-memory state
      _updateUserProperty(primaryCurrency: currency);
    } catch (e) {
      throw Exception('Error updating currency: $e');
    }
  }
}
