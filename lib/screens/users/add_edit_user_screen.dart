import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/db_helper.dart';
import '../../utils/app_colors.dart';

class AddEditUserScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AddEditUserScreen({super.key, this.user});

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'viewer';
  bool _isLoading = false;

  final List<String> _roles = ['admin', 'editor', 'viewer'];
  final Map<String, String> _roleNames = {
    'admin': 'مدير',
    'editor': 'محرر',
    'viewer': 'مشاهد',
  };

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _usernameController.text = widget.user!['username'];
      _selectedRole = widget.user!['role'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEdit ? 'تعديل مستخدم' : 'إضافة مستخدم',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  style: GoogleFonts.cairo(),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب اسم المستخدم';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'كلمة المرور الجديدة (اختياري)' : 'كلمة المرور',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  style: GoogleFonts.cairo(),
                  obscureText: true,
                  validator: (value) {
                    if (!isEdit && (value?.isEmpty ?? true)) {
                      return 'مطلوب كلمة المرور';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'الدور',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  items: _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_roleNames[role]!, style: GoogleFonts.cairo()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedRole = value!),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isEdit ? 'تحديث' : 'إضافة',
                            style: GoogleFonts.cairo(fontSize: 16),
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

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userData = {
        'username': _usernameController.text,
        'role': _selectedRole,
      };

      if (widget.user == null) {
        // إضافة مستخدم جديد
        userData['password'] = _passwordController.text;
        await DatabaseHelper().createUser(
          userData['username']!,
          userData['password']!,
          userData['role']!,
        );
      } else {
        // تعديل مستخدم موجود
        if (_passwordController.text.isNotEmpty) {
          userData['password'] = _passwordController.text;
        }
        await DatabaseHelper().updateUser(widget.user!['id'], userData);
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حفظ المستخدم: $e', style: GoogleFonts.cairo())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}