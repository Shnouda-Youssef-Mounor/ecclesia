import 'dart:io';
import 'package:ecclesia/helpers/cache_helper.dart';
import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;


class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String backupFrequency = CacheHelper.getString('backup_frequency') ?? 'يوميًا';
  String? lastBackupDate = CacheHelper.getString('last_backup_date');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.light.withOpacity(0.95),
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Text(
            'الإعدادات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 3,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 🔹 Backup Settings Card
              _buildSectionCard(
                title: 'إعدادات النسخ الاحتياطي',
                icon: Icons.backup,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'تكرار النسخ الاحتياطي:',
                        style: GoogleFonts.cairo(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: backupFrequency,
                    dropdownColor: Colors.white,
                    iconEnabledColor: AppColors.secondary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.light.withOpacity(0.4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: ['يوميًا', 'أسبوعيًا', 'شهريًا']
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value, style: GoogleFonts.cairo(color: AppColors.secondary)),
                            ))
                        .toList(),
                    onChanged: (newValue) async {
                      setState(() => backupFrequency = newValue!);
                      await CacheHelper.saveString('backup_frequency', backupFrequency);
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.history, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'آخر نسخة احتياطية: ${_formatBackupDate(lastBackupDate)}',
                          style: GoogleFonts.cairo(fontSize: 14, color: AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.cloud_upload),
                          label: Text('نسخ احتياطي الآن', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            try {
                              String backupPath = await DatabaseHelper().backupDatabase();
                              await CacheHelper.saveString('last_backup_path', backupPath);
                              await CacheHelper.saveString('last_backup_date', DateTime.now().toIso8601String());
                              setState(() => lastBackupDate = DateTime.now().toIso8601String());
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تم النسخ الاحتياطي بنجاح إلى:\n$backupPath')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل النسخ الاحتياطي: $e')),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.restore),
                          label: Text('استعادة البيانات', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: () async {
                            try {
                              await DatabaseHelper().restoreDatabase();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تم استعادة البيانات بنجاح')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل في استعادة البيانات: $e')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 24),

              // 🔹 Logout Card
              _buildSectionCard(
                title: 'الحساب',
                icon: Icons.person,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.logout),
                    label: Text('تسجيل الخروج', style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      await CacheHelper.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(icon, color: AppColors.primary),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          Divider(height: 24, thickness: 1, color: AppColors.light.withOpacity(0.6)),
          ...children,
        ],
      ),
    );
  }
  String _formatBackupDate(String? isoDate) {
  if (isoDate == null) return 'لا يوجد';
  try {
    DateTime date = DateTime.parse(isoDate);
    return DateFormat ('d MMMM yyyy - hh:mm a', 'ar').format(date);
  } catch (e) {
    return 'تنسيق غير معروف';
  }
}
}
