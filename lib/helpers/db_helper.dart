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
          version: 4,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      // 📱 Android / iOS
      final dbPath = join(await getDatabasesPath(), 'ecclesia.db');
      return await openDatabase(
        dbPath,
        version: 4,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
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

    await db.execute('''
  CREATE TABLE aids (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    organization_name TEXT NOT NULL,
    aid_type TEXT,
    description TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

    // جدول box_items (المطلوب في الاستعلام) بدلاً من box_type_contents
    await db.execute('''
  CREATE TABLE box_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    box_type_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity REAL NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (box_type_id) REFERENCES box_types(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES inventory_items(id) ON DELETE CASCADE,
    UNIQUE(box_type_id, item_id)
  )
''');

    // جدول ready_boxes (المطلوب في التجهيز) بدلاً من boxes
    await db.execute('''
  CREATE TABLE ready_boxes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    box_type_id INTEGER NOT NULL,
    status TEXT DEFAULT 'ready',
    prepared_by TEXT NOT NULL,
    prepared_at TEXT NOT NULL,
    distribution_date TEXT,
    distributed_to TEXT,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (box_type_id) REFERENCES box_types(id)
  )
''');

    // جدول box_preparation_logs (المطلوب في التجهيز)
    await db.execute('''
  CREATE TABLE box_preparation_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    box_type_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    prepared_by TEXT NOT NULL,
    prepared_at TEXT NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (box_type_id) REFERENCES box_types(id)
  )
''');

    // جدول التبرعات (المذكور في الشاشات)
    await db.execute('''
  CREATE TABLE donations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    donor_name TEXT NOT NULL,
    donor_phone TEXT,
    donation_date TEXT NOT NULL,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

    // جدول تفاصيل التبرعات
    await db.execute('''
  CREATE TABLE donation_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    donation_id INTEGER NOT NULL,
    item_id INTEGER NOT NULL,
    quantity REAL NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (donation_id) REFERENCES donations(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES inventory_items(id)
  )
''');

    // جدول التوزيعات
    await db.execute('''
  CREATE TABLE distributions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipient_name TEXT NOT NULL,
    recipient_phone TEXT,
    distribution_date TEXT NOT NULL,
    box_type_id INTEGER,
    quantity INTEGER NOT NULL,
    distributed_by TEXT,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (box_type_id) REFERENCES box_types(id)
  )
''');

    // جدول تفاصيل التوزيع
    await db.execute('''
  CREATE TABLE distribution_details (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    distribution_id INTEGER NOT NULL,
    box_id INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (distribution_id) REFERENCES distributions(id) ON DELETE CASCADE,
    FOREIGN KEY (box_id) REFERENCES ready_boxes(id)
  )
''');
    // جدول أنواع الكرتونات
    await db.execute('''
  CREATE TABLE box_types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name TEXT NOT NULL,
    description TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

    // جدول الأصناف في المخزون
    await db.execute('''
  CREATE TABLE inventory_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_name TEXT NOT NULL,
    category TEXT CHECK(category IN ('طعام', 'ملابس', 'أدوات', 'طقسي', 'تعليمي', 'صحي', 'أخرى')),
    unit TEXT NOT NULL,
    min_quantity INTEGER DEFAULT 0,
    current_quantity INTEGER DEFAULT 0,
    storage_unit INTEGER DEFAULT 0,
    location TEXT,
    notes TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
  )
''');

    // جدول محتويات كل نوع كرتون
    await db.execute('''
  CREATE TABLE box_type_contents (
    box_type_id INTEGER,
    item_id INTEGER,
    quantity INTEGER NOT NULL,
    PRIMARY KEY (box_type_id, item_id),
    FOREIGN KEY (box_type_id) REFERENCES box_types (id),
    FOREIGN KEY (item_id) REFERENCES inventory_items (id)
  )
''');

    // جدول الكرتونات الجاهزة
    await db.execute('''
  CREATE TABLE boxes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    box_number TEXT UNIQUE NOT NULL,
    box_type_id INTEGER NOT NULL,
    status TEXT CHECK(status IN ('جاهز', 'مستلم', 'تالف', 'مفقود')) DEFAULT 'جاهز',
    prepared_by TEXT,
    prepared_date TEXT,
    distributed_to TEXT,
    distributed_date TEXT,
    qr_code TEXT,
    notes TEXT,
    FOREIGN KEY (box_type_id) REFERENCES box_types (id)
  )
''');

    // جدول حركات المخزون
    await db.execute('''
  CREATE TABLE inventory_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_type TEXT CHECK(transaction_type IN ('دخول', 'خروج', 'تجهيز', 'تعديل', 'تلف')),
    item_id INTEGER,
    quantity_change INTEGER NOT NULL,
    box_id INTEGER,
    related_entity_type TEXT CHECK(related_entity_type IN ('تبرع', 'خدمة', 'إغاثة', 'عائلة', 'فرد', 'أخرى')),
    related_entity_id INTEGER,
    notes TEXT,
    performed_by TEXT,
    transaction_date TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (item_id) REFERENCES inventory_items (id),
    FOREIGN KEY (box_id) REFERENCES boxes (id)
  )
''');

    // جدول المخازن
    await db.execute('''
  CREATE TABLE warehouses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    warehouse_name TEXT NOT NULL,
    location TEXT,
    manager TEXT,
    capacity INTEGER,
    notes TEXT
  )
''');

    // جدول مخزون المخازن
    await db.execute('''
  CREATE TABLE warehouse_stock (
    warehouse_id INTEGER,
    item_id INTEGER,
    quantity INTEGER NOT NULL,
    last_updated TEXT DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (warehouse_id, item_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses (id),
    FOREIGN KEY (item_id) REFERENCES inventory_items (id)
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
    await db.delete(
      'individual_activities',
      where: 'individual_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'individual_aids',
      where: 'individual_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'individual_sectors',
      where: 'individual_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'family_members',
      where: 'individual_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'children',
      where: 'parent_id = ? OR child_id = ?',
      whereArgs: [id, id],
    );
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
    await db.delete(
      'individual_sectors',
      where: 'sector_id = ?',
      whereArgs: [id],
    );
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
    await db.update(
      'individuals',
      {'education_stage_id': null},
      where: 'education_stage_id = ?',
      whereArgs: [id],
    );
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
    await db.delete(
      'individual_activities',
      where: 'activity_id = ?',
      whereArgs: [id],
    );
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
    await db.update(
      'individuals',
      {'area_id': null},
      where: 'area_id = ?',
      whereArgs: [id],
    );
    await db.update(
      'families',
      {'area_id': null},
      where: 'area_id = ?',
      whereArgs: [id],
    );
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

  // في قسم دوال الكرتونات بعد دوال الكرتونات الأساسية
  Future<int> updateBox(int id, Map<String, dynamic> box) async {
    final db = await database;
    return await db.update('boxes', box, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBox(int id) async {
    final db = await database;
    // حذف جميع الحركات المرتبطة بالكرتون أولاً
    await db.delete(
      'inventory_transactions',
      where: 'box_id = ?',
      whereArgs: [id],
    );
    // حذف الكرتون نفسه
    return await db.delete('boxes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getBoxById(int id) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT b.*, bt.type_name FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    WHERE b.id = ?
  ''',
      [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getBoxesByStatus(String status) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT b.*, bt.type_name FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    WHERE b.status = ?
    ORDER BY b.prepared_date DESC
  ''',
      [status],
    );
  }

  Future<int> getBoxCountByStatus(String status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM boxes WHERE status = ?',
      [status],
    );
    return result.isNotEmpty ? result.first['count'] as int : 0;
  }

  Future<List<Map<String, dynamic>>> getTopUsedItems({int limit = 5}) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT i.item_name, i.category, i.current_quantity,
           (SELECT COUNT(*) FROM box_type_contents bc 
            WHERE bc.item_id = i.id) as used_in_boxes
    FROM inventory_items i
    ORDER BY used_in_boxes DESC
    LIMIT ?
  ''',
      [limit],
    );
  }

  Future<List<Map<String, dynamic>>> getDistributionByType() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT bt.type_name, COUNT(b.id) as box_count,
           SUM(CASE WHEN b.status = 'مستلم' THEN 1 ELSE 0 END) as distributed_count
    FROM box_types bt
    LEFT JOIN boxes b ON bt.id = b.box_type_id
    WHERE bt.is_active = 1
    GROUP BY bt.id
    ORDER BY distributed_count DESC
  ''');
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({
    int limit = 10,
  }) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT t.*, i.item_name, i.unit 
    FROM inventory_transactions t
    LEFT JOIN inventory_items i ON t.item_id = i.id
    ORDER BY t.transaction_date DESC
    LIMIT ?
  ''',
      [limit],
    );
  }

  // في بداية class DatabaseHelper بعد متغيرات الإعداد
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  // تنظيف قاعدة البيانات (حذف جميع البيانات عدا المستخدمين)
  Future<void> clearAllDataExceptUsers() async {
    final db = await database;
    // حذف جداول المخزون الجديدة
    await db.delete('inventory_transactions');
    await db.delete('warehouse_stock');
    await db.delete('boxes');
    await db.delete('box_type_contents');
    await db.delete('inventory_items');
    await db.delete('box_types');
    await db.delete('warehouses');
    await db.delete('aid_boxes');

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

  // ================== دوال إدارة أنواع الكرتونات ==================
  Future<int> insertBoxType(Map<String, dynamic> boxType) async {
    final db = await database;
    return await db.insert('box_types', boxType);
  }

  Future<List<Map<String, dynamic>>> getAllBoxTypes() async {
    final db = await database;
    return await db.query('box_types', where: 'is_active = 1');
  }

  Future<Map<String, dynamic>?> getBoxTypeById(int id) async {
    final db = await database;
    final result = await db.query(
      'box_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateBoxType(int id, Map<String, dynamic> boxType) async {
    final db = await database;
    return await db.update(
      'box_types',
      boxType,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBoxType(int id) async {
    final db = await database;
    // التحقق من عدم وجود كرتونات مرتبطة بهذا النوع
    final boxes = await db.query(
      'boxes',
      where: 'box_type_id = ?',
      whereArgs: [id],
    );
    if (boxes.isNotEmpty) {
      throw Exception('لا يمكن حذف نوع الكرتون لأنه مرتبط بكرتونات موجودة');
    }

    // حذف محتويات نوع الكرتون أولاً
    await db.delete(
      'box_type_contents',
      where: 'box_type_id = ?',
      whereArgs: [id],
    );

    // تعطيل بدلاً من الحذف
    return await db.update(
      'box_types',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================== دوال إدارة محتويات أنواع الكرتون ==================
  Future<void> addItemToBoxType(int boxTypeId, int itemId, int quantity) async {
    final db = await database;
    await db.insert('box_type_contents', {
      'box_type_id': boxTypeId,
      'item_id': itemId,
      'quantity': quantity,
    });
  }

  Future<void> updateBoxTypeItem(
    int boxTypeId,
    int itemId,
    int quantity,
  ) async {
    final db = await database;
    await db.update(
      'box_type_contents',
      {'quantity': quantity},
      where: 'box_type_id = ? AND item_id = ?',
      whereArgs: [boxTypeId, itemId],
    );
  }

  Future<void> removeItemFromBoxType(int boxTypeId, int itemId) async {
    final db = await database;
    await db.delete(
      'box_type_contents',
      where: 'box_type_id = ? AND item_id = ?',
      whereArgs: [boxTypeId, itemId],
    );
  }

  // في DatabaseHelper
  Future<List<Map<String, dynamic>>> getBoxTypeContents(int boxTypeId) async {
    final db = await database;
    final dataTest = await db.rawQuery('''
    SELECT 
      bc.*,
      ii.item_name,
      ii.category,
      ii.unit, 
      ii.current_quantity,
      ii.min_quantity
    FROM box_type_contents bc
    LEFT JOIN inventory_items ii ON bc.item_id = ii.id
    ORDER BY ii.category, ii.item_name
  ''');
    print(dataTest);
    // ✅ استخدام unit وليس storage_unit
    return await db.rawQuery(
      '''
    SELECT 
      bc.*,
      ii.item_name,
      ii.category,
      ii.unit, 
      ii.current_quantity,
      ii.min_quantity
    FROM box_type_contents bc
    LEFT JOIN inventory_items ii ON bc.item_id = ii.id
    WHERE bc.box_type_id = ?
    ORDER BY ii.category, ii.item_name
  ''',
      [boxTypeId],
    );
  }

  // أضف هذه الدالة في DatabaseHelper
  Future<int> distributeReadyBox(
    int boxId,
    String distributedTo,
    String notes,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    try {
      return await db.transaction((txn) async {
        // 1. تحديث حالة الكرتون في ready_boxes
        await txn.update(
          'ready_boxes',
          {
            'status': 'distributed', // أو 'مستلم'
            'distributed_to': distributedTo,
            'distribution_date': now,
            'notes': notes,
          },
          where: 'id = ?',
          whereArgs: [boxId],
        );

        // 2. نسخ الكرتون إلى جدول distributions أو boxes إذا أردت
        // هذا اختياري حسب احتياجك

        return 1;
      });
    } catch (e) {
      print('❌ خطأ في توزيع الكرتون: $e');
      rethrow;
    }
  }

  // جلب جميع الأفراد مع معرفاتهم وأسمائهم
  Future<List<Map<String, dynamic>>> getAllIndividualsForDropdown() async {
    final db = await database;
    try {
      return await db.rawQuery('''
      SELECT id, full_name, phone, national_id 
      FROM individuals 
      ORDER BY full_name ASC
    ''');
    } catch (e) {
      print('❌ خطأ في getAllIndividualsForDropdown: $e');
      return [];
    }
  }

  // جلب جميع العائلات مع معرفاتها وأسمائها
  Future<List<Map<String, dynamic>>> getAllFamiliesForDropdown() async {
    final db = await database;
    try {
      return await db.rawQuery('''
      SELECT id, family_name, family_address 
      FROM families 
      ORDER BY family_name ASC
    ''');
    } catch (e) {
      print('❌ خطأ في getAllFamiliesForDropdown: $e');
      return [];
    }
  }

  // جلب إحصائيات عامة محدثة
  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await database;

    try {
      // إجمالي الأصناف
      final totalItems = await db.rawQuery(
        'SELECT COUNT(*) as count FROM inventory_items',
      );

      // الأصناف منخفضة المخزون
      final lowStockItems = await db.rawQuery('''
      SELECT COUNT(*) as count FROM inventory_items 
      WHERE current_quantity <= min_quantity
    ''');

      // إجمالي الكرتونات في ready_boxes (الجاهزة)
      final totalReadyBoxes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ready_boxes 
      WHERE status = 'ready' OR status = 'جاهز'
    ''');

      // إجمالي الكرتونات الموزعة
      final totalDistributedBoxes = await db.rawQuery('''
      SELECT COUNT(*) as count FROM ready_boxes 
      WHERE status = 'distributed' OR status = 'مستلم'
    ''');

      // إجمالي الكرتونات (الكل)
      final totalBoxes = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ready_boxes',
      );

      return {
        'total_items':
            (totalItems.isNotEmpty ? totalItems.first['count'] : 0) ?? 0,
        'low_stock_items':
            (lowStockItems.isNotEmpty ? lowStockItems.first['count'] : 0) ?? 0,
        'total_boxes':
            (totalBoxes.isNotEmpty ? totalBoxes.first['count'] : 0) ?? 0,
        'ready_boxes':
            (totalReadyBoxes.isNotEmpty ? totalReadyBoxes.first['count'] : 0) ??
            0,
        'distributed_boxes':
            (totalDistributedBoxes.isNotEmpty
                ? totalDistributedBoxes.first['count']
                : 0) ??
            0,
      };
    } catch (e) {
      print('❌ خطأ في getInventorySummary: $e');
      return {
        'total_items': 0,
        'low_stock_items': 0,
        'total_boxes': 0,
        'ready_boxes': 0,
        'distributed_boxes': 0,
      };
    }
  }

  // جلب أحدث التوزيعات من ready_boxes
  Future<List<Map<String, dynamic>>> getRecentDistributions({
    int limit = 10,
  }) async {
    final db = await database;

    try {
      return await db.rawQuery(
        '''
      SELECT 
        rb.*,
        bt.type_name,
        bt.description as type_description
      FROM ready_boxes rb
      JOIN box_types bt ON rb.box_type_id = bt.id
      WHERE rb.status = 'distributed' OR rb.status = 'مستلم'
      ORDER BY rb.distribution_date DESC
      LIMIT ?
    ''',
        [limit],
      );
    } catch (e) {
      print('❌ خطأ في getRecentDistributions: $e');
      return [];
    }
  }

  // جلب الأصناف منخفضة المخزون
  Future<List<Map<String, dynamic>>> getLowStockItems({int limit = 10}) async {
    final db = await database;

    try {
      return await db.rawQuery(
        '''
      SELECT * FROM inventory_items 
      WHERE current_quantity <= min_quantity
      ORDER BY (CAST(current_quantity AS REAL) / CAST(min_quantity AS REAL)) ASC
      LIMIT ?
    ''',
        [limit],
      );
    } catch (e) {
      print('❌ خطأ في getLowStockItems: $e');
      return [];
    }
  }

  // جلب أكثر أنواع الكرتونات توزيعاً
  Future<List<Map<String, dynamic>>> getTopDistributedBoxTypes({
    int limit = 5,
  }) async {
    final db = await database;

    try {
      return await db.rawQuery(
        '''
      SELECT 
        bt.id,
        bt.type_name,
        COUNT(rb.id) as total_distributed,
        bt.description
      FROM ready_boxes rb
      JOIN box_types bt ON rb.box_type_id = bt.id
      WHERE rb.status = 'distributed' OR rb.status = 'مستلم'
      GROUP BY bt.id
      ORDER BY total_distributed DESC
      LIMIT ?
    ''',
        [limit],
      );
    } catch (e) {
      print('❌ خطأ في getTopDistributedBoxTypes: $e');
      return [];
    }
  }

  // جلب إحصائيات التوزيع حسب الشهر
  Future<List<Map<String, dynamic>>> getMonthlyDistributionStats() async {
    final db = await database;

    try {
      return await db.rawQuery('''
      SELECT 
        strftime('%Y-%m', distribution_date) as month,
        COUNT(*) as total_distributed
      FROM ready_boxes
      WHERE (status = 'distributed' OR status = 'مستلم')
        AND distribution_date IS NOT NULL
      GROUP BY strftime('%Y-%m', distribution_date)
      ORDER BY month DESC
      LIMIT 6
    ''');
    } catch (e) {
      print('❌ خطأ في getMonthlyDistributionStats: $e');
      return [];
    }
  }

  // جلب جميع الكرتونات الجاهزة
  Future<List<Map<String, dynamic>>> getAllReadyBoxes() async {
    final db = await database;

    try {
      return await db.rawQuery('''
      SELECT 
        rb.*,
        bt.type_name,
        bt.description as type_description
      FROM ready_boxes rb
      JOIN box_types bt ON rb.box_type_id = bt.id
      WHERE rb.status = 'ready' OR rb.status = 'جاهز'
      ORDER BY rb.prepared_at DESC
    ''');
    } catch (e) {
      print('❌ خطأ في getAllReadyBoxes: $e');
      return [];
    }
  }

  // جلب جميع الكرتونات الموزعة
  Future<List<Map<String, dynamic>>> getAllDistributedBoxes() async {
    final db = await database;

    try {
      return await db.rawQuery('''
      SELECT 
        rb.*,
        bt.type_name,
        bt.description as type_description
      FROM ready_boxes rb
      JOIN box_types bt ON rb.box_type_id = bt.id
      WHERE rb.status = 'distributed' OR rb.status = 'مستلم'
      ORDER BY rb.distribution_date DESC
    ''');
    } catch (e) {
      print('❌ خطأ في getAllDistributedBoxes: $e');
      return [];
    }
  }

  // أضف هذه الدوال في DatabaseHelper

  // دالة لتوحيد قيم الحالة
  Future<void> normalizeBoxStatuses() async {
    final db = await database;

    try {
      await db.transaction((txn) async {
        // تحويل 'ready' إلى 'جاهز'
        await txn.rawUpdate('''
        UPDATE ready_boxes 
        SET status = 'جاهز' 
        WHERE status = 'ready' OR status = 'ready' OR status = 'READY' OR status = 'Ready'
      ''');

        // تحويل 'distributed' إلى 'مستلم'
        await txn.rawUpdate('''
        UPDATE ready_boxes 
        SET status = 'مستلم' 
        WHERE status = 'distributed' OR status = 'delivered' OR status = 'DISTRIBUTED' OR status = 'Distributed'
      ''');

        // تحويل 'damaged' إلى 'تالف'
        await txn.rawUpdate('''
        UPDATE ready_boxes 
        SET status = 'تالف' 
        WHERE status = 'damaged' OR status = 'damage' OR status = 'DAMAGED' OR status = 'Damaged'
      ''');
      });

      print('✅ تم توحيد قيم الحالة في قاعدة البيانات');
    } catch (e) {
      print('❌ خطأ في توحيد الحالات: $e');
    }
  }

  // دالة للتحقق من قيم الحالة
  Future<void> checkBoxStatusValues() async {
    final db = await database;

    try {
      // جلب جميع القيم المختلفة للحقل status
      final result = await db.rawQuery('''
      SELECT DISTINCT status, COUNT(*) as count
      FROM ready_boxes
      GROUP BY status
    ''');

      print('📊 قيم الحالة المختلفة في قاعدة البيانات:');
      for (var row in result) {
        print('   - ${row['status']}: ${row['count']} كرتون');
      }

      // جلب عينة من البيانات
      final sample = await db.rawQuery('''
      SELECT id, status, box_type_id, prepared_at 
      FROM ready_boxes 
      LIMIT 3
    ''');

      print('📝 عينة من البيانات:');
      for (var row in sample) {
        print('   - ID: ${row['id']}, Status: ${row['status']}');
      }
    } catch (e) {
      print('❌ خطأ في التحقق: $e');
    }
  }

  // ================== دوال إدارة الأصناف في المخزون ==================
  Future<int> insertInventoryItem(Map<String, dynamic> item) async {
    final db = await database;
    return await db.insert('inventory_items', item);
  }

  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
    final db = await database;
    return await db.query('inventory_items', orderBy: 'item_name');
  }

  Future<Map<String, dynamic>?> getInventoryItemById(int id) async {
    final db = await database;
    final result = await db.query(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateInventoryItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    item['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'inventory_items',
      item,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateInventoryQuantity(
    int itemId,
    int quantityChange,
    String reason,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // تحديث الكمية الحالية
      await txn.rawUpdate(
        '''
      UPDATE inventory_items 
      SET current_quantity = current_quantity + ?, 
          updated_at = ?
      WHERE id = ?
    ''',
        [quantityChange, DateTime.now().toIso8601String(), itemId],
      );

      // تسجيل الحركة
      await txn.insert('inventory_transactions', {
        'transaction_type': quantityChange > 0 ? 'دخول' : 'خروج',
        'item_id': itemId,
        'quantity_change': quantityChange,
        'notes': reason,
        'transaction_date': DateTime.now().toIso8601String(),
      });
    });
    return quantityChange;
  }

  Future<int> deleteInventoryItem(int id) async {
    final db = await database;
    // التحقق من عدم وجود الكرتونات مرتبطة بهذا الصنف
    final boxContents = await db.query(
      'box_type_contents',
      where: 'item_id = ?',
      whereArgs: [id],
    );
    if (boxContents.isNotEmpty) {
      throw Exception('لا يمكن حذف الصنف لأنه مرتبط بأنواع كرتونات');
    }

    return await db.delete('inventory_items', where: 'id = ?', whereArgs: [id]);
  }

  // ================== دوال إدارة الكرتونات ==================
  Future<int> insertBox(Map<String, dynamic> box) async {
    final db = await database;
    return await db.insert('boxes', box);
  }

  Future<List<Map<String, dynamic>>> getAllBoxes({String? status}) async {
    final db = await database;
    if (status != null) {
      return await db.query(
        'boxes',
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'prepared_date DESC',
      );
    }
    return await db.query('boxes', orderBy: 'prepared_date DESC');
  }

  Future<List<Map<String, dynamic>>> getBoxesByType(int boxTypeId) async {
    final db = await database;
    return await db.query(
      'boxes',
      where: 'box_type_id = ?',
      whereArgs: [boxTypeId],
      orderBy: 'prepared_date DESC',
    );
  }

  Future<int> prepareBoxes(
    int boxTypeId,
    int quantity,
    String preparedBy,
  ) async {
    final db = await database;

    try {
      return await db.transaction<int>((txn) async {
        final now = DateTime.now().toIso8601String();

        // ✅ استخدام الجدول الصحيح: box_type_contents (ليس box_items)
        final boxContents = await txn.rawQuery(
          '''
        SELECT 
          bc.*,
          ii.item_name,
          ii.category,
          ii.unit,
          ii.current_quantity,
          ii.min_quantity
        FROM box_type_contents bc
        LEFT JOIN inventory_items ii ON bc.item_id = ii.id
        WHERE bc.box_type_id = ?
        ORDER BY ii.category, ii.item_name
      ''',
          [boxTypeId],
        );

        // 1. التحقق من توفر المخزون
        for (var content in boxContents) {
          final int itemQuantity = (content['quantity'] as int?) ?? 0;
          final int currentQuantity =
              (content['current_quantity'] as int?) ?? 0;

          final int requiredQuantity = itemQuantity * quantity;

          if (requiredQuantity > currentQuantity) {
            throw Exception('غير كافي ${content['item_name']}');
          }
        }

        // 2. تحديث مخزون الأصناف (هنا current_quantity تقل)
        for (var content in boxContents) {
          final int itemQuantity = (content['quantity'] as int?) ?? 0;
          final int currentQuantity =
              (content['current_quantity'] as int?) ?? 0;

          final int requiredQuantity = itemQuantity * quantity;

          // ✅ هذه العملية تنقص current_quantity
          await txn.update(
            'inventory_items',
            {
              'current_quantity': currentQuantity - requiredQuantity,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [content['id']],
          );

          // تسجيل حركة السحب
          await txn.insert('inventory_transactions', {
            'item_id': content['id'],
            'transaction_type': 'تجهيز', // ✅ نوع الحركة
            'quantity_change': -requiredQuantity, // ✅ سالب لأنها سحب
            'box_id': null, // سيتم تحديثها بعد إنشاء الكرتون
            'notes': 'تجهيز كرتون - $preparedBy',
            'performed_by': preparedBy,
            'transaction_date': now,
          });
        }

        int lastBoxId = 0;

        // 3. إضافة الكرتونات الجاهزة في جدول boxes
        for (int i = 0; i < quantity; i++) {
          // ✅ استخدام جدول boxes (ليس ready_boxes)
          final boxNumber =
              'BOX-${DateTime.now().millisecondsSinceEpoch}-${i + 1}';
          final result = await txn.insert('boxes', {
            'box_number': boxNumber,
            'box_type_id': boxTypeId,
            'status': 'جاهز', // ✅ استخدام 'جاهز' (ليس 'ready')
            'prepared_by': preparedBy,
            'prepared_date': now,
            'distributed_to': null,
            'distributed_date': null,
            'qr_code': null,
            'notes': null,
          });

          if (i == 0) lastBoxId = result; // حفظ أول ID لعملية التحديث
        }

        // 4. تحديث حركات المخزون برقم الكرتون
        if (lastBoxId > 0) {
          await txn.update(
            'inventory_transactions',
            {'box_id': lastBoxId},
            where: 'transaction_date = ? AND box_id IS NULL',
            whereArgs: [now],
          );
        }

        return quantity;
      });
    } catch (e) {
      rethrow;
    }
  }

  // طريقة باستخدام Batch بدون cancel
  Future<int> prepareBoxesBatch(
    int boxTypeId,
    int quantity,
    String preparedBy,
  ) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();

    try {
      final boxContents = await getBoxTypeContents(boxTypeId);

      // التحقق من المخزون أولاً - خارج الـ Batch
      for (var content in boxContents) {
        final requiredQuantity = (content['quantity'] ?? 0) * quantity;
        final currentQuantity = content['current_quantity'] ?? 0;

        if (requiredQuantity > currentQuantity) {
          throw Exception('غير كافي ${content['item_name']}');
        }
      }

      // استخدام batch للعمليات
      for (var content in boxContents) {
        final requiredQuantity = (content['quantity'] ?? 0) * quantity;

        // تحديث المخزون
        batch.update(
          'inventory_items',
          {
            'current_quantity': content['current_quantity'] - requiredQuantity,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [content['id']],
        );

        // تسجيل الحركة
        batch.insert('inventory_transactions', {
          'item_id': content['id'],
          'transaction_type': 'withdrawal',
          'quantity': requiredQuantity,
          'reason': 'تجهيز كرتون - $preparedBy',
          'box_type_id': boxTypeId,
          'created_at': now,
        });
      }

      // إضافة الكرتونات
      for (int i = 0; i < quantity; i++) {
        batch.insert('ready_boxes', {
          'box_type_id': boxTypeId,
          'status': 'ready',
          'prepared_by': preparedBy,
          'prepared_at': now,
          'distribution_date': null,
          'distributed_to': null,
          'notes': null,
          'created_at': now,
        });
      }

      // سجل التجهيز
      batch.insert('box_preparation_logs', {
        'box_type_id': boxTypeId,
        'quantity': quantity,
        'prepared_by': preparedBy,
        'prepared_at': now,
        'created_at': now,
      });

      // تنفيذ جميع العمليات معاً
      await batch.commit(noResult: true);

      return quantity;
    } catch (e) {
      // في حالة الخطأ، الـ Batch لن يتم تنفيذه
      // يمكننا إعادة المحاولة أو التعامل مع الخطأ
      rethrow;
    }
  }

  // طريقة محسنة باستخدام transaction مع rollback يدوي
  Future<int> prepareBoxesSafe(
    int boxTypeId,
    int quantity,
    String preparedBy,
  ) async {
    final db = await database;

    try {
      return await db.transaction<int>((txn) async {
        final now = DateTime.now().toIso8601String();

        print('📦 بدء تجهيز $quantity كرتون من النوع $boxTypeId');

        // جلب محتويات الكرتون مع المخزون الحالي
        final boxContents = await _getBoxTypeContentsForTransaction(
          txn,
          boxTypeId,
        );

        print('📋 محتويات الكرتون: $boxContents');

        if (boxContents.isEmpty) {
          throw Exception('لا توجد مواد لهذا النوع من الكرتون');
        }

        // التحقق من المخزون
        for (var content in boxContents) {
          final requiredQuantity = (content['quantity'] ?? 0) * quantity;
          final currentQuantity = content['current_quantity'] ?? 0;
          final itemName = content['item_name'] ?? 'مادة غير معروفة';

          if (requiredQuantity > currentQuantity) {
            throw Exception('غير كافي - $itemName');
          }
        }

        // تحديث المخزون وتسجيل المعاملات
        await _updateInventoryForBoxPreparation(
          txn,
          boxContents,
          quantity,
          boxTypeId,
          preparedBy,
          now,
        );

        // إنشاء الكرتونات الجاهزة
        for (int i = 0; i < quantity; i++) {
          await txn.insert('ready_boxes', {
            'box_type_id': boxTypeId,
            'status': 'ready',
            'prepared_by': preparedBy,
            'prepared_at': now,
            'distribution_date': null,
            'distributed_to': null,
            'notes': null,
            'created_at': now,
          });
        }

        // تسجيل سجل التجهيز
        await txn.insert('box_preparation_logs', {
          'box_type_id': boxTypeId,
          'quantity': quantity,
          'prepared_by': preparedBy,
          'prepared_at': now,
          'created_at': now,
        });

        print('✅ تم تجهيز $quantity كرتون بنجاح');
        return quantity;
      });
    } catch (e) {
      print('❌ خطأ في تجهيز الكرتونات: $e');
      rethrow;
    }
  }

  // دالة مساعدة للحصول على المحتويات داخل transaction
  Future<List<Map<String, dynamic>>> _getBoxTypeContentsForTransaction(
    Transaction txn,
    int boxTypeId,
  ) async {
    // تأكد من أن الأعمدة موجودة بالاسم الصحيح
    return await txn.rawQuery(
      '''
    SELECT 
      bci.*,
      ii.item_name,
      ii.unit,
      ii.current_quantity,
      ii.id as item_id
    FROM box_type_contents bci
    INNER JOIN inventory_items ii ON bci.item_id = ii.id
    WHERE bci.box_type_id = ?
  ''',
      [boxTypeId],
    );
  }

  // دالة مساعدة لتحديث المخزون
  // داخل DatabaseHelper
  Future<void> _updateInventoryForBoxPreparation(
    Transaction txn,
    List<Map<String, dynamic>> boxContents,
    int quantity,
    int boxTypeId,
    String preparedBy,
    String timestamp,
  ) async {
    for (var content in boxContents) {
      final requiredQuantity = (content['quantity'] ?? 0) * quantity;
      final newQuantity = (content['current_quantity'] ?? 0) - requiredQuantity;

      // تحديث كمية المخزون
      await txn.update(
        'inventory_items',
        {'current_quantity': newQuantity, 'updated_at': timestamp},
        where: 'id = ?',
        whereArgs: [content['item_id']],
      );

      // تسجيل المعاملة في جدول inventory_transactions بالهيكل الصحيح
      await txn.insert('inventory_transactions', {
        'item_id': content['item_id'],
        'transaction_type': 'خروج', // مطابق لقيم CHECK
        'quantity_change': -requiredQuantity, // قيمة سالبة للخروج
        'box_id': null, // لا يوجد box_id محدد
        'related_entity_type': 'أخرى', // قيمة افتراضية
        'related_entity_id':
            boxTypeId, // نستخدم box_type_id كـ related_entity_id
        'notes': 'تجهيز كرتون - $preparedBy', // ملاحظات
        'performed_by': preparedBy, // اسم المجهز
        'transaction_date': timestamp, // تاريخ المعاملة
      });
    }
  }

  // أضف هذه الدالة في DatabaseHelper
  Future<String> generateBoxNumber(int boxTypeId, int sequence) async {
    final db = await database;

    // جلب اختصار نوع الكرتون (يمكن إضافة حقل code في box_types)
    final typeInfo = await db.query(
      'box_types',
      where: 'id = ?',
      whereArgs: [boxTypeId],
    );

    String typeCode = 'BOX';
    if (typeInfo.isNotEmpty) {
      // استخدم أول 3 أحرف من اسم النوع ككود
      typeCode = (typeInfo.first['type_name'] as String)
          .substring(0, 3)
          .toUpperCase();
    }

    // تاريخ اليوم
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    // رقم التسلسل
    final seqStr = sequence.toString().padLeft(4, '0');

    return '$typeCode-$dateStr-$seqStr';
  }

  // أضف هذا في _PrepareBoxesScreenState
  Future<void> _diagnoseAndFix(context) async {
    try {
      final dbHelper = DatabaseHelper();

      // التحقق من هيكل الجدول
      await dbHelper.checkInventoryTransactionsStructure();

      // اختبار إدخال بسيط
      final db = await dbHelper.database;
      final testInsert = await db.insert('inventory_transactions', {
        'item_id': 1,
        'transaction_type': 'خروج',
        'quantity_change': -5,
        'box_id': null,
        'related_entity_type': 'أخرى',
        'related_entity_id': 1,
        'notes': 'اختبار',
        'performed_by': 'system',
        'transaction_date': DateTime.now().toIso8601String(),
      });

      print('✅ اختبار الإدخال نجح: $testInsert');

      // حذف بيانات الاختبار
      await db.delete(
        'inventory_transactions',
        where: 'id = ?',
        whereArgs: [testInsert],
      );
    } catch (e) {
      print('❌ خطأ في التشخيص: $e');

      // عرض رسالة خطأ للمستخدم
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في قاعدة البيانات: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> checkInventoryTransactionsStructure() async {
    final db = await database;

    try {
      // التحقق من أعمدة جدول inventory_transactions
      final tableInfo = await db.rawQuery(
        'PRAGMA table_info(inventory_transactions)',
      );
      print('📊 هيكل جدول inventory_transactions:');
      for (var column in tableInfo) {
        print('  - ${column['name']} (${column['type']})');
      }

      // التحقق من قيود CHECK
      // هذا للتأكد من أن transaction_type تقبل 'خروج'
      final checkConstraints = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name='inventory_transactions'",
      );
      print('📝 SQL الأصلي للجدول:');
      print(checkConstraints);
    } catch (e) {
      print('❌ خطأ في التحقق من الجدول: $e');
    }
  }

  // دالة مساعدة لإنشاء الكرتونات الجاهزة
  Future<void> _createReadyBoxes(
    Transaction txn,
    int boxTypeId,
    int quantity,
    String preparedBy,
    String timestamp,
  ) async {
    for (int i = 0; i < quantity; i++) {
      await txn.insert('ready_boxes', {
        'box_type_id': boxTypeId,
        'status': 'ready',
        'prepared_by': preparedBy,
        'prepared_at': timestamp,
        'distribution_date': null,
        'distributed_to': null,
        'notes': null,
        'created_at': timestamp,
      });
    }
  }

  // دالة مساعدة لتسجيل التجهيز
  Future<void> _logBoxPreparation(
    Transaction txn,
    int boxTypeId,
    int quantity,
    String preparedBy,
    String timestamp,
  ) async {
    await txn.insert('box_preparation_logs', {
      'box_type_id': boxTypeId,
      'quantity': quantity,
      'prepared_by': preparedBy,
      'prepared_at': timestamp,
      'created_at': timestamp,
    });
  }

  // طريقة بديلة باستخدام معاملة منفصلة لكل عملية
  Future<int> prepareBoxesSequential(
    int boxTypeId,
    int quantity,
    String preparedBy,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    try {
      // التحقق من المخزون أولاً
      final boxContents = await getBoxTypeContents(boxTypeId);

      for (var content in boxContents) {
        final requiredQuantity = (content['quantity'] ?? 0) * quantity;
        final currentQuantity = content['current_quantity'] ?? 0;

        if (requiredQuantity > currentQuantity) {
          throw Exception('غير كافي ${content['item_name']}');
        }
      }

      // تنفيذ العمليات في معاملة واحدة
      return await db.transaction<int>((txn) async {
        // تحديث المخزون
        for (var content in boxContents) {
          final requiredQuantity = (content['quantity'] ?? 0) * quantity;

          await txn.update(
            'inventory_items',
            {
              'current_quantity':
                  content['current_quantity'] - requiredQuantity,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [content['id']],
          );
        }

        // تسجيل الحركات
        for (var content in boxContents) {
          final requiredQuantity = (content['quantity'] ?? 0) * quantity;

          await txn.insert('inventory_transactions', {
            'item_id': content['id'],
            'transaction_type': 'withdrawal',
            'quantity': requiredQuantity,
            'reason': 'تجهيز كرتون - $preparedBy',
            'box_type_id': boxTypeId,
            'created_at': now,
          });
        }

        // إنشاء الكرتونات
        for (int i = 0; i < quantity; i++) {
          await txn.insert('ready_boxes', {
            'box_type_id': boxTypeId,
            'status': 'ready',
            'prepared_by': preparedBy,
            'prepared_at': now,
            'distribution_date': null,
            'distributed_to': null,
            'notes': null,
            'created_at': now,
          });
        }

        // تسجيل العملية
        await txn.insert('box_preparation_logs', {
          'box_type_id': boxTypeId,
          'quantity': quantity,
          'prepared_by': preparedBy,
          'prepared_at': now,
          'created_at': now,
        });

        return quantity;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<int> distributeBox(
    int boxId,
    String distributedTo,
    String notes,
  ) async {
    final db = await database;
    return await db.update(
      'boxes',
      {
        'status': 'مستلم',
        'distributed_to': distributedTo,
        'distributed_date': DateTime.now().toIso8601String(),
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [boxId],
    );
  }

  // ================== دوال الربط بين المساعدات والكرتونات ==================
  Future<List<Map<String, dynamic>>> getBoxesByAid(int aidId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT b.*, bt.type_name 
    FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    JOIN individual_aids ia ON b.id = ia.box_id
    WHERE ia.aid_id = ?
  ''',
      [aidId],
    );
  }

  Future<void> linkBoxToAid(int aidId, int boxId) async {
    final db = await database;
    // تحديث جدول individual_aids ليحتوي على box_id
    // قد تحتاج لتعديل الجدول أولاً
    await db.rawInsert(
      '''
    INSERT OR REPLACE INTO aid_boxes (aid_id, box_id, distribution_date)
    VALUES (?, ?, ?)
  ''',
      [aidId, boxId, DateTime.now().toIso8601String()],
    );
  }

  Future<void> unlinkBoxFromAid(int aidId, int boxId) async {
    final db = await database;
    await db.delete(
      'aid_boxes',
      where: 'aid_id = ? AND box_id = ?',
      whereArgs: [aidId, boxId],
    );
  }

  // دوال إضافية لإدارة محتويات الكرتونات
  Future<List<Map<String, dynamic>>> getBoxContents(int boxId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT i.*, bc.quantity
    FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    JOIN box_type_contents bc ON bt.id = bc.box_type_id
    JOIN inventory_items i ON bc.item_id = i.id
    WHERE b.id = ?
  ''',
      [boxId],
    );
  }

  Future<void> addBoxItem(int boxId, int itemId, int quantity) async {
    final db = await database;
    // تحتاج لإنشاء جدول box_items إذا كان كل كرتون له محتويات خاصة به
    // أو استخدام جدول box_type_contents إذا كانت المحتويات موحدة حسب النوع
    await db.insert('box_type_contents', {
      'box_type_id': boxId,
      'item_id': itemId,
      'quantity': quantity,
    });
  }

  // دوال خاصة بالتوزيع
  Future<void> linkBoxToDistribution(int distributionId, int boxId) async {
    final db = await database;
    // تأكد من وجود جدول distribution_boxes
    await db.insert('aid_boxes', {
      'aid_id': distributionId,
      'box_id': boxId,
      'distribution_date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getDistributionBoxes(
    int distributionId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT b.*, bt.type_name 
    FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    JOIN aid_boxes ab ON b.id = ab.box_id
    WHERE ab.aid_id = ?
  ''',
      [distributionId],
    );
  }

  Future<int> distributeMultipleBoxes(
    List<int> boxIds,
    String recipient,
    String notes,
  ) async {
    final db = await database;
    int count = 0;

    await db.transaction((txn) async {
      for (var boxId in boxIds) {
        await txn.update(
          'boxes',
          {
            'status': 'مستلم',
            'distributed_to': recipient,
            'distributed_date': DateTime.now().toIso8601String(),
            'notes': notes,
          },
          where: 'id = ?',
          whereArgs: [boxId],
        );
        count++;
      }
    });

    return count;
  }

  Future<void> removeBoxItem(int boxTypeId, int itemId) async {
    final db = await database;
    await db.delete(
      'box_type_contents',
      where: 'box_type_id = ? AND item_id = ?',
      whereArgs: [boxTypeId, itemId],
    );
  }

  // دوال جلب البيانات المرتبطة
  Future<List<Map<String, dynamic>>> getBoxesWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT b.*, bt.type_name, bt.description as type_description,
           (SELECT COUNT(*) FROM box_type_contents bc WHERE bc.box_type_id = bt.id) as item_count
    FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    ORDER BY b.prepared_date DESC
  ''');
  }

  Future<List<Map<String, dynamic>>> getInventoryItemsWithCategory() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT i.*, 
           (SELECT COUNT(*) FROM box_type_contents bc WHERE bc.item_id = i.id) as used_in_box_types,
           (SELECT SUM(quantity) FROM box_type_contents bc WHERE bc.item_id = i.id) as total_required_in_boxes
    FROM inventory_items i
    ORDER BY i.item_name
  ''');
  }

  Future<List<Map<String, dynamic>>> searchItems(String query) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT * FROM inventory_items 
    WHERE item_name LIKE ? OR category LIKE ? OR notes LIKE ?
    ORDER BY item_name
  ''',
      ['%$query%', '%$query%', '%$query%'],
    );
  }

  Future<List<Map<String, dynamic>>> searchBoxes(String query) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT b.*, bt.type_name FROM boxes b
    JOIN box_types bt ON b.box_type_id = bt.id
    WHERE b.box_number LIKE ? OR bt.type_name LIKE ? OR b.distributed_to LIKE ?
    ORDER BY b.prepared_date DESC
  ''',
      ['%$query%', '%$query%', '%$query%'],
    );
  }

  // ================== دوال المخازن ==================
  Future<int> insertWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    return await db.insert('warehouses', warehouse);
  }

  Future<List<Map<String, dynamic>>> getAllWarehouses() async {
    final db = await database;
    return await db.query('warehouses');
  }

  Future<void> transferStock(
    int itemId,
    int fromWarehouseId,
    int toWarehouseId,
    int quantity,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // خصم من المخزن المصدر
      await txn.rawUpdate(
        '''
      UPDATE warehouse_stock 
      SET quantity = quantity - ?
      WHERE warehouse_id = ? AND item_id = ?
    ''',
        [quantity, fromWarehouseId, itemId],
      );

      // إضافة إلى المخزن الهدف
      await txn.rawUpdate(
        '''
      INSERT OR REPLACE INTO warehouse_stock (warehouse_id, item_id, quantity, last_updated)
      VALUES (?, ?, COALESCE((SELECT quantity FROM warehouse_stock WHERE warehouse_id = ? AND item_id = ?), 0) + ?, ?)
    ''',
        [
          toWarehouseId,
          itemId,
          toWarehouseId,
          itemId,
          quantity,
          DateTime.now().toIso8601String(),
        ],
      );
    });
  }

  // ================== دالة لإنشاء الجداول الجديدة في الترقية ==================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // الترقيات القديمة
    }

    if (oldVersion < 4) {
      // إنشاء جداول المخزون الجديدة
      await db.execute('''
      CREATE TABLE box_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

      await db.execute('''
      CREATE TABLE inventory_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        category TEXT CHECK(category IN ('طعام', 'ملابس', 'أدوات', 'طقسي', 'تعليمي', 'صحي', 'أخرى')),
        unit TEXT NOT NULL,
        min_quantity INTEGER DEFAULT 0,
        current_quantity INTEGER DEFAULT 0,
                storage_unit INTEGER DEFAULT 0,
        location TEXT,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

      await db.execute('''
      CREATE TABLE box_type_contents (
        box_type_id INTEGER,
        item_id INTEGER,
        quantity INTEGER NOT NULL,
        PRIMARY KEY (box_type_id, item_id),
        FOREIGN KEY (box_type_id) REFERENCES box_types (id),
        FOREIGN KEY (item_id) REFERENCES inventory_items (id)
      )
    ''');

      await db.execute('''
      CREATE TABLE boxes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        box_number TEXT UNIQUE NOT NULL,
        box_type_id INTEGER NOT NULL,
        status TEXT CHECK(status IN ('جاهز', 'مستلم', 'تالف', 'مفقود')) DEFAULT 'جاهز',
        prepared_by TEXT,
        prepared_date TEXT,
        distributed_to TEXT,
        distributed_date TEXT,
        qr_code TEXT,
        notes TEXT,
        FOREIGN KEY (box_type_id) REFERENCES box_types (id)
      )
    ''');

      await db.execute('''
      CREATE TABLE inventory_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_type TEXT CHECK(transaction_type IN ('دخول', 'خروج', 'تجهيز', 'تعديل', 'تلف')),
        item_id INTEGER,
        quantity_change INTEGER NOT NULL,
        box_id INTEGER,
        related_entity_type TEXT CHECK(related_entity_type IN ('تبرع', 'خدمة', 'إغاثة', 'عائلة', 'فرد', 'أخرى')),
        related_entity_id INTEGER,
        notes TEXT,
        performed_by TEXT,
        transaction_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (item_id) REFERENCES inventory_items (id),
        FOREIGN KEY (box_id) REFERENCES boxes (id)
      )
    ''');

      // إضافة أعمدة جديدة لجدول aids
      await db.execute(
        'ALTER TABLE aids ADD COLUMN is_material_aid INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE aids ADD COLUMN box_type_id INTEGER');
      await db.execute(
        'ALTER TABLE aids ADD COLUMN quantity_needed INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE aids ADD COLUMN quantity_provided INTEGER DEFAULT 0',
      );

      // إنشاء جدول ربط المساعدات بالكرتونات
      await db.execute('''
      CREATE TABLE aid_boxes (
        aid_id INTEGER,
        box_id INTEGER,
        distribution_date TEXT,
        PRIMARY KEY (aid_id, box_id),
        FOREIGN KEY (aid_id) REFERENCES aids (id),
        FOREIGN KEY (box_id) REFERENCES boxes (id)
      )
    ''');
    }
  }
}
