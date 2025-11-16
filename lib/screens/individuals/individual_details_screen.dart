import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/db_helper.dart';
import '../../utils/app_colors.dart';

class IndividualDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> individual;

  const IndividualDetailsScreen({super.key, required this.individual});

  @override
  State<IndividualDetailsScreen> createState() =>
      _IndividualDetailsScreenState();
}

class _IndividualDetailsScreenState extends State<IndividualDetailsScreen> {
  String? educationStageName;

  @override
  void initState() {
    super.initState();
    _loadEducationStageName();
  }

  Future<void> _loadEducationStageName() async {
    if (widget.individual['education_stage_name'] != null) {
      educationStageName = widget.individual['education_stage_name'];
    } else if (widget.individual['education_stage_id'] != null) {
      final db = DatabaseHelper();
      final stages = await db.getAllEducationStages();
      final stage = stages
          .where((s) => s['id'] == widget.individual['education_stage_id'])
          .firstOrNull;
      educationStageName = stage?['stage_name'];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    print('Individual data: ${widget.individual}');
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
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : double.infinity,
              ),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.individual['full_name'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoLayout(isDesktop),
                      const SizedBox(height: 32),
                      _buildListSection(
                        'القطاعات',
                        widget.individual['sectors'],
                      ),
                      const SizedBox(height: 16),
                      _buildListSection(
                        'الأنشطة',
                        widget.individual['activities'],
                      ),
                      const SizedBox(height: 16),
                      _buildListSection('المساعدات', widget.individual['aids']),
                      const SizedBox(height: 16),
                      _buildListSection(
                        'العائلات',
                        widget.individual['families'],
                      ),
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

  Widget _buildInfoLayout(bool isDesktop) {
    final fields = [
      {'label': 'الرقم القومي', 'value': widget.individual['national_id']},
      {'label': 'المحافظة', 'value': widget.individual['governorate']},
      {'label': 'تاريخ الميلاد', 'value': widget.individual['birth_date']},
      {'label': 'النوع', 'value': widget.individual['gender']},
      {
        'label': 'الحالة الاجتماعية',
        'value': widget.individual['marital_status'],
      },
      {'label': 'موقف التجنيد', 'value': widget.individual['military_status']},
      {'label': 'المنطقة', 'value': widget.individual['area']},
      {
        'label': 'العنوان الحالي',
        'value': widget.individual['current_address'],
      },
      {'label': 'رقم الهاتف', 'value': widget.individual['phone']},
      {'label': 'رقم الواتساب', 'value': widget.individual['whatsapp']},
      {
        'label': 'مرحلة التعليم',
        'value':
            educationStageName ?? widget.individual['education_stage_name'],
      },
      {
        'label': 'جهة التعليم',
        'value': widget.individual['education_institution'],
      },
      {'label': 'المسمى الوظيفي', 'value': widget.individual['job_title']},
      {'label': 'مكان العمل', 'value': widget.individual['work_place']},
    ];

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildInfoCard(f),
              ),
            )
            .toList(),
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < fields.length; i += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoCard(fields[i])),
                const SizedBox(width: 16),
                if (i + 1 < fields.length)
                  Expanded(child: _buildInfoCard(fields[i + 1]))
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
        ],
      );
    }
  }

  Widget _buildInfoCard(Map<String, dynamic> field) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field['label'],
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (field['value']?.toString().isNotEmpty ?? false)
                ? field['value'].toString()
                : 'غير محدد',
            style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, dynamic listData) {
    if (listData == null || listData.isEmpty) {
      return Text(
        '$title: لا يوجد بيانات',
        style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[700]),
      );
    }

    List items;
    if (listData is List) {
      items = listData;
    } else {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Column(
          children: items.map((item) {
            String display = '';
            if (item is Map && item.containsKey('sector_name')) {
              display = item['sector_name'];
            } else if (item is Map && item.containsKey('activity_name')) {
              display = item['activity_name'];
            } else if (item is Map && item.containsKey('aid_name')) {
              display = item['aid_name'];
            } else if (item is Map && item.containsKey('organization_name')) {
              display = item['organization_name'];
            } else if (item is Map && item.containsKey('family_name')) {
              display = '${item['family_name']} (${item['role'] ?? 'فرد'})';
            } else {
              display = item.toString();
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      display,
                      style: GoogleFonts.cairo(fontSize: 16),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
