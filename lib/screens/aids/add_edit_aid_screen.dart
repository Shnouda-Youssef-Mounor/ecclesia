import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/db_helper.dart';
import '../../utils/app_colors.dart';

class AddEditAidScreen extends StatefulWidget {
  final Map<String, dynamic>? aid;

  const AddEditAidScreen({super.key, this.aid});

  @override
  State<AddEditAidScreen> createState() => _AddEditAidScreenState();
}

class _AddEditAidScreenState extends State<AddEditAidScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  // ✅ الحقول الأساسية
  final _organizationNameController = TextEditingController();
  final _aidTypeController = TextEditingController();
  final _descriptionController = TextEditingController();

  // ✅ الحقول الجديدة (المضافة في onUpgrade)
  final _quantityNeededController = TextEditingController();
  final _quantityProvidedController = TextEditingController();

  bool _isLoading = false;
  bool _isMaterialAid = false;
  int? _selectedBoxTypeId;
  String? _selectedBoxTypeName;

  List<Map<String, dynamic>> _boxTypes = [];

  @override
  void initState() {
    super.initState();
    _loadBoxTypes();
    if (widget.aid != null) {
      _loadAidData();
    }
  }

  Future<void> _loadBoxTypes() async {
    try {
      final types = await _db.getAllBoxTypes();
      setState(() {
        _boxTypes = types;
      });
    } catch (e) {
      print('خطأ في تحميل أنواع الكرتونات: $e');
    }
  }

  void _loadAidData() {
    final aid = widget.aid!;

    // الحقول الأساسية
    _organizationNameController.text = aid['organization_name'] ?? '';
    _aidTypeController.text = aid['aid_type'] ?? '';
    _descriptionController.text = aid['description'] ?? '';

    // ✅ الحقول الجديدة - مع التحقق من وجودها
    _isMaterialAid = (aid['is_material_aid'] ?? 0) == 1;
    _selectedBoxTypeId = aid['box_type_id'];
    _quantityNeededController.text = (aid['quantity_needed'] ?? 0).toString();
    _quantityProvidedController.text = (aid['quantity_provided'] ?? 0)
        .toString();

    if (_selectedBoxTypeId != null) {
      final boxType = _boxTypes.firstWhere(
        (bt) => bt['id'] == _selectedBoxTypeId,
        orElse: () => {},
      );
      _selectedBoxTypeName = boxType['type_name'];
    }
  }

  Future<void> _saveAid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // ✅ تجهيز البيانات - الآن مع جميع الحقول
    final Map<String, dynamic> data = {
      'organization_name': _organizationNameController.text,
      'aid_type': _aidTypeController.text,
      'description': _descriptionController.text,
      'is_material_aid': _isMaterialAid ? 1 : 0,
    };

    // ✅ إضافة الحقول الخاصة بالمساعدات العينية
    if (_isMaterialAid) {
      data['box_type_id'] = _selectedBoxTypeId;
      data['quantity_needed'] =
          int.tryParse(_quantityNeededController.text) ?? 0;
      data['quantity_provided'] =
          int.tryParse(_quantityProvidedController.text) ?? 0;
    } else {
      // إذا كانت مساعدة مالية، نجعل هذه الحقول null أو 0
      data['box_type_id'] = null;
      data['quantity_needed'] = 0;
      data['quantity_provided'] = 0;
    }

    try {
      int result;
      if (widget.aid == null) {
        result = await _db.insertAid(data);
        print('✅ تم إضافة مساعدة جديدة: $result');
      } else {
        result = await _db.updateAid(widget.aid!['id'], data);
        print('✅ تم تحديث المساعدة: $result');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم ${widget.aid == null ? 'إضافة' : 'تحديث'} المساعدة بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ خطأ في الحفظ: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.aid == null ? 'إضافة مساعدة' : 'تعديل مساعدة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary.withOpacity(0.05), Colors.white],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 600 : double.infinity,
                ),
                child: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🏷️ عنوان القسم
                          Row(
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                color: AppColors.primary,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'معلومات المساعدة',
                                style: GoogleFonts.cairo(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // 📝 اسم الجهة
                          _buildTextField(
                            _organizationNameController,
                            'اسم الجهة *',
                            Icons.business,
                            required: true,
                          ),
                          const SizedBox(height: 16),

                          // 🏷️ نوع المساعدة
                          _buildTextField(
                            _aidTypeController,
                            'نوع المساعدة',
                            Icons.category,
                            hint: 'مثال: إغاثة غذائية, مساعدة مالية, ...',
                          ),
                          const SizedBox(height: 16),

                          // 📋 الوصف
                          _buildTextField(
                            _descriptionController,
                            'الوصف',
                            Icons.description,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),

                          // 🔘 نوع المساعدة (عينية/مالية)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نوع المساعدة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildRadioButton(
                                        value: false,
                                        groupValue: _isMaterialAid,
                                        label: 'مساعدة مالية',
                                        icon: Icons.attach_money,
                                        onChanged: (value) {
                                          setState(() {
                                            _isMaterialAid = value ?? false;
                                            if (!_isMaterialAid) {
                                              _selectedBoxTypeId = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildRadioButton(
                                        value: true,
                                        groupValue: _isMaterialAid,
                                        label: 'مساعدة عينية',
                                        icon: Icons.inventory_2,
                                        onChanged: (value) {
                                          setState(() {
                                            _isMaterialAid = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 📦 إذا كانت مساعدة عينية - أظهر حقول الكرتونات
                          if (_isMaterialAid) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.inventory, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        'بيانات الكرتون',
                                        style: GoogleFonts.cairo(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // قائمة أنواع الكرتونات
                                  if (_boxTypes.isEmpty)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  else
                                    DropdownButtonFormField<int>(
                                      value: _selectedBoxTypeId,
                                      decoration: InputDecoration(
                                        labelText: 'نوع الكرتون *',
                                        labelStyle: GoogleFonts.cairo(),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        prefixIcon: const Icon(Icons.inbox),
                                      ),
                                      items: _boxTypes.map((type) {
                                        return DropdownMenuItem<int>(
                                          value: type['id'],
                                          child: Text(
                                            type['type_name'] ?? '',
                                            style: GoogleFonts.cairo(),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBoxTypeId = value;
                                          final selected = _boxTypes.firstWhere(
                                            (bt) => bt['id'] == value,
                                            orElse: () => {},
                                          );
                                          _selectedBoxTypeName =
                                              selected['type_name'];
                                        });
                                      },
                                      validator: (value) {
                                        if (_isMaterialAid && value == null) {
                                          return 'يرجى اختيار نوع الكرتون';
                                        }
                                        return null;
                                      },
                                    ),
                                  const SizedBox(height: 16),

                                  // الكميات
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          _quantityNeededController,
                                          'الكمية المطلوبة',
                                          Icons.format_list_numbered,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildTextField(
                                          _quantityProvidedController,
                                          'الكمية المقدمة',
                                          Icons.check_circle_outline,
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_selectedBoxTypeId != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info,
                                            color: Colors.green[700],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'سيتم ربط الكرتونات من نوع "$_selectedBoxTypeName" بهذه المساعدة',
                                              style: GoogleFonts.cairo(
                                                fontSize: 13,
                                                color: Colors.green[800],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // 💾 زر الحفظ
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveAid,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
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
          ),
        ),
      ),
    );
  }

  // 📝 دالة بناء حقل النص
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.cairo(color: AppColors.secondary),
          hintStyle: GoogleFonts.cairo(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: GoogleFonts.cairo(),
        validator: required
            ? (value) => value?.isEmpty == true ? 'هذا الحقل مطلوب' : null
            : null,
      ),
    );
  }

  // 🔘 دالة بناء زر الراديو
  Widget _buildRadioButton({
    required bool value,
    required bool groupValue,
    required String label,
    required IconData icon,
    required void Function(bool?) onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? Colors.white : AppColors.secondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _aidTypeController.dispose();
    _descriptionController.dispose();
    _quantityNeededController.dispose();
    _quantityProvidedController.dispose();
    super.dispose();
  }
}
