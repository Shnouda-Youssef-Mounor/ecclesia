import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  DateTimeRange? dateRange;
  String selectedReportType = 'monthly';
  Map<String, dynamic> summaryData = {};
  List<Map<String, dynamic>> recentDistributions = [];
  List<Map<String, dynamic>> lowStockItems = [];
  List<Map<String, dynamic>> topBoxTypes = [];
  List<Map<String, dynamic>> monthlyStats = [];
  List<Map<String, dynamic>> allReadyBoxes = [];
  List<Map<String, dynamic>> allDistributedBoxes = [];

  bool isLoading = true;
  String errorMessage = '';

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
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final dbHelper = DatabaseHelper();

    try {
      // جلب جميع البيانات بالتوازي
      final results = await Future.wait([
        dbHelper.getInventorySummary(),
        dbHelper.getRecentDistributions(limit: 10),
        dbHelper.getLowStockItems(limit: 10),
        dbHelper.getTopDistributedBoxTypes(limit: 5),
        dbHelper.getMonthlyDistributionStats(),
        dbHelper.getAllReadyBoxes(),
        dbHelper.getAllDistributedBoxes(),
      ]);

      summaryData = results[0] as Map<String, dynamic>;
      recentDistributions = results[1] as List<Map<String, dynamic>>;
      lowStockItems = results[2] as List<Map<String, dynamic>>;
      topBoxTypes = results[3] as List<Map<String, dynamic>>;
      monthlyStats = results[4] as List<Map<String, dynamic>>;
      allReadyBoxes = results[5] as List<Map<String, dynamic>>;
      allDistributedBoxes = results[6] as List<Map<String, dynamic>>;

      print('✅ تم تحميل البيانات:');
      print('   - كرتونات جاهزة: ${allReadyBoxes.length}');
      print('   - كرتونات موزعة: ${allDistributedBoxes.length}');
      print('   - توزيعات حديثة: ${recentDistributions.length}');
    } catch (e) {
      print('❌ خطأ في تحميل التقارير: $e');
      setState(() {
        errorMessage = 'حدث خطأ أثناء تحميل التقارير: $e';
      });
      _showErrorSnackBar('حدث خطأ أثناء تحميل التقارير');
    }

    setState(() => isLoading = false);
  }

  // دالة مساعدة لجلب الأصناف منخفضة المخزون
  Future<List<Map<String, dynamic>>> getLowStockItems({int limit = 10}) async {
    final db = await DatabaseHelper().database;

    try {
      return await db.rawQuery(
        '''
        SELECT * FROM inventory_items 
        WHERE current_quantity <= min_quantity
        ORDER BY (CAST(current_quantity AS REAL) / CAST(min_quantity AS REAL)) ASC
        LIMIT ?
      ''',
        [limit],
      );
    } catch (e) {
      print('❌ خطأ في getLowStockItems: $e');
      return [];
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDateRangePicker() async {
    final initialDateRange =
        dateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
      locale: const Locale('ar', 'EG'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBackground,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() => dateRange = pickedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'التقارير والإحصائيات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadReports,
            tooltip: 'تحديث',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              setState(() => selectedReportType = value);
              if (value == 'custom') {
                _showDateRangePicker();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text('تقرير شهري'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'weekly',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_view_week,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text('تقرير أسبوعي'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'daily',
                child: Row(
                  children: [
                    Icon(Icons.today, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('تقرير يومي'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    Icon(Icons.date_range, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('فترة مخصصة'),
                  ],
                ),
              ),
            ],
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
            Tab(icon: Icon(Icons.analytics), text: 'تحليلات'),
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
                    'جاري تحميل التقارير...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الكرتونات الجاهزة: ${allReadyBoxes.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadReports,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
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
          _buildDateFilterCard(),
          const SizedBox(height: 16),
          _buildQuickStats(isSmallScreen),
          const SizedBox(height: 24),
          _buildSummaryStats(isSmallScreen),
          const SizedBox(height: 24),
          _buildRecentDistributions(),
        ],
      ),
    );
  }

  Widget _buildDateFilterCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'الفترة الزمنية',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selectedReportType == 'monthly'
                          ? 'شهري'
                          : selectedReportType == 'weekly'
                          ? 'أسبوعي'
                          : selectedReportType == 'daily'
                          ? 'يومي'
                          : 'مخصص',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              if (selectedReportType == 'custom' && dateRange != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'من',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDateFromDateTime(dateRange!.start),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.white),
                      Column(
                        children: [
                          const Text(
                            'إلى',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDateFromDateTime(dateRange!.end),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                'نظرة سريعة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStatItem(
                icon: Icons.inventory_2,
                value: '${allReadyBoxes.length}',
                label: 'جاهز',
                color: Colors.green,
              ),
              _buildQuickStatItem(
                icon: Icons.check_circle,
                value: '${allDistributedBoxes.length}',
                label: 'موزع',
                color: Colors.blue,
              ),
              _buildQuickStatItem(
                icon: Icons.warning,
                value: '${lowStockItems.length}',
                label: 'منخفض',
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSummaryStats(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.pie_chart, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'إحصائيات عامة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isSmallScreen ? 2 : 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                '📦',
                'إجمالي الأصناف',
                '${summaryData['total_items'] ?? 0}',
                AppColors.primary,
              ),
              _buildStatCard(
                '⚠️',
                'منخفض المخزون',
                '${summaryData['low_stock_items'] ?? 0}',
                Colors.orange,
              ),
              _buildStatCard(
                '✅',
                'كرتونات جاهزة',
                '${summaryData['ready_boxes'] ?? 0}',
                Colors.green,
              ),
              _buildStatCard(
                '📋',
                'كرتونات موزعة',
                '${summaryData['distributed_boxes'] ?? 0}',
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDistributions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.history, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'أحدث التوزيعات',
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${recentDistributions.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          recentDistributions.isEmpty
              ? const Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'لا توجد توزيعات حديثة',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentDistributions.length > 5
                      ? 5
                      : recentDistributions.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final dist = recentDistributions[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(
                          Icons.inventory,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        dist['type_name'] ?? 'كرتون',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'المستلم: ${dist['distributed_to'] ?? 'غير محدد'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDate(dist['distribution_date']),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  // ================== تبويب المخزون ==================
  Widget _buildInventoryTab(bool isSmallScreen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLowStockSection(),
          const SizedBox(height: 24),
          _buildInventoryStats(),
        ],
      ),
    );
  }

  Widget _buildLowStockSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.warning, color: Colors.red),
              ),
              const SizedBox(width: 12),
              const Text(
                'أصناف منخفضة المخزون',
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${lowStockItems.length}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          lowStockItems.isEmpty
              ? const Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'جميع الأصناف في المستوى المطلوب',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lowStockItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = lowStockItems[index];
                    final currentQty = (item['current_quantity'] ?? 0)
                        .toDouble();
                    final minQty = (item['min_quantity'] ?? 0).toDouble();
                    final percentage = minQty > 0 ? (currentQty / minQty) : 0;
                    final isCritical = percentage < 0.3;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? Colors.red.withOpacity(0.05)
                            : Colors.orange.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCritical
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isCritical ? Icons.warning : Icons.error_outline,
                              color: isCritical ? Colors.red : Colors.orange,
                              size: 20,
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
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'المخزون: $currentQty ${item['unit'] ?? ''}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'الحد: $minQty ${item['unit'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage > 1 ? 1 : percentage,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCritical ? Colors.red : Colors.orange,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              // إضافة مخزون
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildInventoryStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(Icons.pie_chart, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'توزيع المخزون',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInventoryStatItem(
                  label: 'كرتونات جاهزة',
                  value: allReadyBoxes.length,
                  color: Colors.green,
                  icon: Icons.inventory_2,
                ),
              ),
              Expanded(
                child: _buildInventoryStatItem(
                  label: 'كرتونات موزعة',
                  value: allDistributedBoxes.length,
                  color: Colors.blue,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInventoryStatItem(
                  label: 'إجمالي الأصناف',
                  value: summaryData['total_items'] ?? 0,
                  color: AppColors.primary,
                  icon: Icons.category,
                ),
              ),
              Expanded(
                child: _buildInventoryStatItem(
                  label: 'أنواع الكرتون',
                  value: topBoxTypes.length,
                  color: Colors.orange,
                  icon: Icons.inbox,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatItem({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
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
        children: [
          _buildTopBoxTypes(),
          const SizedBox(height: 24),
          _buildMonthlyStats(),
        ],
      ),
    );
  }

  Widget _buildTopBoxTypes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Text(
                'أكثر الأنواع توزيعاً',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          topBoxTypes.isEmpty
              ? const Center(
                  child: Column(
                    children: [
                      Icon(Icons.show_chart, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'لا توجد بيانات كافية',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topBoxTypes.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final type = topBoxTypes[index];
                    final total = (type['total_distributed'] ?? 0).toDouble();
                    final maxTotal = topBoxTypes.isNotEmpty
                        ? (topBoxTypes.first['total_distributed'] ?? 1)
                              .toDouble()
                        : 1.0;
                    final percentage = total / maxTotal;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
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
                                  type['type_name'] ?? 'غير محدد',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage,
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                    minHeight: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${total.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.trending_up, color: Colors.green),
              ),
              const SizedBox(width: 12),
              const Text(
                'التوزيعات الشهرية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          monthlyStats.isEmpty
              ? const Center(
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'لا توجد بيانات كافية',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: monthlyStats.map((stat) {
                    final month = stat['month'] ?? '';
                    final total = (stat['total_distributed'] ?? 0).toDouble();
                    final maxTotal = monthlyStats.isNotEmpty
                        ? (monthlyStats.first['total_distributed'] ?? 1)
                              .toDouble()
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
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.green,
                                ),
                                minHeight: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${total.toInt()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
        return '${months[month - 1]} $year';
      }
    } catch (e) {
      // تجاهل الخطأ
    }

    return monthStr;
  }

  Future<void> _generateDetailedReport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تقرير مفصل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            const Text('سيتم إنشاء تقرير مفصل شامل:'),
            const SizedBox(height: 8),
            const Text('• إحصائيات عامة'),
            const Text('• حالة المخزون'),
            const Text('• سجل التوزيعات'),
            const Text('• تحليلات الأداء'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // محاكاة إنشاء التقرير
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await Future.delayed(const Duration(seconds: 2));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إنشاء التقرير بنجاح'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'غير محدد';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateFromDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
