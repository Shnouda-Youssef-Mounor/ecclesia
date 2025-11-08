import 'dart:io';

import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ChurchAddScreen extends StatefulWidget {
  final Map<String, dynamic>? item;
  const ChurchAddScreen({Key? key, this.item}) : super(key: key);

  @override
  State<ChurchAddScreen> createState() => _ChurchAddScreenState();
}

class _ChurchAddScreenState extends State<ChurchAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _churchNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _dioceseNameController = TextEditingController();

  File? _churchLogo;
  File? _dioceseLogo;
  final ImagePicker _picker = ImagePicker();

  Future<File?> _pickImage(bool isChurchLogo) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final dirPath = '${appDir.path}/church_images';
    await Directory(dirPath).create(recursive: true);

    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}';
    final savedImage = await File(image.path).copy('$dirPath/$fileName');
    return savedImage;
  }

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _loadChurchData();
    }
  }

  void _loadChurchData() {
    final item = widget.item!;
    _churchNameController.text = item['church_name'] ?? '';
    _countryController.text = item['church_country'] ?? '';
    _dioceseNameController.text = item['diocese_name'] ?? '';

    if (item['church_logo'] != null &&
        (item['church_logo'] as String).isNotEmpty) {
      _churchLogo = File(item['church_logo']);
    }
    if (item['diocese_logo'] != null &&
        (item['diocese_logo'] as String).isNotEmpty) {
      _dioceseLogo = File(item['diocese_logo']);
    }
  }

  Future<void> _saveChurch() async {
    if (!_formKey.currentState!.validate()) return;

    final dbHelper = DatabaseHelper();
    if (widget.item != null) {
      await dbHelper.updateChurch(widget.item!['id'], {
        'church_name': _churchNameController.text,
        'church_logo': _churchLogo?.path,
        'church_country': _countryController.text,
        'diocese_name': _dioceseNameController.text,
        'diocese_logo': _dioceseLogo?.path,
      });
    } else {
      await dbHelper.insertChurch({
        'church_name': _churchNameController.text,
        'church_logo': _churchLogo?.path,
        'church_country': _countryController.text,
        'diocese_name': _dioceseNameController.text,
        'diocese_logo': _dioceseLogo?.path,
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حفظ البيانات بنجاح'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.item == null ? 'إضافة كنيسة' : 'تعديل كنيسة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _churchNameController,
                  label: 'اسم الكنيسة',
                  validatorMsg: 'قم بإدخال اسم الكنيسة',
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _countryController,
                  label: 'البلد (المدينة أو القرية)',
                  validatorMsg: 'قم بإدخال اسم البلد',
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _dioceseNameController,
                  label: 'اسم المطرانية',
                  validatorMsg: 'قم بإدخال اسم المطرانية',
                ),
                const SizedBox(height: 20),
                _imagePickerWidget(
                  title: 'شعار الكنيسة',
                  imageFile: _churchLogo,
                  onTap: () async {
                    final img = await _pickImage(true);
                    if (img != null) setState(() => _churchLogo = img);
                  },
                ),
                const SizedBox(height: 20),
                _imagePickerWidget(
                  title: 'شعار المطرانية',
                  imageFile: _dioceseLogo,
                  onTap: () async {
                    final img = await _pickImage(false);
                    if (img != null) setState(() => _dioceseLogo = img);
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _saveChurch,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String validatorMsg,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.primary),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(10),
        ),
        fillColor: AppColors.light.withOpacity(0.2),
        filled: true,
      ),
      validator: (value) => value!.isEmpty ? validatorMsg : null,
    );
  }

  Widget _imagePickerWidget({
    required String title,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.light.withOpacity(0.3),
              border: Border.all(color: AppColors.accent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imageFile == null
                ? const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      size: 40,
                      color: AppColors.accent,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }
}
