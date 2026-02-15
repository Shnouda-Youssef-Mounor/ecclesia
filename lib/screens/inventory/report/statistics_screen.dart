import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> topItems = [];
  List<Map<String, dynamic>> distributionByType = [];
  List<Map<String, dynamic>> monthlyStats = [];
  bool isLoading = true;

  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => isLoading = true);
    final dbHelper = DatabaseHelper();

    try {
      // إحصائيات عامة
      stats = await dbHelper.getInventorySummary();

      // الأصناف الأكثر استخداماً
      topItems = await dbHelper.rawQuery('''
        SELECT i.item_name, i.category, i.current_quantity, i.unit,
               (SELECT COUNT(*) FROM box_type_contents bc 
                WHERE bc.item_id = i.id) as used_in_boxes
        FROM inventory_items i
        ORDER BY used_in_boxes DESC
        LIMIT 5
      ''');

      // التوزيع حسب النوع
      distributionByType = await dbHelper.rawQuery('''
        SELECT bt.type_name, 
               COUNT(b.id) as box_count,
               SUM(CASE WHEN b.status = 'مستلم' OR b.status = 'distributed' THEN 1 ELSE 0 END) as distributed_count,
               bt.id
        FROM box_types bt
        LEFT JOIN ready_boxes b ON bt.id = b.box_type_id
        WHERE bt.is_active = 1
        GROUP BY bt.id
        ORDER BY distributed_count DESC
      ''');

      // إحصائيات شهرية
      monthlyStats = await dbHelper.rawQuery('''
        SELECT 
          strftime('%Y-%m', distribution_date) as month,
          COUNT(*) as total
        FROM ready_boxes
        WHERE distribution_date IS NOT NULL
        GROUP BY strftime('%Y-%m', distribution_date)
        ORDER BY month DESC
        LIMIT 6
      ''');
    } catch (e) {
      print('❌ خطأ في تحميل الإحصائيات: $e');
      _showErrorSnackBar('حدث خطأ أثناء تحميل الإحصائيات');
    }

    setState(() => isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الإحصائيات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadStatistics,
            tooltip: 'تحديث',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'الرئيسية'),
            Tab(icon: Icon(Icons.inventory), text: 'المخزون'),
            Tab(icon: Icon(Icons.trending_up), text: 'التحليلات'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'جاري تحميل الإحصائيات...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(isSmallScreen),
                _buildInventoryTab(isSmallScreen),
                _buildAnalyticsTab(isSmallScreen),
              ],
            ),
    );
  }

  // ================== تبويب النظرة العامة ==================
  Widget _buildOverviewTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 20),
          _buildStatsGrid(isSmallScreen),
          const SizedBox(height: 24),
          _buildProgressStats(),
          const SizedBox(height: 24),
          _buildTopItemsSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مرحباً بك في لوحة الإحصائيات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'آخر تحديث: ${_getCurrentDateTime()}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
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

  Widget _buildStatsGrid(bool isSmallScreen) {
    final statItems = [
      {
        'icon': Icons.category,
        'label': 'إجمالي الأصناف',
        'value': '${stats['total_items'] ?? 0}',
        'color': AppColors.primary,
        'gradient': [AppColors.primary, AppColors.secondary],
      },
      {
        'icon': Icons.warning,
        'label': 'منخفض المخزون',
        'value': '${stats['low_stock_items'] ?? 0}',
        'color': Colors.orange,
        'gradient': [Colors.orange, Colors.deepOrange],
      },
      {
        'icon': Icons.inventory_2,
        'label': 'إجمالي الكرتونات',
        'value': '${stats['total_boxes'] ?? 0}',
        'color': Colors.green,
        'gradient': [Colors.green, Colors.teal],
      },
      {
        'icon': Icons.check_circle,
        'label': 'جاهزة للتوزيع',
        'value': '${stats['ready_boxes'] ?? 0}',
        'color': Colors.purple,
        'gradient': [Colors.purple, Colors.purpleAccent],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: statItems.length,
      itemBuilder: (context, index) {
        final item = statItems[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (item['color'] as Color).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Card(
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['value'] as String,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressStats() {
    final totalBoxes = (stats['total_boxes'] ?? 0).toDouble();
    final readyBoxes = (stats['ready_boxes'] ?? 0).toDouble();
    final distributedBoxes = (stats['distributed_boxes'] ?? 0).toDouble();

    final readyPercentage = totalBoxes > 0 ? (readyBoxes / totalBoxes) : 0;
    final distributedPercentage = totalBoxes > 0
        ? (distributedBoxes / totalBoxes)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.speed, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'مؤشرات الأداء',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildProgressItem(
            label: 'كرتونات جاهزة',
            value: readyBoxes.toInt(),
            total: totalBoxes.toInt(),
            percentage: readyPercentage,
            color: Colors.green,
            icon: Icons.inventory_2,
          ),

          const SizedBox(height: 16),

          _buildProgressItem(
            label: 'كرتونات موزعة',
            value: distributedBoxes.toInt(),
            total: totalBoxes.toInt(),
            percentage: distributedPercentage,
            color: Colors.blue,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required int value,
    required int total,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$value / $total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopItemsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star, color: Colors.amber),
              ),
              const SizedBox(width: 12),
              const Text(
                'الأصناف الأكثر استخداماً',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'أفضل 5',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          topItems.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد بيانات',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topItems.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = topItems[index];
                    return _buildTopItemCard(item, index + 1);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTopItemCard(Map<String, dynamic> item, int rank) {
    final colors = [
      Colors.amber,
      Color.fromARGB(255, 158, 158, 158),
      Color.fromARGB(255, 156, 102, 68),
      AppColors.primary,
      AppColors.accent,
    ];

    final color = colors[(rank - 1) % colors.length];
    final usedInBoxes = (item['used_in_boxes'] ?? 0).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'] ?? 'غير محدد',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['category'] ?? 'أخرى',
                        style: TextStyle(fontSize: 10, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.inventory, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 2),
                    Text(
                      '${item['current_quantity'] ?? 0} ${item['unit'] ?? ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '$usedInBoxes',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================== تبويب المخزون ==================
  Widget _buildInventoryTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildDistributionByTypeCard()],
      ),
    );
  }

  Widget _buildDistributionByTypeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              const Text(
                'التوزيع حسب نوع الكرتون',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          distributionByType.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.pie_chart_outline,
                        size: 50,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد بيانات',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: distributionByType.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final type = distributionByType[index];
                    return _buildTypeDistributionItem(type);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTypeDistributionItem(Map<String, dynamic> type) {
    final total = (type['box_count'] ?? 0).toDouble();
    final distributed = (type['distributed_count'] ?? 0).toDouble();
    final percentage = total > 0 ? (distributed / total) : 0.0;

    // ألوان مختلفة لكل نوع
    final colors = [
      AppColors.primary,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    final color = colors[type['id'] % colors.length];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type['type_name'] ?? 'غير محدد',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجمالي: ${total.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'الموزع: ${distributed.toInt()}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== تبويب التحليلات ==================
  Widget _buildAnalyticsTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildMonthlyStatsCard()],
      ),
    );
  }

  Widget _buildMonthlyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text(
                'الإحصائيات الشهرية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          monthlyStats.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart, size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد بيانات شهرية',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: monthlyStats.map((stat) {
                    final month = stat['month'] ?? '';
                    final total = (stat['total'] ?? 0).toDouble();
                    final maxTotal = monthlyStats.isNotEmpty
                        ? (monthlyStats.first['total'] ?? 1).toDouble()
                        : 1.0;
                    final percentage = total / maxTotal;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              _formatMonth(month),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.green.withOpacity(
                                      0.1,
                                    ),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.green,
                                        ),
                                    minHeight: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${total.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCurrentDateTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')} - ${now.day}/${now.month}/${now.year}';
  }

  String _formatMonth(String? monthStr) {
    if (monthStr == null || monthStr.length < 7) return monthStr ?? '';

    try {
      final parts = monthStr.split('-');
      if (parts.length >= 2) {
        final year = parts[0];
        final month = int.parse(parts[1]);
        const months = [
          'يناير',
          'فبراير',
          'مارس',
          'إبريل',
          'مايو',
          'يونيو',
          'يوليو',
          'أغسطس',
          'سبتمبر',
          'أكتوبر',
          'نوفمبر',
          'ديسمبر',
        ];
        return '${months[month - 1]}';
      }
    } catch (e) {
      // تجاهل الخطأ
    }

    return monthStr;
  }
}
