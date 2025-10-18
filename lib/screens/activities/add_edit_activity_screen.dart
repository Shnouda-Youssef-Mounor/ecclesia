import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class AddEditActivityScreen extends StatefulWidget {
  final Map<String, dynamic>? activity;

  const AddEditActivityScreen({super.key, this.activity});

  @override
  State<AddEditActivityScreen> createState() => _AddEditActivityScreenState();
}

class _AddEditActivityScreenState extends State<AddEditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  
  final _activityNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scheduleController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activity != null) {
      _loadActivityData();
    }
  }

  void _loadActivityData() {
    final activity = widget.activity!;
    _activityNameController.text = activity['activity_name'] ?? '';
    _descriptionController.text = activity['description'] ?? '';
    _scheduleController.text = activity['schedule'] ?? '';
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'activity_name': _activityNameController.text,
      'description': _descriptionController.text,
      'schedule': _scheduleController.text,
    };

    try {
      if (widget.activity == null) {
        await _db.insertActivity(data);
      } else {
        await _db.updateActivity(widget.activity!['id'], data);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.activity == null ? 'إضافة نشاط' : 'تعديل نشاط', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 600 : double.infinity),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_activityNameController, 'اسم النشاط', Icons.event, required: true),
                    const SizedBox(height: 16),
                    _buildTextField(_descriptionController, 'الوصف', Icons.description, maxLines: 3),
                    const SizedBox(height: 16),
                    _buildTextField(_scheduleController, 'المواعيد', Icons.schedule),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveActivity,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('حفظ', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: AppColors.secondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.cairo(),
        validator: required ? (value) => value?.isEmpty == true ? 'هذا الحقل مطلوب' : null : null,
      ),
    );
  }
}