import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ReadyBoxesScreen extends StatefulWidget {
  const ReadyBoxesScreen({super.key});

  @override
  State<ReadyBoxesScreen> createState() => _ReadyBoxesScreenState();
}

class _ReadyBoxesScreenState extends State<ReadyBoxesScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> boxes = [];
  List<Map<String, dynamic>> boxTypes = [];
  List<Map<String, dynamic>> filteredBoxes = [];
  List<Map<String, dynamic>> individuals = [];
  List<Map<String, dynamic>> families = [];

  String? selectedStatus;
  int? selectedBoxTypeId;
  String searchQuery = '';

  // متغيرات التوزيع
  String? selectedRecipientType = 'individual';
  int? selectedIndividualId;
  int? selectedFamilyId;

  bool isLoading = true;

  late TabController _tabController;
  int _selectedTabIndex = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
        _filterBoxesByTab();
      });
    });
    _searchController.addListener(_onSearchChanged);

    // توحيد الحالات أولاً ثم تحميل البيانات
    _normalizeAndLoadData();
  }

  Future<void> _normalizeAndLoadData() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.normalizeBoxStatuses(); // توحيد الحالات
    await _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // دالة للتحقق من حالة الكرتون بشكل موحد
  bool _isStatus(String? boxStatus, String targetStatus) {
    if (boxStatus == null || boxStatus.toString().isEmpty) return false;

    final status = boxStatus.toString().toLowerCase().trim();

    switch (targetStatus) {
      case 'جاهز':
        return status == 'ready' ||
            status == 'جاهز' ||
            status.contains('ready') ||
            status.contains('جاهز') ||
            status == '1' || // إذا كان الرقم 1 يمثل جاهز
            status == 'جاهزة';
      case 'مستلم':
        return status == 'distributed' ||
            status == 'مستلم' ||
            status == 'delivered' ||
            status.contains('distributed') ||
            status.contains('مستلم') ||
            status == '2' || // إذا كان الرقم 2 يمثل مستلم
            status == 'موزع';
      case 'تالف':
        return status == 'damaged' ||
            status == 'تالف' ||
            status == 'damage' ||
            status.contains('damage') ||
            status.contains('تالف') ||
            status == '3'; // إذا كان الرقم 3 يمثل تالف
      default:
        return false;
    }
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filterBoxesByTab();
    });
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final dbHelper = DatabaseHelper();

    try {
      // التحقق من القيم أولاً
      await dbHelper.checkBoxStatusValues();

      // استعلام يجلب البيانات من ready_boxes مع ربطها بـ box_types
      final data = await dbHelper.rawQuery('''
        SELECT 
          rb.*,
          bt.type_name,
          bt.description as box_type_description
        FROM ready_boxes rb
        JOIN box_types bt ON rb.box_type_id = bt.id
        ORDER BY rb.prepared_at DESC
      ''');

      boxes = data;
      boxTypes = await dbHelper.getAllBoxTypes();

      // جلب الأفراد والعائلات للقوائم المنسدلة
      individuals = await dbHelper.getAllIndividualsForDropdown();
      families = await dbHelper.getAllFamiliesForDropdown();

      print('📦 تم تحميل ${boxes.length} كرتون');
      print('👤 تم تحميل ${individuals.length} فرد');
      print('👪 تم تحميل ${families.length} عائلة');

      _filterBoxesByTab();
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      _showErrorSnackBar('خطأ في تحميل البيانات: $e');
    }

    setState(() => isLoading = false);
  }

  void _filterBoxesByTab() {
    String targetStatus;
    switch (_selectedTabIndex) {
      case 0:
        targetStatus = 'جاهز';
        break;
      case 1:
        targetStatus = 'مستلم';
        break;
      case 2:
        targetStatus = 'تالف';
        break;
      default:
        targetStatus = 'جاهز';
    }

    filteredBoxes = boxes.where((box) {
      final boxStatus = box['status'];

      if (!_isStatus(boxStatus, targetStatus)) return false;

      if (selectedBoxTypeId != null &&
          box['box_type_id'] != selectedBoxTypeId) {
        return false;
      }

      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final typeName = (box['type_name'] ?? '').toString().toLowerCase();
        final boxNumber = (box['box_number'] ?? '').toString().toLowerCase();
        final preparedBy = (box['prepared_by'] ?? '').toString().toLowerCase();
        final distributedTo = (box['distributed_to'] ?? '')
            .toString()
            .toLowerCase();

        return typeName.contains(query) ||
            boxNumber.contains(query) ||
            preparedBy.contains(query) ||
            distributedTo.contains(query);
      }

      return true;
    }).toList();
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (_isStatus(status, 'جاهز')) return Colors.green;
    if (_isStatus(status, 'مستلم')) return Colors.blue;
    if (_isStatus(status, 'تالف')) return Colors.red;
    return Colors.grey;
  }

  String _getStatusArabic(String? status) {
    if (_isStatus(status, 'جاهز')) return 'جاهز للتوزيع';
    if (_isStatus(status, 'مستلم')) return 'تم التوزيع';
    if (_isStatus(status, 'تالف')) return 'تالف';
    return status ?? 'غير معروف';
  }

  IconData _getStatusIcon(String? status) {
    if (_isStatus(status, 'جاهز')) return Icons.check_circle;
    if (_isStatus(status, 'مستلم')) return Icons.local_shipping;
    if (_isStatus(status, 'تالف')) return Icons.warning;
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'الكرتونات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _normalizeAndLoadData,
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
            Tab(icon: Icon(Icons.check_circle), text: 'جاهزة'),
            Tab(icon: Icon(Icons.local_shipping), text: 'موزعة'),
            Tab(icon: Icon(Icons.warning), text: 'تالفة'),
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
                    'جاري تحميل الكرتونات...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildFilterSection(),
                _buildStatsSection(),
                _buildSearchSection(),
                Expanded(child: _buildBoxesList()),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'تصفية الكرتونات',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filteredBoxes.length} كرتون',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedBoxTypeId,
                  decoration: InputDecoration(
                    labelText: 'نوع الكرتون',
                    prefixIcon: const Icon(Icons.category, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('جميع الأنواع'),
                    ),
                    ...boxTypes.map(
                      (type) => DropdownMenuItem(
                        value: type['id'],
                        child: Text(type['type_name']),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedBoxTypeId = value;
                      _filterBoxesByTab();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      selectedBoxTypeId = null;
                      _filterBoxesByTab();
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final readyCount = boxes
        .where((b) => _isStatus(b['status'], 'جاهز'))
        .length;
    final distributedCount = boxes
        .where((b) => _isStatus(b['status'], 'مستلم'))
        .length;
    final damagedCount = boxes
        .where((b) => _isStatus(b['status'], 'تالف'))
        .length;
    final totalCount = boxes.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('جاهز', readyCount, Colors.green, Icons.check_circle),
          _buildStatItem(
            'موزع',
            distributedCount,
            Colors.blue,
            Icons.local_shipping,
          ),
          _buildStatItem('تالف', damagedCount, Colors.red, Icons.warning),
          _buildStatItem('إجمالي', totalCount, Colors.white, Icons.inventory),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, int count, Color color, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'بحث بالاسم، الرقم، أو المستلم...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBoxesList() {
    if (filteredBoxes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyStateIcon(),
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubMessage(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBoxes.length,
      itemBuilder: (context, index) {
        final box = filteredBoxes[index];
        return _buildBoxCard(box);
      },
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedTabIndex) {
      case 0:
        return Icons.inventory_2_outlined;
      case 1:
        return Icons.local_shipping_outlined;
      case 2:
        return Icons.warning_amber_outlined;
      default:
        return Icons.inbox;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTabIndex) {
      case 0:
        return 'لا توجد كرتونات جاهزة';
      case 1:
        return 'لا توجد كرتونات موزعة';
      case 2:
        return 'لا توجد كرتونات تالفة';
      default:
        return 'لا توجد بيانات';
    }
  }

  String _getEmptyStateSubMessage() {
    switch (_selectedTabIndex) {
      case 0:
        return 'قم بتجهيز كرتونات جديدة من شاشة التجهيز';
      case 1:
        return 'سيظهر هنا الكرتونات التي تم توزيعها';
      case 2:
        return 'سيظهر هنا الكرتونات المسجلة كتالفة';
      default:
        return '';
    }
  }

  Widget _buildBoxCard(Map<String, dynamic> box) {
    final status = box['status'];
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusArabic(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          onTap: () => _showBoxDetails(box),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // الصف العلوي: الحالة والرقم
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${box['box_number'] ?? box['id']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // نوع الكرتون
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'نوع الكرتون',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            box['type_name'] ?? 'نوع غير محدد',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // معلومات إضافية
                Row(
                  children: [
                    // تاريخ التجهيز
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              box['prepared_date'] != null
                                  ? _formatDate(box['prepared_date'])
                                  : 'بدون تاريخ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // المجهز
                    if (box['prepared_by'] != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                box['prepared_by'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // معلومات التوزيع (إذا كانت موجودة)
                if (_isStatus(status, 'مستلم') &&
                    box['distributed_to'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المستلم: ${_formatRecipientName(box['distributed_to'])}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (box['distributed_date'] != null)
                                Text(
                                  'تاريخ التوزيع: ${_formatDate(box['distributed_date'])}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // الملاحظات (إذا كانت موجودة)
                if (box['notes'] != null &&
                    box['notes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            box['notes'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // أزرار الإجراءات
                Row(
                  children: [
                    if (_isStatus(status, 'جاهز'))
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showDistributeDialog(box),
                          icon: const Icon(Icons.local_shipping, size: 16),
                          label: const Text('توزيع'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                    if (_isStatus(status, 'جاهز')) const SizedBox(width: 8),

                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showBoxDetails(box),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('عرض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditBoxDialog(box);
                          } else if (value == 'damage') {
                            _showMarkAsDamagedDialog(box);
                          } else if (value == 'delete') {
                            _showDeleteBoxDialog(box);
                          }
                        },
                        icon: const Icon(Icons.more_vert, size: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 8),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                          if (!_isStatus(status, 'تالف'))
                            const PopupMenuItem(
                              value: 'damage',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 8),
                                  Text('تسجيل كتالف'),
                                ],
                              ),
                            ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  String _formatRecipientName(String? recipientInfo) {
    if (recipientInfo == null) return 'غير محدد';
    if (!recipientInfo.contains('|')) return recipientInfo;

    final parts = recipientInfo.split('|');
    if (parts.length >= 3) {
      final type = parts[0] == 'individual' ? 'فرد' : 'عائلة';
      return '$type: ${parts[2]}';
    }
    return recipientInfo;
  }

  // ================== دالة توزيع الكرتون المحسنة ==================
  void _showDistributeDialog(Map<String, dynamic> box) {
    // إعادة تعيين المتغيرات
    selectedRecipientType = 'individual';
    selectedIndividualId = null;
    selectedFamilyId = null;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('توزيع الكرتون'),
            content: SingleChildScrollView(
              child: Container(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // معلومات الكرتون
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  box['type_name'] ?? 'كرتون',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'رقم: ${box['box_number'] ?? box['id']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // اختيار نوع المستلم
                    const Text(
                      'نوع المستلم:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, size: 16),
                                SizedBox(width: 4),
                                Text('فرد'),
                              ],
                            ),
                            selected: selectedRecipientType == 'individual',
                            onSelected: (selected) {
                              setState(() {
                                selectedRecipientType = 'individual';
                                selectedIndividualId = null;
                                selectedFamilyId = null;
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.family_restroom, size: 16),
                                SizedBox(width: 4),
                                Text('عائلة'),
                              ],
                            ),
                            selected: selectedRecipientType == 'family',
                            onSelected: (selected) {
                              setState(() {
                                selectedRecipientType = 'family';
                                selectedIndividualId = null;
                                selectedFamilyId = null;
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            backgroundColor: Colors.grey[100],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // قائمة الأفراد المنسدلة
                    if (selectedRecipientType == 'individual') ...[
                      const Text(
                        'اختر الفرد:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: selectedIndividualId,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('-- اختر الفرد --'),
                          isExpanded: true,
                          items: [
                            ...individuals.map(
                              (individual) => DropdownMenuItem(
                                value: individual['id'],
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        individual['full_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedIndividualId = value;
                            });
                          },
                        ),
                      ),
                    ],

                    // قائمة العائلات المنسدلة
                    if (selectedRecipientType == 'family') ...[
                      const Text(
                        'اختر العائلة:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: selectedFamilyId,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          hint: const Text('-- اختر العائلة --'),
                          isExpanded: true,
                          items: [
                            ...families.map(
                              (family) => DropdownMenuItem(
                                value: family['id'],
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.family_restroom,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            family['family_name'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (family['family_address'] != null)
                                            Text(
                                              family['family_address'],
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedFamilyId = value;
                            });
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // ملاحظات
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        hintText: 'أضف ملاحظات حول التوزيع...',
                        prefixIcon: const Icon(Icons.note, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed:
                    (selectedRecipientType == 'individual' &&
                            selectedIndividualId == null) ||
                        (selectedRecipientType == 'family' &&
                            selectedFamilyId == null)
                    ? null
                    : () async {
                        // الحصول على اسم المستلم
                        String recipientName = '';
                        int recipientId = 0;

                        if (selectedRecipientType == 'individual') {
                          final individual = individuals.firstWhere(
                            (ind) => ind['id'] == selectedIndividualId,
                            orElse: () => {},
                          );
                          recipientName =
                              individual['full_name'] ?? 'فرد غير معروف';
                          recipientId = selectedIndividualId!;
                        } else {
                          final family = families.firstWhere(
                            (fam) => fam['id'] == selectedFamilyId,
                            orElse: () => {},
                          );
                          recipientName =
                              family['family_name'] ?? 'عائلة غير معروفة';
                          recipientId = selectedFamilyId!;
                        }

                        Navigator.pop(context);

                        await _distributeBox(
                          box['id'],
                          recipientName,
                          recipientId,
                          notesController.text,
                          selectedRecipientType!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('تسجيل التوزيع'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _distributeBox(
    int boxId,
    String recipientName,
    int recipientId,
    String notes,
    String recipientType,
  ) async {
    try {
      final dbHelper = DatabaseHelper();

      // تخزين معلومات المستلم مع الـ ID والاسم
      final recipientInfo = '$recipientType|$recipientId|$recipientName';

      await dbHelper.distributeReadyBox(boxId, recipientInfo, notes);

      if (mounted) {
        _showSuccessSnackBar('تم تسجيل التوزيع بنجاح ✅');
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في التوزيع: $e');
      }
    }
  }

  void _showBoxDetails(Map<String, dynamic> box) {
    String recipientDisplay = _formatRecipientName(box['distributed_to']);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getStatusColor(box['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(box['status']),
                      color: _getStatusColor(box['status']),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تفاصيل الكرتون',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '#${box['box_number'] ?? box['id']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              _buildDetailItem(
                'نوع الكرتون',
                box['type_name'] ?? 'غير محدد',
                Icons.category,
              ),
              _buildDetailItem(
                'الحالة',
                _getStatusArabic(box['status']),
                Icons.info,
              ),

              if (box['prepared_by'] != null)
                _buildDetailItem('المجهز', box['prepared_by'], Icons.person),

              if (box['prepared_date'] != null)
                _buildDetailItem(
                  'تاريخ التجهيز',
                  _formatDate(box['prepared_date']),
                  Icons.calendar_today,
                ),

              if (box['distributed_to'] != null)
                _buildDetailItem(
                  'المستلم',
                  recipientDisplay,
                  Icons.person_outline,
                ),

              if (box['distributed_date'] != null)
                _buildDetailItem(
                  'تاريخ التوزيع',
                  _formatDate(box['distributed_date']),
                  Icons.event,
                ),

              if (box['notes'] != null && box['notes'].toString().isNotEmpty)
                _buildDetailItem('ملاحظات', box['notes'], Icons.note),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditBoxDialog(Map<String, dynamic> box) {
    final notesController = TextEditingController(text: box['notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الكرتون'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'كرتون: ${box['type_name']} - #${box['box_number'] ?? box['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'أضف ملاحظات حول الكرتون...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showSuccessSnackBar('تم تحديث الكرتون بنجاح');
              await _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showMarkAsDamagedDialog(Map<String, dynamic> box) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل كتالف'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'كرتون: ${box['type_name']} - #${box['box_number'] ?? box['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'سبب التلف',
                  hintText: 'وصف سبب تلف الكرتون',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: reasonController.text.isEmpty
                ? null
                : () async {
                    Navigator.pop(context);
                    _showSuccessSnackBar('تم تسجيل الكرتون كتالف');
                    await _loadData();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }

  void _showDeleteBoxDialog(Map<String, dynamic> box) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(
                'هل أنت متأكد من حذف الكرتون رقم ${box['box_number'] ?? box['id']}؟',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'لا يمكن التراجع عن هذا الإجراء',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showSuccessSnackBar('تم حذف الكرتون بنجاح');
              await _loadData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
