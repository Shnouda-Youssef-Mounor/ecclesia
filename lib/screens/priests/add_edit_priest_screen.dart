import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../utils/searchable_dropdown.dart';
import '../../helpers/db_helper.dart';

class AddEditPriestScreen extends StatefulWidget {
  final Map<String, dynamic>? priest;

  const AddEditPriestScreen({super.key, this.priest});

  @override
  State<AddEditPriestScreen> createState() => _AddEditPriestScreenState();
}

class _AddEditPriestScreenState extends State<AddEditPriestScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  
  final _priestNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  int? _sectorId;
  List<Map<String, dynamic>> _sectors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSectors();
    if (widget.priest != null) {
      _loadPriestData();
    }
  }

  Future<void> _loadSectors() async {
    _sectors = await _db.getAllSectors();
    setState(() {});
  }

  void _loadPriestData() {
    final priest = widget.priest!;
    _priestNameController.text = priest['priest_name'] ?? '';
    _phoneController.text = priest['phone'] ?? '';
    _sectorId = priest['sector_id'];
  }

  Future<void> _savePriest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'priest_name': _priestNameController.text,
      'phone': _phoneController.text,
      'sector_id': _sectorId,
    };

    try {
      if (widget.priest == null) {
        await _db.insertPriest(data);
      } else {
        await _db.updatePriest(widget.priest!['id'], data);
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
          title: Text(widget.priest == null ? 'إضافة كاهن' : 'تعديل كاهن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                    _buildTextField(_priestNameController, 'اسم الكاهن', Icons.church, required: true),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone),
                    const SizedBox(height: 16),
                    SearchableDropdown<int>(
                      label: 'القطاع المسؤول عنه',
                      value: _sectorId,
                      items: _sectors,
                      displayKey: 'sector_name',
                      valueKey: 'id',
                      onChanged: (value) => setState(() => _sectorId = value),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _savePriest,
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

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool required = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
      child: TextFormField(
        controller: controller,
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

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
      child: DropdownButtonFormField<int>(
        value: _sectorId,
        decoration: InputDecoration(
          labelText: 'القطاع المسؤول عنه',
          labelStyle: GoogleFonts.cairo(color: AppColors.secondary),
          prefixIcon: Icon(Icons.category, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('اختر القطاع', style: GoogleFonts.cairo())),
          ..._sectors.map((sector) => DropdownMenuItem<int>(value: sector['id'], child: Text(sector['sector_name'] ?? '', style: GoogleFonts.cairo()))),
        ],
        onChanged: (value) => setState(() => _sectorId = value),
      ),
    );
  }
}