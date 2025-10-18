import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import 'add_edit_user_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final loadedUsers = await DatabaseHelper().getAllUsers();
      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل المستخدمين: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('إدارة المستخدمين', style: GoogleFonts.cairo()),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToAddUser(),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : users.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد مستخدمين',
                      style: GoogleFonts.cairo(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    itemBuilder: (context, index) => _buildUserCard(users[index]),
                  ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(user['username'], style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        subtitle: Text('الدور: ${user['role']}', style: GoogleFonts.cairo()),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.secondary),
              onPressed: () => _navigateToEditUser(user),
            ),
            if (user['username'] != 'admin')
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(user),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditUserScreen()),
    );
    if (result == true) _loadUsers();
  }

  void _navigateToEditUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditUserScreen(user: user)),
    );
    if (result == true) _loadUsers();
  }

  void _confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
          content: Text('هل تريد حذف المستخدم "${user['username']}"؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteUser(user['id']);
              },
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(int id) async {
    try {
      await DatabaseHelper().deleteUser(id);
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف المستخدم بنجاح', style: GoogleFonts.cairo())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حذف المستخدم: $e', style: GoogleFonts.cairo())),
      );
    }
  }
}