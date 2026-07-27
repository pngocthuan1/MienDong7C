import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _themeModeKey = 'theme_mode';
  static const String _languageCodeKey = 'language_code';

  // ==================== First launch ====================

  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_isFirstLaunchKey, value);
  }

  bool get isFirstLaunch => _prefs.getBool(_isFirstLaunchKey) ?? true;

  // ==================== Theme ====================

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  /// Trả về 'system', 'light', hoặc 'dark'. Mặc định 'system'.
  String get themeMode => _prefs.getString(_themeModeKey) ?? 'system';

  // ==================== Language ====================

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(_languageCodeKey, code);
  }

  /// Trả về mã ngôn ngữ, ví dụ 'vi', 'en'. Mặc định 'vi'.
  String get languageCode => _prefs.getString(_languageCodeKey) ?? 'vi';

  // ==================== Xóa dữ liệu ====================

  /// Chỉ xóa các key mà class này quản lý, không đụng tới
  /// dữ liệu khác có thể tồn tại chung trong SharedPreferences.
  Future<void> clear() async {
    await Future.wait([
      _prefs.remove(_isFirstLaunchKey),
      _prefs.remove(_themeModeKey),
      _prefs.remove(_languageCodeKey),
    ]);
  }
}
