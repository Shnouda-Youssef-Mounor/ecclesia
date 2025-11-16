import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> deleteDatabaseFile() async {
    String dbPath;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      dbPath = join(await databaseFactoryFfi.getDatabasesPath(), 'ecclesia.db');
      await databaseFactoryFfi.deleteDatabase(dbPath);
    } else {
      dbPath = join(await getDatabasesPath(), 'ecclesia.db');
      await deleteDatabase(dbPath);
    }
  }

  Future<Database> _initDatabase() async {
    WidgetsFlutterBinding.ensureInitialized(); // 🟡 مهم جدًا لو بتستدعيها بدري

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 🖥️ Desktop
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      // في الـ Desktop مش بنستخدم getDatabasesPath()
      final dbPath = join(
        await databaseFactoryFfi.getDatabasesPath(),
        'ecclesia.db',
      );
      return await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // 📱 Android / iOS
      final dbPath = join(await getDatabasesPath(), 'ecclesia.db');
      return await openDatabase(
        dbPath,
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {}
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
    // جدول الكنيسة
    await db.execute('''
      CREATE TABLE churches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        church_name TEXT NOT NULL,
        church_logo TEXT,
        church_country TEXT NOT NULL,
        diocese_name TEXT NOT NULL,
        diocese_logo TEXT
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
        military_status TEXT,
        area_id INTEGER,
        area TEXT, 
        current_address TEXT,
        phone TEXT,
        whatsapp TEXT, 
        sector_id INTEGER NULL,
        education_stage_id INTEGER,
        education_institution TEXT,
        job_title TEXT, 
        work_place TEXT, 
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
      'role': 'admin',
    });
  }

  // دوال المصادقة
  Future<Map<String, dynamic>?> authenticateUser(
    String username,
    String password,
  ) async {
    final db = await database;
    String hashedPassword = sha256.convert(utf8.encode(password)).toString();

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    return result.isNotEmpty ? result.first : null;
  }

  // 🏛️ دوال CRUD للكنائس
  Future<int> insertChurch(Map<String, dynamic> church) async {
    final db = await database;
    return await db.insert('churches', church);
  }

  Future<List<Map<String, dynamic>>> getAllChurches() async {
    final db = await database;
    return await db.query('churches');
  }

  Future<int> updateChurch(int id, Map<String, dynamic> church) async {
    final db = await database;
    return await db.update(
      'churches',
      church,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChurch(int id) async {
    final db = await database;
    return await db.delete('churches', where: 'id = ?', whereArgs: [id]);
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

  Future<List<Map<String, dynamic>>> getAllIndividualsWithRelations() async {
    final db = await database;

    final individuals = await db.rawQuery('''
      SELECT i.*, es.stage_name as education_stage_name
      FROM individuals i
      LEFT JOIN education_stages es ON i.education_stage_id = es.id
    ''');

    List<Map<String, dynamic>> result = [];

    for (var individual in individuals) {
      final individualId = individual['id'];

      // جلب الأنشطة
      final activities = await db.rawQuery(
        '''
      SELECT a.id, a.activity_name 
      FROM activities a
      INNER JOIN individual_activities ia ON ia.activity_id = a.id
      WHERE ia.individual_id = ?
    ''',
        [individualId],
      );

      // جلب المساعدات
      final aids = await db.rawQuery(
        '''
      SELECT ad.id, ad.organization_name 
      FROM aids ad
      INNER JOIN individual_aids iad ON iad.aid_id = ad.id
      WHERE iad.individual_id = ?
    ''',
        [individualId],
      );

      // جلب القطاعات
      final sectors = await db.rawQuery(
        '''
      SELECT s.id, s.sector_name 
      FROM sectors s
      INNER JOIN individual_sectors isec ON isec.sector_id = s.id
      WHERE isec.individual_id = ?
    ''',
        [individualId],
      );

      // 🟢 جلب الأسرة اللي الفرد عضو فيها مع دوره
      final families = await db.rawQuery(
        '''
      SELECT f.id, f.family_name, f.family_address,
             CASE 
               WHEN f.father_id = ? THEN 'أب'
               WHEN f.mother_id = ? THEN 'أم'
               ELSE 'فرد'
             END as role
      FROM families f
      INNER JOIN family_members fm ON fm.family_id = f.id
      WHERE fm.individual_id = ?
    ''',
        [individualId, individualId, individualId],
      );

      result.add({
        ...individual,
        'activities': activities,
        'aids': aids,
        'sectors': sectors,
        'families': families, // 🟢 إضافة العائلة
      });
    }

    return result;
  }

  Future<int> updateIndividual(int id, Map<String, dynamic> individual) async {
    final db = await database;
    return await db.update(
      'individuals',
      individual,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // حذف كل الأنشطة المرتبطة بفرد
  Future<int> deleteIndividualActivities(int individualId) async {
    final db = await database;
    return await db.delete(
      'individual_activities',
      where: 'individual_id = ?',
      whereArgs: [individualId],
    );
  }

  // حذف كل المساعدات المرتبطة بفرد
  Future<int> deleteIndividualAids(int individualId) async {
    final db = await database;
    return await db.delete(
      'individual_aids',
      where: 'individual_id = ?',
      whereArgs: [individualId],
    );
  }

  // حذف كل القطاعات المرتبطة بفرد
  Future<int> deleteIndividualSectors(int individualId) async {
    final db = await database;
    return await db.delete(
      'individual_sectors',
      where: 'individual_id = ?',
      whereArgs: [individualId],
    );
  }

  // إدراج نشاط مرتبط بفرد
  Future<int> insertIndividualActivity(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('individual_activities', data);
  }

  // إدراج مساعدة مرتبطة بفرد
  Future<int> insertIndividualAid(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('individual_aids', data);
  }

  // إدراج قطاع مرتبط بفرد
  Future<int> insertIndividualSector(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('individual_sectors', data);
  }

  Future<int> deleteIndividual(int id) async {
    final db = await database;
    // حذف جميع العلاقات أولاً
    await db.delete('individual_activities', where: 'individual_id = ?', whereArgs: [id]);
    await db.delete('individual_aids', where: 'individual_id = ?', whereArgs: [id]);
    await db.delete('individual_sectors', where: 'individual_id = ?', whereArgs: [id]);
    await db.delete('family_members', where: 'individual_id = ?', whereArgs: [id]);
    await db.delete('children', where: 'parent_id = ? OR child_id = ?', whereArgs: [id, id]);
    await db.delete('servants', where: 'individual_id = ?', whereArgs: [id]);
    // حذف الفرد نفسه
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
    return await db.update(
      'families',
      family,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFamily(int id) async {
    final db = await database;
    // حذف العلاقات أولاً
    await db.delete('family_members', where: 'family_id = ?', whereArgs: [id]);
    // حذف العائلة نفسها
    return await db.delete('families', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateSector(int id, Map<String, dynamic> sector) async {
    final db = await database;
    return await db.update('sectors', sector, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSector(int id) async {
    final db = await database;
    // حذف العلاقات أولاً
    await db.delete('individual_sectors', where: 'sector_id = ?', whereArgs: [id]);
    await db.delete('servants', where: 'sector_id = ?', whereArgs: [id]);
    await db.delete('priests', where: 'sector_id = ?', whereArgs: [id]);
    // حذف القطاع نفسه
    return await db.delete('sectors', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateEducationStage(int id, Map<String, dynamic> stage) async {
    final db = await database;
    return await db.update(
      'education_stages',
      stage,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteEducationStage(int id) async {
    final db = await database;
    // تحديث الأفراد لإزالة المرجع للمرحلة التعليمية
    await db.update('individuals', {'education_stage_id': null}, where: 'education_stage_id = ?', whereArgs: [id]);
    // حذف المرحلة التعليمية نفسها
    return await db.delete(
      'education_stages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateServant(int id, Map<String, dynamic> servant) async {
    final db = await database;
    return await db.update(
      'servants',
      servant,
      where: 'id = ?',
      whereArgs: [id],
    );
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
    // حذف العلاقات أولاً
    await db.delete('individual_aids', where: 'aid_id = ?', whereArgs: [id]);
    // حذف المساعدة نفسها
    return await db.delete('aids', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateActivity(int id, Map<String, dynamic> activity) async {
    final db = await database;
    return await db.update(
      'activities',
      activity,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final db = await database;
    // حذف العلاقات أولاً
    await db.delete('individual_activities', where: 'activity_id = ?', whereArgs: [id]);
    // حذف النشاط نفسه
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
    // تحديث الأفراد والعائلات لإزالة المرجع للمنطقة
    await db.update('individuals', {'area_id': null}, where: 'area_id = ?', whereArgs: [id]);
    await db.update('families', {'area_id': null}, where: 'area_id = ?', whereArgs: [id]);
    // حذف المنطقة نفسها
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
      user['password'] = sha256
          .convert(utf8.encode(user['password']))
          .toString();
    }
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // دوال إدارة أعضاء الأسرة
  Future<void> addFamilyMember(int familyId, int individualId) async {
    final db = await database;
    await db.insert('family_members', {
      'family_id': familyId,
      'individual_id': individualId,
    });
  }

  Future<void> removeFamilyMember(int familyId, int individualId) async {
    final db = await database;
    await db.delete(
      'family_members',
      where: 'family_id = ? AND individual_id = ?',
      whereArgs: [familyId, individualId],
    );
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(int familyId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT i.* FROM individuals i
      JOIN family_members fm ON i.id = fm.individual_id
      WHERE fm.family_id = ?
    ''',
      [familyId],
    );
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

  // إعادة تهيئة قاعدة البيانات بالكامل
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // حذف ملف قاعدة البيانات
    await deleteDatabaseFile();

    // إعادة إنشاء قاعدة البيانات
    await database;
  }

  Future<String> backupDatabase() async {
    try {
      // تحديد مكان قاعدة البيانات الأصلية
      String originalDbPath;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        originalDbPath = join(
          await databaseFactoryFfi.getDatabasesPath(),
          'ecclesia.db',
        );
      } else {
        originalDbPath = join(await getDatabasesPath(), 'ecclesia.db');
      }

      final originalFile = File(originalDbPath);

      // يختار المستخدم مكان حفظ النسخة
      String? outputDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مكان حفظ النسخة الاحتياطية',
      );

      if (outputDir == null) {
        throw Exception('لم يتم اختيار مجلد للنسخ الاحتياطي');
      }

      // اسم النسخة الاحتياطية
      final backupPath = join(
        outputDir,
        'ecclesia_backup_${DateTime.now().millisecondsSinceEpoch}.db',
      );

      // نسخ الملف
      await originalFile.copy(backupPath);

      print('تم النسخ الاحتياطي إلى: $backupPath');
      return backupPath;
    } catch (e) {
      print('فشل في عمل النسخة الاحتياطية: $e');
      rethrow;
    }
  }

  Future<void> restoreDatabase() async {
    try {
      // اختيار ملف النسخة الاحتياطية من المستخدم
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'اختر ملف النسخة الاحتياطية للاستعادة',
        type: FileType.custom,
        allowedExtensions: ['db'],
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('لم يتم اختيار أي ملف');
      }

      String backupPath = result.files.single.path!;

      // إغلاق قاعدة البيانات الحالية
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // مسار القاعدة الأصلية
      String originalDbPath;
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        originalDbPath = join(
          await databaseFactoryFfi.getDatabasesPath(),
          'ecclesia.db',
        );
      } else {
        originalDbPath = join(await getDatabasesPath(), 'ecclesia.db');
      }

      final backupFile = File(backupPath);
      final originalFile = File(originalDbPath);

      if (await backupFile.exists()) {
        await backupFile.copy(originalFile.path);
      } else {
        throw Exception('ملف النسخة الاحتياطية غير موجود!');
      }

      await database;
      print('تم استعادة قاعدة البيانات بنجاح');
    } catch (e) {
      print('فشل في استعادة قاعدة البيانات: $e');
      rethrow;
    }
  }
}
