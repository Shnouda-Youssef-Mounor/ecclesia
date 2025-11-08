import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/db_helper.dart';
import '../../utils/app_colors.dart';
import '../../utils/national_id_parser.dart';
import '../../utils/searchable_dropdown.dart';

class AddEditIndividualScreen extends StatefulWidget {
  final Map<String, dynamic>? individual;

  const AddEditIndividualScreen({super.key, this.individual});

  @override
  State<AddEditIndividualScreen> createState() =>
      _AddEditIndividualScreenState();
}

class _AddEditIndividualScreenState extends State<AddEditIndividualScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _familyController = TextEditingController();
  final _educationController = TextEditingController();

  String? _maritalStatus;
  String? _militaryStatus;
  String? _governorate;
  String? _birthDate;
  String? _gender;
  int? _selectedAreaId;
  int? _selectedFamilyId;

  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> _educationStages = [];
  int? _selectedEducationStageId;
  final _workController = TextEditingController();
  final _workAddressController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadFamilies();
    _loadEducationStages();
    if (widget.individual != null) {
      _loadIndividualData();
    }
  }

  Future<void> _loadAreas() async {
    _areas = await _db.getAllAreas();
    setState(() {});
  }

  Future<void> _loadFamilies() async {
    _families = await _db.getAllFamilies();
    setState(() {});
  }

  Future<void> _loadEducationStages() async {
    _educationStages = await _db.getAllEducationStages();
    setState(() {});
  }

  void _loadIndividualData() {
    final individual = widget.individual!;
    _nameController.text = individual['full_name'] ?? '';
    _nationalIdController.text = individual['national_id'] ?? '';
    _phoneController.text = individual['phone'] ?? '';
    _whatsappController.text = individual['whatsapp'] ?? '';
    _areaController.text = individual['area'] ?? '';
    _selectedAreaId = individual['area_id'];
    _addressController.text = individual['current_address'] ?? '';
    _selectedFamilyId = individual['family_id'];
    _selectedEducationStageId = individual['education_stage_id'];
    _educationController.text = individual['education_institution'] ?? '';
    _maritalStatus = individual['marital_status'];
    _militaryStatus = individual['military_status'];
    _governorate = individual['governorate'];
    _birthDate = individual['birth_date'];
    _gender = individual['gender'];
    _workController.text = individual['job_title'] ?? '';
    _workAddressController.text = individual['work_place'] ?? '';
  }

  void _parseNationalId() {
    if (_nationalIdController.text.length == 14) {
      final parsed = NationalIdParser.parseNationalId(
        _nationalIdController.text,
      );
      if (!parsed.containsKey('error')) {
        setState(() {
          _governorate = parsed['governorate'];
          _birthDate = parsed['birth_date'];
          _gender = parsed['gender'];
        });
      }
    }
  }

  Future<void> _saveIndividual() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'full_name': _nameController.text,
      'national_id': _nationalIdController.text,
      'governorate': _governorate,
      'birth_date': _birthDate,
      'gender': _gender,
      'marital_status': _maritalStatus,
      'military_status': _militaryStatus,
      'area_id': _selectedAreaId,
      'area': _areaController.text,
      'current_address': _addressController.text,
      'phone': _phoneController.text,
      'whatsapp': _whatsappController.text,
      'family_id': _selectedFamilyId,
      'education_stage_id': _selectedEducationStageId,
      'job_title': _workController.text,
      'work_place': _workAddressController.text,
      'education_institution': _educationController.text,
    };

    try {
      if (widget.individual == null) {
        await _db.insertIndividual(data);
      } else {
        await _db.updateIndividual(widget.individual!['id'], data);
      }
      Navigator.pop(context);
    } catch (e) {
      print('Error saving individual: $e');
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
            widget.individual == null ? 'إضافة فرد جديد' : 'تعديل بيانات الفرد',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 24),
                      if (isDesktop)
                        _buildDesktopForm()
                      else
                        _buildMobileForm(),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
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

  Widget _buildDesktopForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _nameController,
                'الاسم الرباعي *',
                required: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildNationalIdField()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField(_phoneController, 'رقم الهاتف')),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(_whatsappController, 'رقم الواتساب'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAreaDropdown()),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdown(
                'الحالة الاجتماعية',
                _maritalStatus,
                ['متزوجة', 'أعزب', 'متزوج', 'مطلق', 'أرمل'],
                (value) => setState(() => _maritalStatus = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(_addressController, 'العنوان الحالي'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFamilyDropdown()),
            const SizedBox(width: 16),
            if (_gender == 'ذكر')
              Expanded(
                child: _buildDropdown(
                  'موقف التجنيد',
                  _militaryStatus,
                  ['أدى الخدمة', 'معفى', 'مؤجل'],
                  (value) => setState(() => _militaryStatus = value),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),
        _buildTextField(_workController, 'جهة العمل'),
        const SizedBox(height: 16),
        _buildTextField(_workAddressController, 'عنوان العمل'),
        const SizedBox(height: 16),
        _buildEducationStageDropdown(),
        const SizedBox(height: 16),
        _buildTextField(_educationController, 'جهة التعليم'),
        const SizedBox(height: 16),
        _buildParsedInfo(),
      ],
    );
  }

  Widget _buildMobileForm() {
    return Column(
      children: [
        _buildTextField(_nameController, 'الاسم الرباعي *', required: true),
        const SizedBox(height: 16),
        _buildNationalIdField(),
        const SizedBox(height: 16),
        _buildTextField(_phoneController, 'رقم الهاتف'),
        const SizedBox(height: 16),
        _buildTextField(_whatsappController, 'رقم الواتساب'),
        const SizedBox(height: 16),
        _buildAreaDropdown(),
        const SizedBox(height: 16),
        _buildDropdown(
          'الحالة الاجتماعية',
          _maritalStatus,
          ['متزوجة', 'أعزب', 'متزوج', 'مطلق', 'أرمل'],
          (value) => setState(() => _maritalStatus = value),
        ),
        const SizedBox(height: 16),
        _buildTextField(_addressController, 'العنوان الحالي'),
        const SizedBox(height: 16),
        _buildFamilyDropdown(),
        const SizedBox(height: 16),
        if (_gender == 'ذكر') ...[
          _buildDropdown(
            'موقف التجنيد',
            _militaryStatus,
            ['أدى الخدمة', 'معفى', 'مؤجل'],
            (value) => setState(() => _militaryStatus = value),
          ),
          const SizedBox(height: 16),
        ],
        _buildTextField(_workController, 'جهة العمل'),
        const SizedBox(height: 16),
        _buildTextField(_workAddressController, 'عنوان العمل'),
        const SizedBox(height: 16),
        _buildEducationStageDropdown(),
        const SizedBox(height: 16),
        _buildTextField(_educationController, 'جهة التعليم'),
        const SizedBox(height: 16),
        _buildParsedInfo(),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: GoogleFonts.cairo(),
      validator: required
          ? (value) => value?.isEmpty == true ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _buildNationalIdField() {
    return TextFormField(
      controller: _nationalIdController,
      decoration: InputDecoration(
        labelText: 'الرقم القومي *',
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: GoogleFonts.cairo(),
      keyboardType: TextInputType.number,
      maxLength: 14,
      onChanged: (value) => _parseNationalId(),
      validator: (value) {
        if (value?.isEmpty == true) return 'هذا الحقل مطلوب';
        if (value?.length != 14) return 'الرقم القومي يجب أن يكون 14 رقم';
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item, style: GoogleFonts.cairo()),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildParsedInfo() {
    if (_governorate == null && _birthDate == null && _gender == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppColors.light.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'البيانات المستخرجة من الرقم القومي:',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_governorate != null)
              Text('المحافظة: $_governorate', style: GoogleFonts.cairo()),
            if (_birthDate != null)
              Text('تاريخ الميلاد: $_birthDate', style: GoogleFonts.cairo()),
            if (_gender != null)
              Text('النوع: $_gender', style: GoogleFonts.cairo()),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    return SearchableDropdown<int>(
      label: 'المنطقة',
      value: _selectedAreaId,
      items: _areas,
      displayKey: 'area_name',
      valueKey: 'id',
      onChanged: (value) {
        setState(() {
          _selectedAreaId = value;
          if (value != null) {
            final selectedArea = _areas.firstWhere(
              (area) => area['id'] == value,
            );
            _areaController.text = selectedArea['area_name'] ?? '';
          } else {
            _areaController.text = '';
          }
        });
      },
    );
  }

  Widget _buildFamilyDropdown() {
    return SearchableDropdown<int>(
      label: 'العائلة',
      value: _selectedFamilyId,
      items: _families,
      displayKey: 'family_name',
      valueKey: 'id',
      onChanged: (value) {
        setState(() {
          _selectedFamilyId = value;
          if (value != null) {
            final selectedArea = _families.firstWhere(
              (area) => area['id'] == value,
            );
            _familyController.text = selectedArea['family_name'] ?? '';
          } else {
            _familyController.text = '';
          }
        });
      },
    );
  }

  Widget _buildEducationStageDropdown() {
    return SearchableDropdown<int>(
      label: 'المرحلة التعليمية',
      value: _selectedEducationStageId,
      items: _educationStages,
      displayKey: 'stage_name',
      valueKey: 'id',
      onChanged: (value) {
        setState(() {
          _selectedEducationStageId = value;
        });
      },
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.light.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.individual == null ? Icons.person_add : Icons.edit,
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
                  widget.individual == null
                      ? 'إضافة فرد جديد'
                      : 'تعديل بيانات الفرد',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'الحقول المطلوبة معلمة بعلامة *',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveIndividual,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.individual == null ? Icons.add : Icons.save,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.individual == null ? 'إضافة الفرد' : 'حفظ التعديلات',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
