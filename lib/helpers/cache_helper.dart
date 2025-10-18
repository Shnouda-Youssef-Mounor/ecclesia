import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // حفظ بيانات المستخدم المسجل دخوله
  static Future<void> saveUserData({
    required int userId,
    required String username,
    required String role,
  }) async {
    await _prefs?.setInt('user_id', userId);
    await _prefs?.setString('username', username);
    await _prefs?.setString('user_role', role);
    await _prefs?.setBool('is_logged_in', true);
  }

  // الحصول على بيانات المستخدم
  static Map<String, dynamic>? getUserData() {
    if (_prefs?.getBool('is_logged_in') == true) {
      return {
        'user_id': _prefs?.getInt('user_id'),
        'username': _prefs?.getString('username'),
        'user_role': _prefs?.getString('user_role'),
      };
    }
    return null;
  }

  // التحقق من تسجيل الدخول
  static bool isLoggedIn() {
    return _prefs?.getBool('is_logged_in') ?? false;
  }

  // الحصول على دور المستخدم
  static String? getUserRole() {
    return _prefs?.getString('user_role');
  }

  // الحصول على اسم المستخدم
  static String? getUsername() {
    return _prefs?.getString('username');
  }

  // الحصول على معرف المستخدم
  static int? getUserId() {
    return _prefs?.getInt('user_id');
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    await _prefs?.remove('user_id');
    await _prefs?.remove('username');
    await _prefs?.remove('user_role');
    await _prefs?.setBool('is_logged_in', false);
  }

  // التحقق من صلاحيات المستخدم
  static bool canEdit() {
    String? role = getUserRole();
    return role == 'admin' || role == 'editor';
  }

  static bool isAdmin() {
    return getUserRole() == 'admin';
  }

  static bool isViewer() {
    return getUserRole() == 'viewer';
  }

  // حفظ إعدادات عامة
  static Future<void> saveString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs?.getString(key);
  }

  static Future<void> saveInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  static Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }
}