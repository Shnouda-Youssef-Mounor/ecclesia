import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class AddEditFamilyScreen extends StatefulWidget {
  final Map<String, dynamic>? family;

  const AddEditFamilyScreen({super.key, this.family});

  @override
  State<AddEditFamilyScreen> createState() => _AddEditFamilyScreenState();
}

class _AddEditFamilyScreenState extends State<AddEditFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  
  final _familyNameController = TextEditingController();
  final _addressController = TextEditingController();
  
  int? _fatherId;
  int? _motherId;
  int? _selectedAreaId;
  List<Map<String, dynamic>> _individuals = [];
  List<Map<String, dynamic>> _areas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.family != null) {
      _loadFamilyData();
    }
  }

  Future<void> _loadData() async {
    _individuals = await _db.getAllIndividuals();
    _areas = await _db.getAllAreas();
    setState(() {});
  }



  void _loadFamilyData() {
    final family = widget.family!;
    _familyNameController.text = family['family_name'] ?? '';
    _addressController.text = family['family_address'] ?? '';
    _fatherId = family['father_id'];
    _motherId = family['mother_id'];
    _selectedAreaId = family['area_id'];
  }

  Future<void> _saveFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'family_name': _familyNameController.text,
      'family_address': _addressController.text,
      'area_id': _selectedAreaId,
      'father_id': _fatherId,
      'mother_id': _motherId,
    };

    try {
      if (widget.family == null) {
        await _db.insertFamily(data);
      } else {
        await _db.updateFamily(widget.family!['id'], data);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
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
          title: Text(
            widget.family == null ? 'إضافة أسرة' : 'تعديل أسرة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
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
                    _buildTextField(_familyNameController, 'اسم الأسرة', required: true),
                    const SizedBox(height: 16),
                    _buildTextField(_addressController, 'عنوان الأسرة'),
                    const SizedBox(height: 16),
                    _buildAreaDropdown(),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'الأب',
                      _fatherId,
                      _individuals.where((i) => i['gender'] == 'ذكر').toList(),
                      (value) => setState(() => _fatherId = value),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'الأم',
                      _motherId,
                      _individuals.where((i) => i['gender'] == 'أنثى').toList(),
                      (value) => setState(() => _motherId = value),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveFamily,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'حفظ',
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
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

  Widget _buildTextField(TextEditingController controller, String label, {bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: GoogleFonts.cairo(),
      validator: required ? (value) => value?.isEmpty == true ? 'هذا الحقل مطلوب' : null : null,
    );
  }

  Widget _buildDropdown(String label, int? value, List<Map<String, dynamic>> items, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text('اختر $label', style: GoogleFonts.cairo()),
        ),
        ...items.map((item) => DropdownMenuItem<int>(
          value: item['id'],
          child: Text(item['full_name'] ?? '', style: GoogleFonts.cairo()),
        )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildAreaDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedAreaId,
      decoration: InputDecoration(
        labelText: 'المنطقة',
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text('اختر المنطقة', style: GoogleFonts.cairo()),
        ),
        ..._areas.map((area) => DropdownMenuItem<int>(
          value: area['id'],
          child: Text(area['area_name'] ?? '', style: GoogleFonts.cairo()),
        )),
      ],
      onChanged: (value) => setState(() => _selectedAreaId = value),
    );
  }
}