import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jura/app.dart';
import 'package:jura/core/utils/api_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Import MVVM features
import 'package:jura/features/login/login_service.dart';
import 'package:jura/features/login/login_viewmodel.dart';
import 'package:jura/features/journal/journal_service.dart';
import 'package:jura/features/journal/journal_viewmodel.dart';
import 'package:jura/features/register/register_service.dart';
import 'package:jura/features/register/register_viewmodel.dart';
import 'package:jura/features/profile/profile_service.dart';
import 'package:jura/features/profile/profile_viewmodel.dart';
import 'package:jura/features/chat/chat_service.dart';
import 'package:jura/features/chat/chat_viewmodel.dart';

import 'core/services/auth_service.dart';
import 'core/services/protected_api.dart';
import 'core/services/transaction_service.dart';
import 'core/services/user_service.dart';

final getIt = GetIt.instance;

Future<void> main() async {
  // load ENV
  await dotenv.load(fileName: ".env");
  // Initialize Configs
  ApiConfig.init();

  // Instantiate global services manually
  final secureStorage = const FlutterSecureStorage();
  final httpClient = http.Client();
  final authService = AuthService(
    httpClient: httpClient,
    secureStorage: secureStorage,
  )..init();
  final userService = UserService(storage: secureStorage)..init();
  final protectedApiClient = ProtectedApiClient(
    authService: authService,
    inner: httpClient,
    storage: secureStorage,
  );
  final transactionService = TransactionService(apiClient: protectedApiClient);
  final speechToText = stt.SpeechToText();

  // Instantiate feature services
  final loginService = LoginService(
    httpClient: httpClient,
    secureStorage: secureStorage,
  );
  final registerService = RegisterService(httpClient: httpClient);
  final profileService = ProfileService(userClient: userService);
  final chatService = ChatService(transactionService: transactionService);
  final journalService = JournalService(transactionService: transactionService);

  // Register services in GetIt for view access
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  getIt.registerSingleton<http.Client>(httpClient);
  getIt.registerSingleton<AuthService>(authService);
  getIt.registerSingleton<UserService>(userService);
  getIt.registerSingleton<ProtectedApiClient>(protectedApiClient);
  getIt.registerSingleton<TransactionService>(transactionService);
  getIt.registerSingleton<stt.SpeechToText>(speechToText);

  getIt.registerSingleton<LoginService>(loginService);
  getIt.registerSingleton<RegisterService>(registerService);
  getIt.registerSingleton<ProfileService>(profileService);
  getIt.registerSingleton<ChatService>(chatService);
  getIt.registerSingleton<JournalService>(journalService);

  // Instantiate and register MVVM viewmodels
  final loginViewModel = LoginViewModel(loginService, authService, userService);
  final registerViewModel = RegisterViewModel(registerService, authService);
  final chatViewModel = ChatViewModel(chatService, speechToText, userService);
  final journalViewModel = JournalViewModel(journalService, userService);
  final profileViewModel = ProfileViewModel(
    profileService,
    userService,
    authService,
  );

  getIt.registerSingleton<LoginViewModel>(loginViewModel);
  getIt.registerSingleton<RegisterViewModel>(registerViewModel);
  getIt.registerSingleton<ChatViewModel>(chatViewModel);
  getIt.registerSingleton<JournalViewModel>(journalViewModel);
  getIt.registerSingleton<ProfileViewModel>(profileViewModel);

  // RUN APP
  runApp(App());
}
