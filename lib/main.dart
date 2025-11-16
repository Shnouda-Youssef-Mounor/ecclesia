import 'dart:io';

import 'package:ecclesia/screens/church/view_church_screen.dart';
import 'package:ecclesia/screens/settings/settings_page.dart';
import 'package:ecclesia/utils/app_footer.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/cache_helper.dart';
import 'helpers/db_helper.dart';
import 'screens/activities/activities_screen.dart';
import 'screens/aids/aids_screen.dart';
import 'screens/areas/areas_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/education_stages/education_stages_screen.dart';
import 'screens/families/families_screen.dart';
import 'screens/individuals/individuals_screen.dart';
import 'screens/priests/priests_screen.dart';
import 'screens/sectors/sectors_screen.dart';
import 'screens/servants/servants_screen.dart';
import 'screens/users/roles_screen.dart';
import 'screens/users/users_screen.dart';
import 'services/auth_service.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🖥️ تهيئة قاعدة البيانات على Desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
  }

  await CacheHelper.init();
  //await _deleteOldDatabase();
  // 🗃️ تهيئة قاعدة البيانات
  await DatabaseHelper().database;

  // 📝 لو عايز تزرع بيانات أولية
  final db = DatabaseHelper();
  final individuals = await db.getAllIndividuals();
  if (individuals.isEmpty) {
    //await DataSeeder.seedData();
  }

  runApp(const MyApp());
}

Future<void> _deleteOldDatabase() async {
  String dbPath;

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    dbPath = join(await databaseFactoryFfi.getDatabasesPath(), 'ecclesia.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  } else {
    dbPath = join(await getDatabasesPath(), 'ecclesia.db');
    await deleteDatabase(dbPath);
  }

  print('✅ تم حذف قاعدة البيانات القديمة بنجاح');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'اكليسيا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFF1A2A80, {
          50: AppColors.light,
          100: AppColors.accent,
          200: AppColors.secondary,
          300: AppColors.primary,
          400: AppColors.primary,
          500: AppColors.primary,
          600: AppColors.primary,
          700: AppColors.primary,
          800: AppColors.primary,
          900: AppColors.primary,
        }),
        textTheme: GoogleFonts.cairoTextTheme(),
        useMaterial3: true,
      ),
      home: AuthService.isLoggedIn() ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.getCurrentUser();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        bottomNavigationBar: AppFooter(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.light.withOpacity(0.3),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, user),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildWelcomeCard(user),
                        const SizedBox(height: 24),
                        _buildMenuGrid(context, isDesktop),
                      ],
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

  Widget _buildHeader(BuildContext context, Map<String, dynamic>? user) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAllChurches(),
      builder: (context, snapshot) {
        final church = snapshot.data?.isNotEmpty == true
            ? snapshot.data!.first
            : null;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    church?['church_logo'] != null &&
                        church!['church_logo'].toString().isNotEmpty &&
                        File(church['church_logo']).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(church['church_logo']),
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.church, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      church?['church_name'] ?? 'نظام إدارة الكنيسة',
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              /*if (AuthService.isAdmin())
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => _showResetDialog(context),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    tooltip: 'إعادة تعيين قاعدة البيانات',
                  ),
                ),*/
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () async {
                    await AuthService.logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'تسجيل الخروج',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(Map<String, dynamic>? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.light.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'مرحباً بك ${user?['username'] ?? ''}',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'الدور: ${user?['user_role'] ?? ''}',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context, bool isDesktop) {
    final menuItems = [
      {
        'title': 'الأفراد',
        'icon': Icons.people,
        'screen': const IndividualsScreen(),
      },
      {
        'title': 'الأسر',
        'icon': Icons.family_restroom,
        'screen': const FamiliesScreen(),
      },
      {
        'title': 'القطاعات',
        'icon': Icons.category,
        'screen': const SectorsScreen(),
      },
      {
        'title': 'المراحل التعليمية',
        'icon': Icons.school,
        'screen': const EducationStagesScreen(),
      },
      {
        'title': 'الخدام',
        'icon': Icons.volunteer_activism,
        'screen': const ServantsScreen(),
      },
      {
        'title': 'الكهنة',
        'icon': Icons.church,
        'screen': const PriestsScreen(),
      },
      {
        'title': 'المساعدات',
        'icon': Icons.favorite,
        'screen': const AidsScreen(),
      },
      {
        'title': 'الأنشطة',
        'icon': Icons.event,
        'screen': const ActivitiesScreen(),
      },
      {
        'title': 'المناطق',
        'icon': Icons.location_on,
        'screen': const AreasScreen(),
      },
    ];

    // إضافة إدارة المستخدمين والأدوار للمدير فقط
    if (AuthService.isAdmin()) {
      menuItems.addAll([
        {
          'title': 'إدارة المستخدمين',
          'icon': Icons.admin_panel_settings,
          'screen': const UsersScreen(),
        },
        {
          'title': 'إدارة الكنيسة',
          'icon': Icons.church,
          'screen': const ViewChurchScreen(),
        },
        {
          'title': 'الأدوار والصلاحيات',
          'icon': Icons.security,
          'screen': const RolesScreen(),
        },
        {
          'title': 'الاعدادات',
          'icon': Icons.security,
          'screen': SettingsPage(),
        },
      ]);
    }

    return isDesktop
        ? _buildDesktopMenu(menuItems, context)
        : _buildMobileMenu(menuItems, context);
  }

  Widget _buildDesktopMenu(
    List<Map<String, dynamic>> menuItems,
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: menuItems
            .map(
              (item) => _buildDesktopMenuItem(
                item['title'] as String,
                item['icon'] as IconData,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => item['screen'] as Widget,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileMenu(
    List<Map<String, dynamic>> menuItems,
    BuildContext context,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menuItems.length,
      itemBuilder: (ctx, index) {
        final item = menuItems[index];
        return _buildMobileMenuItem(
          item['title'] as String,
          item['icon'] as IconData,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item['screen'] as Widget),
          ),
        );
      },
    );
  }

  Widget _buildDesktopMenuItem(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.accent,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('إعادة تعيين قاعدة البيانات', style: GoogleFonts.cairo()),
          content: Text(
            'هل أنت متأكد من حذف جميع البيانات وإعادة تعيين قاعدة البيانات؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _resetDatabase(context);
              },
              child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resetDatabase(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                'جاري إعادة تعيين قاعدة البيانات...',
                style: GoogleFonts.cairo(),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await DatabaseHelper().resetDatabase();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إعادة تعيين قاعدة البيانات بنجاح',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e', style: GoogleFonts.cairo()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
