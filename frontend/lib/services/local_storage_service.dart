import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _guestModeKey = 'guest_mode';
  static const String _hasChosenKey = 'has_chosen_auth';

  Future<bool> hasUserChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasChosenKey) ?? false;
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, isGuest);
    await prefs.setBool(_hasChosenKey, true);
  }

  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }

  Future<void> clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestModeKey);
  }
}
