import 'package:jura/core/services/user_service.dart';

class ProfileService {
  final UserService _userService;

  ProfileService({required UserService userClient}) : _userService = userClient;

  Future<void> updateCurrency(String currency) async {
    _userService.updateCurrency(currency);
  }
}
