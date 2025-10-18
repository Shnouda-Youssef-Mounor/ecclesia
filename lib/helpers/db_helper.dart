import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    String path = join(await getDatabasesPath(), 'ecclesia.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // إضافة جدول المناطق
      await db.execute('''
        CREATE TABLE areas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          area_name TEXT NOT NULL,
          area_description TEXT
        )
      ''');
      
      // إضافة عمود area_id للأفراد
      await db.execute('ALTER TABLE individuals ADD COLUMN area_id INTEGER');
      
      // إضافة عمود area_id للأسر
      await db.execute('ALTER TABLE families ADD COLUMN area_id INTEGER');
      
      // إضافة بيانات المناطق التجريبية
      await db.insert('areas', {'area_name': 'مصر الجديدة', 'area_description': 'منطقة مصر الجديدة وما حولها'});
      await db.insert('areas', {'area_name': 'الدقي', 'area_description': 'منطقة الدقي والمهندسين'});
      await db.insert('areas', {'area_name': 'مدينة نصر', 'area_description': 'مدينة نصر والمناطق المجاورة'});
      await db.insert('areas', {'area_name': 'شبرا', 'area_description': 'منطقة شبرا وروض الفرج'});
      await db.insert('areas', {'area_name': 'الزيتون', 'area_description': 'منطقة الزيتون وحدائق القبة'});
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // جدول المستخدمين والأدوار
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL CHECK (role IN ('admin', 'editor', 'viewer')),
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // جدول المناطق
    await db.execute('''
      CREATE TABLE areas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        area_name TEXT NOT NULL,
        area_description TEXT
      )
    ''');

    // جدول المراحل التعليمية
    await db.execute('''
      CREATE TABLE education_stages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        stage_name TEXT NOT NULL
      )
    ''');

    // جدول القطاعات
    await db.execute('''
      CREATE TABLE sectors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sector_name TEXT NOT NULL,
        responsible_id INTEGER,
        meeting_time TEXT,
        FOREIGN KEY (responsible_id) REFERENCES servants (id)
      )
    ''');

    // جدول الأنشطة
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_name TEXT NOT NULL,
        description TEXT,
        schedule TEXT
      )
    ''');

    // جدول المساعدات
    await db.execute('''
      CREATE TABLE aids (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        organization_name TEXT NOT NULL,
        description TEXT,
        schedule TEXT
      )
    ''');

    // جدول الكهنة
    await db.execute('''
      CREATE TABLE priests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        priest_name TEXT NOT NULL,
        phone TEXT,
        sector_id INTEGER,
        FOREIGN KEY (sector_id) REFERENCES sectors (id)
      )
    ''');

    // جدول الأفراد
    await db.execute('''
      CREATE TABLE individuals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        national_id TEXT UNIQUE NOT NULL,
        governorate TEXT,
        birth_date TEXT,
        gender TEXT,
        marital_status TEXT,
        spouse_id INTEGER,
        military_status TEXT,
        area_id INTEGER,
        area TEXT,
        current_address TEXT,
        phone TEXT,
        whatsapp TEXT,
        family_name TEXT,
        education_stage_id INTEGER,
        education_institution TEXT,
        FOREIGN KEY (spouse_id) REFERENCES individuals (id),
        FOREIGN KEY (education_stage_id) REFERENCES education_stages (id),
        FOREIGN KEY (area_id) REFERENCES areas (id)
      )
    ''');

    // جدول الخدام
    await db.execute('''
      CREATE TABLE servants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        individual_id INTEGER NOT NULL,
        confession_father_id INTEGER,
        sector_id INTEGER,
        FOREIGN KEY (individual_id) REFERENCES individuals (id),
        FOREIGN KEY (confession_father_id) REFERENCES priests (id),
        FOREIGN KEY (sector_id) REFERENCES sectors (id)
      )
    ''');

    // جدول الأسر
    await db.execute('''
      CREATE TABLE families (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        family_name TEXT NOT NULL,
        family_address TEXT,
        area_id INTEGER,
        father_id INTEGER,
        mother_id INTEGER,
        FOREIGN KEY (father_id) REFERENCES individuals (id),
        FOREIGN KEY (mother_id) REFERENCES individuals (id),
        FOREIGN KEY (area_id) REFERENCES areas (id)
      )
    ''');

    // جدول علاقة الأفراد بالأنشطة
    await db.execute('''
      CREATE TABLE individual_activities (
        individual_id INTEGER,
        activity_id INTEGER,
        PRIMARY KEY (individual_id, activity_id),
        FOREIGN KEY (individual_id) REFERENCES individuals (id),
        FOREIGN KEY (activity_id) REFERENCES activities (id)
      )
    ''');

    // جدول علاقة الأفراد بالمساعدات
    await db.execute('''
      CREATE TABLE individual_aids (
        individual_id INTEGER,
        aid_id INTEGER,
        PRIMARY KEY (individual_id, aid_id),
        FOREIGN KEY (individual_id) REFERENCES individuals (id),
        FOREIGN KEY (aid_id) REFERENCES aids (id)
      )
    ''');

    // جدول علاقة الأفراد بالقطاعات
    await db.execute('''
      CREATE TABLE individual_sectors (
        individual_id INTEGER,
        sector_id INTEGER,
        PRIMARY KEY (individual_id, sector_id),
        FOREIGN KEY (individual_id) REFERENCES individuals (id),
        FOREIGN KEY (sector_id) REFERENCES sectors (id)
      )
    ''');

    // جدول الأطفال
    await db.execute('''
      CREATE TABLE children (
        parent_id INTEGER,
        child_id INTEGER,
        PRIMARY KEY (parent_id, child_id),
        FOREIGN KEY (parent_id) REFERENCES individuals (id),
        FOREIGN KEY (child_id) REFERENCES individuals (id)
      )
    ''');

    // جدول أعضاء الأسرة
    await db.execute('''
      CREATE TABLE family_members (
        family_id INTEGER,
        individual_id INTEGER,
        PRIMARY KEY (family_id, individual_id),
        FOREIGN KEY (family_id) REFERENCES families (id),
        FOREIGN KEY (individual_id) REFERENCES individuals (id)
      )
    ''');

    // إنشاء مستخدم admin افتراضي
    String hashedPassword = sha256.convert(utf8.encode('admin123')).toString();
    await db.insert('users', {
      'username': 'admin',
      'password': hashedPassword,
      'role': 'admin'
    });
  }

  // دوال المصادقة
  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final db = await database;
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();
    
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> createUser(String username, String password, String role) async {
    final db = await database;
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();
    
    return await db.insert('users', {
      'username': username,
      'password': hashedPassword,
      'role': role,
    });
  }

  // دوال CRUD للأفراد
  Future<int> insertIndividual(Map<String, dynamic> individual) async {
    final db = await database;
    return await db.insert('individuals', individual);
  }

  Future<List<Map<String, dynamic>>> getAllIndividuals() async {
    final db = await database;
    return await db.query('individuals');
  }

  Future<int> updateIndividual(int id, Map<String, dynamic> individual) async {
    final db = await database;
    return await db.update('individuals', individual, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteIndividual(int id) async {
    final db = await database;
    return await db.delete('individuals', where: 'id = ?', whereArgs: [id]);
  }

  // دوال CRUD للقطاعات
  Future<int> insertSector(Map<String, dynamic> sector) async {
    final db = await database;
    return await db.insert('sectors', sector);
  }

  Future<List<Map<String, dynamic>>> getAllSectors() async {
    final db = await database;
    return await db.query('sectors');
  }

  // دوال CRUD للخدام
  Future<int> insertServant(Map<String, dynamic> servant) async {
    final db = await database;
    return await db.insert('servants', servant);
  }

  Future<List<Map<String, dynamic>>> getAllServants() async {
    final db = await database;
    return await db.query('servants');
  }

  // دوال CRUD للكهنة
  Future<int> insertPriest(Map<String, dynamic> priest) async {
    final db = await database;
    return await db.insert('priests', priest);
  }

  Future<List<Map<String, dynamic>>> getAllPriests() async {
    final db = await database;
    return await db.query('priests');
  }

  // دوال CRUD للأنشطة
  Future<int> insertActivity(Map<String, dynamic> activity) async {
    final db = await database;
    return await db.insert('activities', activity);
  }

  Future<List<Map<String, dynamic>>> getAllActivities() async {
    final db = await database;
    return await db.query('activities');
  }

  // دوال CRUD للمساعدات
  Future<int> insertAid(Map<String, dynamic> aid) async {
    final db = await database;
    return await db.insert('aids', aid);
  }

  Future<List<Map<String, dynamic>>> getAllAids() async {
    final db = await database;
    return await db.query('aids');
  }

  // دوال CRUD للأسر
  Future<int> insertFamily(Map<String, dynamic> family) async {
    final db = await database;
    return await db.insert('families', family);
  }

  Future<List<Map<String, dynamic>>> getAllFamilies() async {
    final db = await database;
    return await db.query('families');
  }

  // دوال CRUD للمراحل التعليمية
  Future<int> insertEducationStage(Map<String, dynamic> stage) async {
    final db = await database;
    return await db.insert('education_stages', stage);
  }

  Future<List<Map<String, dynamic>>> getAllEducationStages() async {
    final db = await database;
    return await db.query('education_stages');
  }

  Future<int> updateFamily(int id, Map<String, dynamic> family) async {
    final db = await database;
    return await db.update('families', family, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFamily(int id) async {
    final db = await database;
    return await db.delete('families', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSector(int id, Map<String, dynamic> sector) async {
    final db = await database;
    return await db.update('sectors', sector, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSector(int id) async {
    final db = await database;
    return await db.delete('sectors', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEducationStage(int id, Map<String, dynamic> stage) async {
    final db = await database;
    return await db.update('education_stages', stage, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEducationStage(int id) async {
    final db = await database;
    return await db.delete('education_stages', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateServant(int id, Map<String, dynamic> servant) async {
    final db = await database;
    return await db.update('servants', servant, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteServant(int id) async {
    final db = await database;
    return await db.delete('servants', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePriest(int id, Map<String, dynamic> priest) async {
    final db = await database;
    return await db.update('priests', priest, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePriest(int id) async {
    final db = await database;
    return await db.delete('priests', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAid(int id, Map<String, dynamic> aid) async {
    final db = await database;
    return await db.update('aids', aid, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAid(int id) async {
    final db = await database;
    return await db.delete('aids', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateActivity(int id, Map<String, dynamic> activity) async {
    final db = await database;
    return await db.update('activities', activity, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteActivity(int id) async {
    final db = await database;
    return await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  // دوال CRUD للمناطق
  Future<int> insertArea(Map<String, dynamic> area) async {
    final db = await database;
    return await db.insert('areas', area);
  }

  Future<List<Map<String, dynamic>>> getAllAreas() async {
    final db = await database;
    return await db.query('areas');
  }

  Future<int> updateArea(int id, Map<String, dynamic> area) async {
    final db = await database;
    return await db.update('areas', area, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteArea(int id) async {
    final db = await database;
    return await db.delete('areas', where: 'id = ?', whereArgs: [id]);
  }

  // دوال CRUD للمستخدمين
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    if (user.containsKey('password')) {
      user['password'] = sha256.convert(utf8.encode(user['password'])).toString();
    }
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // تنظيف قاعدة البيانات (حذف جميع البيانات عدا المستخدمين)
  Future<void> clearAllDataExceptUsers() async {
    final db = await database;
    
    // حذف البيانات من جداول العلاقات أولاً
    await db.delete('individual_activities');
    await db.delete('individual_aids');
    await db.delete('individual_sectors');
    await db.delete('children');
    await db.delete('family_members');
    
    // حذف البيانات من الجداول الرئيسية
    await db.delete('individuals');
    await db.delete('families');
    await db.delete('sectors');
    await db.delete('servants');
    await db.delete('priests');
    await db.delete('activities');
    await db.delete('aids');
    await db.delete('education_stages');
    await db.delete('areas');
  }
}