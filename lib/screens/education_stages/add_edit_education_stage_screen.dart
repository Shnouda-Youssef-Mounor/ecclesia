import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class AddEditEducationStageScreen extends StatefulWidget {
  final Map<String, dynamic>? stage;

  const AddEditEducationStageScreen({super.key, this.stage});

  @override
  State<AddEditEducationStageScreen> createState() => _AddEditEducationStageScreenState();
}

class _AddEditEducationStageScreenState extends State<AddEditEducationStageScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  
  final _stageNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.stage != null) {
      _loadStageData();
    }
  }

  void _loadStageData() {
    final stage = widget.stage!;
    _stageNameController.text = stage['stage_name'] ?? '';
  }

  Future<void> _saveStage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'stage_name': _stageNameController.text,
    };

    try {
      if (widget.stage == null) {
        await _db.insertEducationStage(data);
      } else {
        await _db.updateEducationStage(widget.stage!['id'], data);
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
          title: Text(widget.stage == null ? 'إضافة مرحلة تعليمية' : 'تعديل مرحلة تعليمية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: TextFormField(
                        controller: _stageNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم المرحلة التعليمية',
                          labelStyle: GoogleFonts.cairo(color: AppColors.secondary),
                          prefixIcon: Icon(Icons.school, color: AppColors.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        style: GoogleFonts.cairo(),
                        validator: (value) => value?.isEmpty == true ? 'هذا الحقل مطلوب' : null,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveStage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
}