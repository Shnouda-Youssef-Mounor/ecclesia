import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

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
  final _educationController = TextEditingController();

  String? _maritalStatus;
  String? _militaryStatus;
  String? _governorate;
  String? _birthDate;
  String? _gender;
  int? _selectedAreaId;

  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _educationStages = [];
  int? _selectedEducationStageId;
  final _workController = TextEditingController();
  final _workAddressController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _aids = [];
  List<Map<String, dynamic>> _sectors = [];

  List<int> _selectedActivityIds = [];
  List<int> _selectedAidIds = [];
  List<int> _selectedSectorIds = [];

  @override
  @override
  void initState() {
    super.initState();
    _loadAreas();
    _loadEducationStages();
    _loadActivities();
    _loadAids();
    _loadSectors();
    if (widget.individual != null) {
      _loadIndividualData();
    }
  }

  Future<void> _loadActivities() async {
    final activities = await _db.getAllActivities();
    setState(() => _activities = activities);
  }

  Future<void> _loadAids() async {
    final aids = await _db.getAllAids();
    setState(() => _aids = aids);
  }

  Future<void> _loadSectors() async {
    final sectors = await _db.getAllSectors();
    setState(() => _sectors = sectors);
  }

  Future<void> _loadAreas() async {
    final areas = await _db.getAllAreas();
    setState(() {
      _areas = areas;
    });
  }

  Future<void> _loadEducationStages() async {
    final stages = await _db.getAllEducationStages();
    setState(() {
      _educationStages = stages;
    });
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
    _selectedEducationStageId = individual['education_stage_id'];
    _educationController.text = individual['education_institution'] ?? '';
    _maritalStatus = individual['marital_status'];
    _militaryStatus = individual['military_status'];
    _governorate = individual['governorate'];
    _birthDate = individual['birth_date'];
    _gender = individual['gender'];
    _workController.text = individual['job_title'] ?? '';
    _workAddressController.text = individual['work_place'] ?? '';
    _selectedActivityIds = List<int>.from(individual['activity_ids'] ?? []);
    _selectedAidIds = List<int>.from(individual['aid_ids'] ?? []);
    _selectedSectorIds = List<int>.from(individual['sector_ids'] ?? []);
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
      'education_stage_id': _selectedEducationStageId,
      'job_title': _workController.text,
      'work_place': _workAddressController.text,
      'education_institution': _educationController.text,
    };

    try {
      int individualId;
      if (widget.individual == null) {
        individualId = await _db.insertIndividual(data);
      } else {
        individualId = widget.individual!['id'];
        await _db.updateIndividual(individualId, data);
        // حذف العلاقات القديمة
        await _db.deleteIndividualActivities(individualId);
        await _db.deleteIndividualAids(individualId);
        await _db.deleteIndividualSectors(individualId);
      }

      // حفظ العلاقات الجديدة
      for (var actId in _selectedActivityIds) {
        await _db.insertIndividualActivity({
          'individual_id': individualId,
          'activity_id': actId,
        });
      }
      for (var aidId in _selectedAidIds) {
        await _db.insertIndividualAid({
          'individual_id': individualId,
          'aid_id': aidId,
        });
      }
      for (var sectorId in _selectedSectorIds) {
        await _db.insertIndividualSector({
          'individual_id': individualId,
          'sector_id': sectorId,
        });
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
        _buildParsedInfo(),
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
        _buildActivitiesSelector(),
        const SizedBox(height: 16),
        _buildAidsSelector(),
        const SizedBox(height: 16),
        _buildSectorsSelector(),
      ],
    );
  }

  Widget _buildActivitiesSelector() {
    return MultiSelectDialogField<int>(
      items: _activities
          .map(
            (e) => MultiSelectItem<int>(
              e['id'] as int,
              e['activity_name'] as String,
            ),
          )
          .toList(),
      title: const Text("الأنشطة"),
      buttonText: const Text("اختر الأنشطة"),
      initialValue: _selectedActivityIds,
      onConfirm: (values) {
        setState(() => _selectedActivityIds = values);
      },
    );
  }

  Widget _buildAidsSelector() {
    return MultiSelectDialogField<int>(
      items: _aids
          .map(
            (e) =>
                MultiSelectItem<int>(e['id'] as int, e['aid_name'] as String),
          )
          .toList(),
      title: const Text("المساعدات"),
      buttonText: const Text("اختر المساعدات"),
      initialValue: _selectedAidIds,
      onConfirm: (values) {
        setState(() => _selectedAidIds = values);
      },
    );
  }

  Widget _buildSectorsSelector() {
    return MultiSelectDialogField<int>(
      items: _sectors
          .map(
            (e) => MultiSelectItem<int>(
              e['id'] as int,
              e['sector_name'] as String,
            ),
          )
          .toList(),
      title: const Text("القطاعات"),
      buttonText: const Text("اختر القطاعات"),
      initialValue: _selectedSectorIds,
      onConfirm: (values) {
        setState(() => _selectedSectorIds = values);
      },
    );
  }

  Widget _buildMobileForm() {
    return Column(
      children: [
        _buildTextField(_nameController, 'الاسم الرباعي *', required: true),
        const SizedBox(height: 16),
        _buildNationalIdField(),
        const SizedBox(height: 16),
        _buildParsedInfo(),
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
        _buildActivitiesSelector(),
        const SizedBox(height: 16),
        _buildAidsSelector(),
        const SizedBox(height: 16),
        _buildSectorsSelector(),
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
    // لو في قيمة ومش موجودة في الليست → ضيفها
    if (value != null && value.isNotEmpty && !items.contains(value)) {
      items = [...items, value];
    }

    return DropdownButtonFormField<String>(
      value: (value != null && value.isNotEmpty && items.contains(value))
          ? value
          : null,
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
