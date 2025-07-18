import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static Future<bool> isPinSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_pin') != null;
  }

  static Future<bool> isFingerprintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('fingerprint_enabled') ?? false;
  }

  static Future<void> resetAllAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin');
    await prefs.remove('fingerprint_enabled');
  }

  static Future<Map<String, bool>> getAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'pin_setup': prefs.getString('user_pin') != null,
      'fingerprint_enabled': prefs.getBool('fingerprint_enabled') ?? false,
    };
  }
}
