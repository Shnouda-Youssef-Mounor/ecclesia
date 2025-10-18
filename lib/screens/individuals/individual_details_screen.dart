import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class IndividualDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> individual;

  const IndividualDetailsScreen({super.key, required this.individual});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تفاصيل الفرد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        individual['full_name'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoGrid(isDesktop),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(bool isDesktop) {
    final fields = [
      {'label': 'الرقم القومي', 'value': individual['national_id']},
      {'label': 'المحافظة', 'value': individual['governorate']},
      {'label': 'تاريخ الميلاد', 'value': individual['birth_date']},
      {'label': 'النوع', 'value': individual['gender']},
      {'label': 'الحالة الاجتماعية', 'value': individual['marital_status']},
      {'label': 'موقف التجنيد', 'value': individual['military_status']},
      {'label': 'المنطقة', 'value': individual['area']},
      {'label': 'العنوان الحالي', 'value': individual['current_address']},
      {'label': 'رقم الهاتف', 'value': individual['phone']},
      {'label': 'رقم الواتساب', 'value': individual['whatsapp']},
      {'label': 'العائلة', 'value': individual['family_name']},
      {'label': 'جهة التعليم', 'value': individual['education_institution']},
    ];

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: fields.length,
        itemBuilder: (context, index) => _buildInfoCard(fields[index]),
      );
    } else {
      return Column(
        children: fields.map((field) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildInfoCard(field),
        )).toList(),
      );
    }
  }

  Widget _buildInfoCard(Map<String, dynamic> field) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            field['label'],
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            field['value']?.toString() ?? 'غير محدد',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}