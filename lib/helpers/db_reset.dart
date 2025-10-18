import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'db_helper.dart';

class DatabaseReset {
  static Future<void> resetDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    String path = join(await getDatabasesPath(), 'ecclesia.db');
    await deleteDatabase(path);
    
    // إعادة إنشاء قاعدة البيانات
    await DatabaseHelper().database;
  }
}