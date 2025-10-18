import 'db_helper.dart';

class DataSeeder {
  static final DatabaseHelper _db = DatabaseHelper();

  static Future<void> seedData() async {
    await _seedAreas();
    await _seedEducationStages();
    await _seedActivities();
    await _seedAids();
    await _seedPriests();
    await _seedSectors();
    await _seedIndividuals();
    await _seedFamilies();
    await _seedServants();
  }

  static Future<void> _seedAreas() async {
    final areas = [
      {'area_name': 'مصر الجديدة', 'area_description': 'منطقة مصر الجديدة وما حولها'},
      {'area_name': 'الدقي', 'area_description': 'منطقة الدقي والمهندسين'},
      {'area_name': 'مدينة نصر', 'area_description': 'مدينة نصر والمناطق المجاورة'},
      {'area_name': 'شبرا', 'area_description': 'منطقة شبرا وروض الفرج'},
      {'area_name': 'الزيتون', 'area_description': 'منطقة الزيتون وحدائق القبة'},
    ];

    for (var area in areas) {
      await _db.insertArea(area);
    }
  }

  static Future<void> _seedEducationStages() async {
    final stages = [
      {'stage_name': 'ابتدائي'},
      {'stage_name': 'إعدادي'},
      {'stage_name': 'ثانوي'},
      {'stage_name': 'جامعي'},
      {'stage_name': 'دراسات عليا'},
    ];

    for (var stage in stages) {
      await _db.insertEducationStage(stage);
    }
  }

  static Future<void> _seedActivities() async {
    final activities = [
      {'activity_name': 'مدارس الأحد', 'description': 'تعليم ديني للأطفال', 'schedule': 'الأحد 10 صباحاً'},
      {'activity_name': 'اجتماع الشباب', 'description': 'اجتماع أسبوعي للشباب', 'schedule': 'الجمعة 7 مساءً'},
      {'activity_name': 'كورال الكنيسة', 'description': 'ترانيم وألحان', 'schedule': 'الثلاثاء 6 مساءً'},
    ];

    for (var activity in activities) {
      await _db.insertActivity(activity);
    }
  }

  static Future<void> _seedAids() async {
    final aids = [
      {'organization_name': 'جمعية الخير', 'description': 'مساعدات مالية', 'schedule': 'شهرياً'},
      {'organization_name': 'بنك الطعام', 'description': 'توزيع مواد غذائية', 'schedule': 'أسبوعياً'},
    ];

    for (var aid in aids) {
      await _db.insertAid(aid);
    }
  }

  static Future<void> _seedPriests() async {
    final priests = [
      {'priest_name': 'الأنبا يوحنا', 'phone': '01234567890'},
      {'priest_name': 'القس مرقس', 'phone': '01234567891'},
    ];

    for (var priest in priests) {
      await _db.insertPriest(priest);
    }
  }

  static Future<void> _seedSectors() async {
    final sectors = [
      {'sector_name': 'قطاع الأطفال', 'meeting_time': 'الأحد 10 صباحاً'},
      {'sector_name': 'قطاع الشباب', 'meeting_time': 'الجمعة 7 مساءً'},
      {'sector_name': 'قطاع الخدمة', 'meeting_time': 'الثلاثاء 6 مساءً'},
    ];

    for (var sector in sectors) {
      await _db.insertSector(sector);
    }
  }

  static Future<void> _seedIndividuals() async {
    final individuals = [
      {
        'full_name': 'مينا جرجس عبد الملك فهيم',
        'national_id': '29012011234567',
        'governorate': 'القاهرة',
        'birth_date': '01/01/1990',
        'gender': 'ذكر',
        'marital_status': 'متزوج',
        'military_status': 'أدى الخدمة',
        'area_id': 1,
        'area': 'مصر الجديدة',
        'current_address': 'شارع الحجاز، مصر الجديدة',
        'phone': '01234567890',
        'whatsapp': '01234567890',
        'family_name': 'عائلة فهيم',
        'education_stage_id': 4,
        'education_institution': 'جامعة القاهرة - كلية الهندسة'
      },
      {
        'full_name': 'مريم بولس إبراهيم عبد الملك',
        'national_id': '29512021234568',
        'governorate': 'الجيزة',
        'birth_date': '15/05/1992',
        'gender': 'أنثى',
        'marital_status': 'متزوجة',
        'spouse_id': 1,
        'area_id': 2,
        'area': 'الدقي',
        'current_address': 'شارع التحرير، الدقي',
        'phone': '01234567891',
        'whatsapp': '01234567891',
        'family_name': 'عائلة فهيم',
        'education_stage_id': 4,
        'education_institution': 'جامعة القاهرة - كلية الطب'
      },
      {
        'full_name': 'كيرلس مينا جرجس فهيم',
        'national_id': '31203151234569',
        'governorate': 'القاهرة',
        'birth_date': '20/03/2015',
        'gender': 'ذكر',
        'marital_status': 'أعزب',
        'area_id': 1,
        'area': 'مصر الجديدة',
        'current_address': 'شارع الحجاز، مصر الجديدة',
        'phone': '',
        'whatsapp': '',
        'family_name': 'عائلة فهيم',
        'education_stage_id': 1,
        'education_institution': 'مدرسة الأنبا أنطونيوس الابتدائية'
      }
    ];

    for (var individual in individuals) {
      await _db.insertIndividual(individual);
    }
  }

  static Future<void> _seedFamilies() async {
    final families = [
      {
        'family_name': 'عائلة فهيم',
        'family_address': 'شارع الحجاز، مصر الجديدة',
        'area_id': 1,
        'father_id': 1,
        'mother_id': 2
      }
    ];

    for (var family in families) {
      await _db.insertFamily(family);
    }
  }

  static Future<void> _seedServants() async {
    final servants = [
      {
        'individual_id': 1,
        'confession_father_id': 1,
        'sector_id': 2
      }
    ];

    for (var servant in servants) {
      await _db.insertServant(servant);
    }
  }
}