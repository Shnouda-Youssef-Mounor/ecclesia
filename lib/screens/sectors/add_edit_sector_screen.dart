import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class AddEditSectorScreen extends StatefulWidget {
  final Map<String, dynamic>? sector;

  const AddEditSectorScreen({super.key, this.sector});

  @override
  State<AddEditSectorScreen> createState() => _AddEditSectorScreenState();
}

class _AddEditSectorScreenState extends State<AddEditSectorScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();
  
  final _sectorNameController = TextEditingController();
  final _meetingTimeController = TextEditingController();
  
  int? _responsibleId;
  List<Map<String, dynamic>> _servants = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServants();
    if (widget.sector != null) {
      _loadSectorData();
    }
  }

  Future<void> _loadServants() async {
    final servants = await _db.getAllServants();
    final individuals = await _db.getAllIndividuals();
    
    _servants = servants.map((servant) {
      final individual = individuals.firstWhere((i) => i['id'] == servant['individual_id'], orElse: () => {});
      return {...servant, ...individual};
    }).toList();
    
    setState(() {});
  }

  void _loadSectorData() {
    final sector = widget.sector!;
    _sectorNameController.text = sector['sector_name'] ?? '';
    _meetingTimeController.text = sector['meeting_time'] ?? '';
    _responsibleId = sector['responsible_id'];
  }

  Future<void> _saveSector() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'sector_name': _sectorNameController.text,
      'meeting_time': _meetingTimeController.text,
      'responsible_id': _responsibleId,
    };

    try {
      if (widget.sector == null) {
        await _db.insertSector(data);
      } else {
        await _db.updateSector(widget.sector!['id'], data);
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
          title: Text(widget.sector == null ? 'إضافة قطاع' : 'تعديل قطاع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                    _buildTextField(_sectorNameController, 'اسم القطاع', Icons.category, required: true),
                    const SizedBox(height: 16),
                    _buildTextField(_meetingTimeController, 'موعد الاجتماع', Icons.schedule),
                    const SizedBox(height: 16),
                    _buildDropdown(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSector,
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
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
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
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<int>(
        value: _responsibleId,
        decoration: InputDecoration(
          labelText: 'مسؤول القطاع',
          labelStyle: GoogleFonts.cairo(color: AppColors.secondary),
          prefixIcon: Icon(Icons.person_pin, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: [
          DropdownMenuItem<int>(value: null, child: Text('اختر مسؤول القطاع', style: GoogleFonts.cairo())),
          ..._servants.map((servant) => DropdownMenuItem<int>(value: servant['id'], child: Text(servant['full_name'] ?? '', style: GoogleFonts.cairo()))),
        ],
        onChanged: (value) => setState(() => _responsibleId = value),
      ),
    );
  }
}