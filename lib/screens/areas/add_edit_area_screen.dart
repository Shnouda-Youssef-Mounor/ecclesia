import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class AddEditAreaScreen extends StatefulWidget {
  final Map<String, dynamic>? area;

  const AddEditAreaScreen({super.key, this.area});

  @override
  State<AddEditAreaScreen> createState() => _AddEditAreaScreenState();
}

class _AddEditAreaScreenState extends State<AddEditAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  
  final _areaNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.area != null) {
      _loadAreaData();
    }
  }

  void _loadAreaData() {
    final area = widget.area!;
    _areaNameController.text = area['area_name'] ?? '';
    _descriptionController.text = area['area_description'] ?? '';
  }

  Future<void> _saveArea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'area_name': _areaNameController.text,
      'area_description': _descriptionController.text,
    };

    try {
      if (widget.area == null) {
        await _db.insertArea(data);
      } else {
        await _db.updateArea(widget.area!['id'], data);
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
          title: Text(widget.area == null ? 'إضافة منطقة' : 'تعديل منطقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                    _buildTextField(_areaNameController, 'اسم المنطقة', Icons.location_on, required: true),
                    const SizedBox(height: 16),
                    _buildTextField(_descriptionController, 'وصف المنطقة', Icons.description, maxLines: 3),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveArea,
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