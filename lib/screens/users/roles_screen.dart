import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  final List<Map<String, dynamic>> roles = const [
    {
      'name': 'مدير',
      'value': 'admin',
      'icon': Icons.admin_panel_settings,
      'description': 'صلاحيات كاملة - إضافة وتعديل وحذف جميع البيانات والمستخدمين',
      'permissions': [
        'إدارة المستخدمين والأدوار',
        'إضافة وتعديل وحذف جميع البيانات',
        'عرض جميع التقارير',
        'إعادة تعيين قاعدة البيانات',
      ],
    },
    {
      'name': 'محرر',
      'value': 'editor',
      'icon': Icons.edit,
      'description': 'صلاحيات التعديل - إضافة وتعديل البيانات فقط',
      'permissions': [
        'إضافة وتعديل بيانات الأفراد والأسر',
        'إضافة وتعديل القطاعات والخدام',
        'إضافة وتعديل الأنشطة والمساعدات',
        'عرض التقارير الأساسية',
      ],
    },
    {
      'name': 'مشاهد',
      'value': 'viewer',
      'icon': Icons.visibility,
      'description': 'صلاحيات المشاهدة - عرض البيانات فقط',
      'permissions': [
        'عرض بيانات الأفراد والأسر',
        'عرض القطاعات والخدام',
        'عرض الأنشطة والمساعدات',
        'طباعة التقارير الأساسية',
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الأدوار والصلاحيات', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (context, index) => _buildRoleCard(roles[index]),
        ),
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    role['icon'],
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role['name'],
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        role['value'],
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              role['description'],
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'الصلاحيات:',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            ...role['permissions'].map<Widget>((permission) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      permission,
                      style: GoogleFonts.cairo(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}