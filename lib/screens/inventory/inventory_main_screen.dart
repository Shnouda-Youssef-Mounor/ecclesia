import 'package:ecclesia/screens/inventory/box/box_types_screen.dart';
import 'package:ecclesia/screens/inventory/box/prepare_boxes_screen.dart';
import 'package:ecclesia/screens/inventory/box/ready_boxes_screen.dart';
import 'package:ecclesia/screens/inventory/distribution/distribution_screen.dart';
import 'package:ecclesia/screens/inventory/donations/donations_screeen.dart';
import 'package:ecclesia/screens/inventory/items/items_management_screen.dart';
import 'package:ecclesia/screens/inventory/report/reports_screen.dart';
import 'package:ecclesia/screens/inventory/report/statistics_screen.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class InventoryMainScreen extends StatelessWidget {
  const InventoryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Modern AppBar with gradient
          SliverAppBar(
            expandedHeight: screenHeight * 0.25,
            floating: false,
            pinned: true,
            snap: false,
            stretch: true,
            backgroundColor: AppColors.primary,
            elevation: 0,
            shape: const ContinuousRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(vertical: 16),
              title: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? 60
                      : isTablet
                      ? 40
                      : 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isDesktop)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.light.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.inventory_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'نظام إدارة الكنيسة',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Text(
                        'إدارة المخزون',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop
                              ? 28
                              : isTablet
                              ? 24
                              : 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: isDesktop
                            ? TextAlign.center
                            : TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ),
            ),
          ),

          // Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop
                    ? 60
                    : isTablet
                    ? 40
                    : 24,
                vertical: isDesktop
                    ? 32
                    : isTablet
                    ? 24
                    : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.dashboard_customize_outlined,
                              color: AppColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'لوحة التحكم',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'مرحباً بك في نظام المخزون',
                    style: TextStyle(
                      fontSize: isDesktop
                          ? 28
                          : isTablet
                          ? 24
                          : 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'إدارة المخزون، التوزيع، والتقارير في نظام واحد متكامل',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Features count (only on larger screens)
          if (isDesktop)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildFeatureCount('٨', 'قسم رئيسي'),
                    const SizedBox(width: 16),
                    _buildFeatureCount('٢٤', 'وظيفة متاحة'),
                    const SizedBox(width: 16),
                    _buildFeatureCount('∞', 'تقرير مخصص'),
                  ],
                ),
              ),
            ),

          // Main Grid
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop
                  ? 60
                  : isTablet
                  ? 40
                  : 20,
              vertical: isDesktop ? 24 : 20,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                mainAxisExtent: 230,
                crossAxisCount: isDesktop
                    ? 4
                    : isTablet
                    ? 3
                    : 2,
                crossAxisSpacing: isDesktop ? 24 : 20,
                mainAxisSpacing: isDesktop ? 24 : 20,
                childAspectRatio: isDesktop
                    ? 1.0
                    : isTablet
                    ? 0.9
                    : 0.85,
              ),
              delegate: SliverChildListDelegate([
                _buildModernMenuCard(
                  context: context,
                  title: 'الأصناف',
                  subtitle: 'إدارة المواد المخزنة',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  iconBgColor: AppColors.light.withOpacity(0.2),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemsManagementScreen(),
                    ),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'أنواع الكرتونات',
                  subtitle: 'تصميم محتويات الكرتونات',
                  icon: Icons.category_outlined,
                  color: AppColors.secondary,
                  iconBgColor: AppColors.light.withOpacity(0.2),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BoxTypesScreen()),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'تجهيز الكرتونات',
                  subtitle: 'تحويل مواد إلى كرتونات',
                  icon: Icons.build_outlined,
                  color: const Color(0xFFE74C3C),
                  iconBgColor: const Color(0xFFFFE5E0),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrepareBoxesScreen(),
                    ),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'الكرتونات الجاهزة',
                  subtitle: 'عرض وتوزيع الكرتونات',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2ECC71),
                  iconBgColor: const Color(0xFFE8F8EF),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReadyBoxesScreen()),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'التوزيع',
                  subtitle: 'تسجيل توزيع الكرتونات',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFF39C12),
                  iconBgColor: const Color(0xFFFEF5E7),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DistributionScreen(),
                    ),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'التقارير',
                  subtitle: 'تقارير المخزون والحركات',
                  icon: Icons.analytics_outlined,
                  color: AppColors.accent,
                  iconBgColor: AppColors.light.withOpacity(0.2),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReportsScreen()),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'التبرعات',
                  subtitle: 'تسجيل تبرعات المواد',
                  icon: Icons.card_giftcard_outlined,
                  color: const Color(0xFF9B59B6),
                  iconBgColor: const Color(0xFFF4ECF7),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DonationsScreen()),
                  ),
                ),
                _buildModernMenuCard(
                  context: context,
                  title: 'الإحصائيات',
                  subtitle: 'نظرة عامة على المخزون',
                  icon: Icons.dashboard_outlined,
                  color: const Color(0xFF3498DB),
                  iconBgColor: const Color(0xFFEBF5FB),
                  isTablet: isTablet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatisticsScreen()),
                  ),
                ),
              ]),
            ),
          ),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildFeatureCount(String count, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernMenuCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconBgColor,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(60),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            icon,
                            size: isTablet ? 28 : 24,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
