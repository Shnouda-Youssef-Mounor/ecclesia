class NationalIdUtils {
  static Map<String, String?> extractInfoFromNationalId(String nationalId) {
    if (nationalId.length != 14) {
      return {
        'birth_date': null,
        'governorate': null,
        'gender': null,
      };
    }

    try {
      // استخراج تاريخ الميلاد
      String century = nationalId.substring(0, 1);
      String year = nationalId.substring(1, 3);
      String month = nationalId.substring(3, 5);
      String day = nationalId.substring(5, 7);

      String fullYear;
      if (century == '2') {
        fullYear = '19$year';
      } else if (century == '3') {
        fullYear = '20$year';
      } else {
        fullYear = '19$year'; // افتراضي
      }

      String birthDate = '$fullYear-$month-$day';

      // استخراج المحافظة
      String governorateCode = nationalId.substring(7, 9);
      String governorate = _getGovernorateFromCode(governorateCode);

      // استخراج النوع
      String genderDigit = nationalId.substring(12, 13);
      String gender = (int.parse(genderDigit) % 2 == 0) ? 'أنثى' : 'ذكر';

      return {
        'birth_date': birthDate,
        'governorate': governorate,
        'gender': gender,
      };
    } catch (e) {
      return {
        'birth_date': null,
        'governorate': null,
        'gender': null,
      };
    }
  }

  static String _getGovernorateFromCode(String code) {
    Map<String, String> governorates = {
      '01': 'القاهرة',
      '02': 'الإسكندرية',
      '03': 'بورسعيد',
      '04': 'السويس',
      '11': 'دمياط',
      '12': 'الدقهلية',
      '13': 'الشرقية',
      '14': 'القليوبية',
      '15': 'كفر الشيخ',
      '16': 'الغربية',
      '17': 'المنوفية',
      '18': 'البحيرة',
      '19': 'الإسماعيلية',
      '21': 'الجيزة',
      '22': 'بني سويف',
      '23': 'الفيوم',
      '24': 'المنيا',
      '25': 'أسيوط',
      '26': 'سوهاج',
      '27': 'قنا',
      '28': 'أسوان',
      '29': 'الأقصر',
      '31': 'البحر الأحمر',
      '32': 'الوادي الجديد',
      '33': 'مطروح',
      '34': 'شمال سيناء',
      '35': 'جنوب سيناء',
      '88': 'خارج الجمهورية',
    };

    return governorates[code] ?? 'غير محدد';
  }
}