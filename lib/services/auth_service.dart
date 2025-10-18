import '../helpers/db_helper.dart';
import '../helpers/cache_helper.dart';

class AuthService {
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // تسجيل الدخول
  static Future<bool> login(String username, String password) async {
    try {
      final user = await _dbHelper.authenticateUser(username, password);
      
      if (user != null) {
        await CacheHelper.saveUserData(
          userId: user['id'],
          username: user['username'],
          role: user['role'],
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // تسجيل الخروج
  static Future<void> logout() async {
    await CacheHelper.logout();
  }

  // التحقق من تسجيل الدخول
  static bool isLoggedIn() {
    return CacheHelper.isLoggedIn();
  }

  // الحصول على المستخدم الحالي
  static Map<String, dynamic>? getCurrentUser() {
    return CacheHelper.getUserData();
  }

  // إنشاء مستخدم جديد (للأدمن فقط)
  static Future<bool> createUser(String username, String password, String role) async {
    if (!CacheHelper.isAdmin()) {
      return false;
    }
    
    try {
      await _dbHelper.createUser(username, password, role);
      return true;
    } catch (e) {
      return false;
    }
  }

  // التحقق من الصلاحيات
  static bool canEdit() {
    return CacheHelper.canEdit();
  }

  static bool isAdmin() {
    return CacheHelper.isAdmin();
  }

  static bool isViewer() {
    return CacheHelper.isViewer();
  }
}