import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/db_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/searchable_dropdown.dart';

class AddEditServantScreen extends StatefulWidget {
  final Map<String, dynamic>? servant;

  const AddEditServantScreen({super.key, this.servant});

  @override
  State<AddEditServantScreen> createState() => _AddEditServantScreenState();
}

class _AddEditServantScreenState extends State<AddEditServantScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  int? _individualId;
  int? _confessionFatherId;
  int? _sectorId;

  List<Map<String, dynamic>> _individuals = [];
  List<Map<String, dynamic>> _priests = [];
  List<Map<String, dynamic>> _sectors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.servant != null) {
      _loadServantData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _db.getAllIndividuals(),
        _db.getAllPriests(),
        _db.getAllSectors(),
      ]);

      setState(() {
        _individuals = results[0];
        _priests = results[1];
        _sectors = results[2];
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadServantData() {
    final servant = widget.servant!;
    _individualId = servant['individual_id'];
    _confessionFatherId = servant['confession_father_id'];
    _sectorId = servant['sector_id'];
  }

  Future<void> _saveServant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'individual_id': _individualId,
      'confession_father_id': _confessionFatherId,
      'sector_id': _sectorId,
    };

    try {
      if (widget.servant == null) {
        await _db.insertServant(data);
      } else {
        await _db.updateServant(widget.servant!['id'], data);
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
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
            widget.servant == null ? 'إضافة خادم' : 'تعديل خادم',
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
                maxWidth: isDesktop ? 600 : double.infinity,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SearchableDropdown<int>(
                      label: 'الفرد',
                      value: _individualId,
                      items: _individuals,
                      displayKey: 'full_name',
                      valueKey: 'id',
                      onChanged: (value) =>
                          setState(() => _individualId = value),
                    ),
                    const SizedBox(height: 16),
                    SearchableDropdown<int>(
                      label: 'أب الاعتراف',
                      value: _confessionFatherId,
                      items: _priests,
                      displayKey: 'priest_name',
                      valueKey: 'id',
                      onChanged: (value) =>
                          setState(() => _confessionFatherId = value),
                    ),
                    const SizedBox(height: 16),
                    SearchableDropdown<int>(
                      label: 'القطاع',
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
                        onPressed: _isLoading ? null : _saveServant,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'حفظ',
                                style: GoogleFonts.cairo(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
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

  Widget _buildDropdown(
    String label,
    int? value,
    List<Map<String, dynamic>> items,
    Function(int?) onChanged, {
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<int>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: AppColors.secondary),
          prefixIcon: Icon(Icons.person, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: [
          DropdownMenuItem<int>(
            value: null,
            child: Text('اختر $label', style: GoogleFonts.cairo()),
          ),
          ...items.map(
            (item) => DropdownMenuItem<int>(
              value: item['id'],
              child: Text(item['full_name'] ?? '', style: GoogleFonts.cairo()),
            ),
          ),
        ],
        onChanged: onChanged,
        validator: required
            ? (value) => value == null ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }
}
