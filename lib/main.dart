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
                        OutlinedButton.icon(
                          onPressed: () {},
                          style: ButtonStyle(
                            foregroundColor: WidgetStatePropertyAll(
                              AppColors.primary,
                            ),
                          ),
                          icon: Icon(Icons.inventory, color: AppColors.primary),
                          label: Text(
                            "المخزون",
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
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
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.05),
            AppColors.light.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.person_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'أهلاً وسهلاً ${user?['username'] ?? ''}',
            style: GoogleFonts.cairo(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withOpacity(0.15),
                  AppColors.accent.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(user?['user_role']),
                  color: AppColors.secondary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'الدور: ${_getRoleDisplayName(user?['user_role'])}',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickStats(),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'editor':
        return Icons.edit_rounded;
      case 'viewer':
        return Icons.visibility_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return 'مدير';
      case 'editor':
        return 'محرر';
      case 'viewer':
        return 'مشاهد';
      default:
        return 'غير محدد';
    }
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, int>>(
      future: _getQuickStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.light.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'الأفراد',
                stats['individuals'] ?? 0,
                Icons.people_rounded,
              ),
              _buildStatItem(
                'الأسر',
                stats['families'] ?? 0,
                Icons.family_restroom_rounded,
              ),
              _buildStatItem(
                'القطاعات',
                stats['sectors'] ?? 0,
                Icons.category_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.cairo(fontSize: 12, color: AppColors.secondary),
        ),
      ],
    );
  }

  Future<Map<String, int>> _getQuickStats() async {
    final db = DatabaseHelper();
    final individuals = await db.getAllIndividuals();
    final families = await db.getAllFamilies();
    final sectors = await db.getAllSectors();

    return {
      'individuals': individuals.length,
      'families': families.length,
      'sectors': sectors.length,
    };
  }

  Widget _buildMenuGrid(BuildContext context, bool isDesktop) {
    final menuItems = _getMenuItemsByRole();

    return isDesktop
        ? _buildDesktopMenu(menuItems, context)
        : _buildMobileMenu(menuItems, context);
  }

  List<Map<String, dynamic>> _getMenuItemsByRole() {
    final baseItems = [
      {
        'title': 'الأفراد',
        'icon': Icons.people_rounded,
        'screen': const IndividualsScreen(),
        'color': const Color(0xFF2196F3),
        'description': 'إدارة بيانات الأفراد',
      },
      {
        'title': 'الأسر',
        'icon': Icons.family_restroom_rounded,
        'screen': const FamiliesScreen(),
        'color': const Color(0xFF4CAF50),
        'description': 'إدارة الأسر والعائلات',
      },
      {
        'title': 'القطاعات',
        'icon': Icons.category_rounded,
        'screen': const SectorsScreen(),
        'color': const Color(0xFF9C27B0),
        'description': 'إدارة قطاعات الخدمة',
      },
      {
        'title': 'المراحل التعليمية',
        'icon': Icons.school_rounded,
        'screen': const EducationStagesScreen(),
        'color': const Color(0xFFFF9800),
        'description': 'إدارة المراحل التعليمية',
      },
      {
        'title': 'الخدام',
        'icon': Icons.volunteer_activism_rounded,
        'screen': const ServantsScreen(),
        'color': const Color(0xFF795548),
        'description': 'إدارة الخدام والمسؤوليات',
      },
      {
        'title': 'الكهنة',
        'icon': Icons.church_rounded,
        'screen': const PriestsScreen(),
        'color': const Color(0xFF607D8B),
        'description': 'إدارة الكهنة وآباء الاعتراف',
      },
      {
        'title': 'المساعدات',
        'icon': Icons.favorite_rounded,
        'screen': const AidsScreen(),
        'color': const Color(0xFFE91E63),
        'description': 'إدارة المساعدات المقدمة',
      },
      {
        'title': 'الأنشطة',
        'icon': Icons.event_rounded,
        'screen': const ActivitiesScreen(),
        'color': const Color(0xFF00BCD4),
        'description': 'إدارة الأنشطة والفعاليات',
      },
      {
        'title': 'المناطق',
        'icon': Icons.location_on_rounded,
        'screen': const AreasScreen(),
        'color': const Color(0xFF8BC34A),
        'description': 'إدارة المناطق الجغرافية',
      },
    ];

    // إضافة عناصر المدير فقط
    if (AuthService.isAdmin()) {
      baseItems.addAll([
        {
          'title': 'إدارة المستخدمين',
          'icon': Icons.admin_panel_settings_rounded,
          'screen': const UsersScreen(),
          'color': const Color(0xFFF44336),
          'description': 'إدارة المستخدمين والصلاحيات',
        },
        {
          'title': 'إدارة الكنيسة',
          'icon': Icons.church_rounded,
          'screen': const ViewChurchScreen(),
          'color': const Color(0xFF3F51B5),
          'description': 'إعدادات الكنيسة العامة',
        },
        {
          'title': 'الأدوار والصلاحيات',
          'icon': Icons.security_rounded,
          'screen': const RolesScreen(),
          'color': const Color(0xFF673AB7),
          'description': 'عرض الأدوار والصلاحيات',
        },
        {
          'title': 'الإعدادات',
          'icon': Icons.settings_rounded,
          'screen': SettingsPage(),
          'color': const Color(0xFF757575),
          'description': 'إعدادات النظام العامة',
        },
      ]);
    }

    return baseItems;
  }

  Widget _buildDesktopMenu(
    List<Map<String, dynamic>> menuItems,
    BuildContext context,
  ) {
    final mainItems = menuItems
        .where((item) => !_isAdminItem(item['title'] as String))
        .toList();
    final adminItems = menuItems
        .where((item) => _isAdminItem(item['title'] as String))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('الأقسام الرئيسية'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mainItems.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final item = mainItems[index];
              return _buildDesktopMenuItem(
                item['title'] as String,
                item['icon'] as IconData,
                item['color'] as Color,
                item['description'] as String,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => item['screen'] as Widget,
                  ),
                ),
              );
            },
          ),
        ),
        if (adminItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionTitle('إدارة النظام'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: adminItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final item = adminItems[index];
                return _buildDesktopMenuItem(
                  item['title'] as String,
                  item['icon'] as IconData,
                  item['color'] as Color,
                  item['description'] as String,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => item['screen'] as Widget,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  bool _isAdminItem(String title) {
    return title.contains('إدارة المستخدمين') ||
        title.contains('إدارة الكنيسة') ||
        title.contains('الأدوار والصلاحيات') ||
        title.contains('الإعدادات');
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMenu(
    List<Map<String, dynamic>> menuItems,
    BuildContext context,
  ) {
    return Column(
      children: [
        _buildSectionTitle('الأقسام الرئيسية'),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: menuItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (ctx, index) {
            final item = menuItems[index];
            return _buildMobileMenuItem(
              item['title'] as String,
              item['icon'] as IconData,
              item['color'] as Color,
              item['description'] as String,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => item['screen'] as Widget,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesktopMenuItem(
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.accent,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
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
