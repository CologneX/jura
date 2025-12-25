import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jura/core/utils/storage_keys.dart';

final secureStorage = FlutterSecureStorage();

class User {
  final String id;
  final String username;
  final String primaryCurrency;
  final bool isPremium;

  User({
    required this.id,
    required this.username,
    required this.primaryCurrency,
    required this.isPremium,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      primaryCurrency: json['primary_currency'] as String,
      isPremium: json['is_premium'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'primary_currency': primaryCurrency,
      'is_premium': isPremium,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  // Save to secure storage
  Future<void> storeTokens() async {
    await secureStorage.write(key: storageKeyAccessToken, value: accessToken);
    await secureStorage.write(key: storageKeyRefreshToken, value: refreshToken);
    await secureStorage.write(key: storageKeyUserId, value: user.id);
    await secureStorage.write(key: storageKeyUsername, value: user.username);
    await secureStorage.write(
      key: storageKeyPrimaryCurrency,
      value: user.primaryCurrency,
    );
    await secureStorage.write(
      key: storageKeyIsPremium,
      value: user.isPremium.toString(),
    );
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final String refreshToken;

  RefreshTokenResponse({required this.accessToken, required this.refreshToken});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );
  }

  // Storing tokens to secure storage can be implemented here
  Future<void> storeTokens() async {
    await secureStorage.write(key: storageKeyAccessToken, value: accessToken);
    await secureStorage.write(key: storageKeyRefreshToken, value: refreshToken);
  }
}
