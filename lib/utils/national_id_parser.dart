class NationalIdParser {
  static Map<String, String> parseNationalId(String nationalId) {
    if (nationalId.length != 14) {
      return {'error': 'الرقم القومي يجب أن يكون 14 رقم'};
    }

    // استخراج تاريخ الميلاد
    String century = nationalId[0] == '2' ? '19' : '20';
    String year = century + nationalId.substring(1, 3);
    String month = nationalId.substring(3, 5);
    String day = nationalId.substring(5, 7);
    
    // استخراج المحافظة
    String governorateCode = nationalId.substring(7, 9);
    String governorate = _getGovernorate(governorateCode);
    
    // استخراج النوع
    int genderDigit = int.parse(nationalId[12]);
    String gender = genderDigit % 2 == 0 ? 'أنثى' : 'ذكر';
    
    return {
      'birth_date': '$day/$month/$year',
      'governorate': governorate,
      'gender': gender,
    };
  }

  static String _getGovernorate(String code) {
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
    };
    
    return governorates[code] ?? 'غير محدد';
  }
}