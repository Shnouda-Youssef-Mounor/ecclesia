import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> donations = [];
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredDonations = [];

  bool isLoading = true;
  String searchQuery = '';
  int? selectedItemId;

  late TabController _tabController;
  int _selectedTabIndex = 0;

  final TextEditingController searchController = TextEditingController();
  final Map<int, int> itemStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
        _filterDonations();
      });
    });
    searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
      _filterDonations();
    });
  }

  void _filterDonations() {
    filteredDonations = donations.where((donation) {
      // فلترة حسب التبويب
      if (_selectedTabIndex == 1 && selectedItemId != null) {
        if (donation['item_id'] != selectedItemId) return false;
      }

      // فلترة حسب البحث
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final itemName = (donation['item_name'] ?? '').toString().toLowerCase();
        final donor = (donation['notes'] ?? '').toString().toLowerCase();

        return itemName.contains(query) || donor.contains(query);
      }

      return true;
    }).toList();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final dbHelper = DatabaseHelper();

    try {
      // جلب سجل التبرعات
      donations = await dbHelper.rawQuery('''
        SELECT t.*, i.item_name, i.unit 
        FROM inventory_transactions t
        JOIN inventory_items i ON t.item_id = i.id
        WHERE t.transaction_type = 'دخول' OR t.transaction_type = 'تبرع'
        ORDER BY t.transaction_date DESC
      ''');

      // جلب جميع الأصناف
      allItems = await dbHelper.getAllInventoryItems();

      // حساب إحصائيات لكل صنف
      for (var item in allItems) {
        final count = donations.where((d) => d['item_id'] == item['id']).length;
        itemStats[item['id']] = count;
      }

      filteredDonations = List.from(donations);

      print('✅ تم تحميل ${donations.length} تبرع');
    } catch (e) {
      print('❌ خطأ في تحميل البيانات: $e');
      _showErrorSnackBar('خطأ في تحميل البيانات: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        foregroundColor: Colors.white,
        title: const Text(
          'التبرعات',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
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
            Tab(icon: Icon(Icons.all_inbox), text: 'كل التبرعات'),
            Tab(icon: Icon(Icons.category), text: 'حسب الصنف'),
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
                    'جاري تحميل التبرعات...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                _buildStatsSection(),
                _buildSearchSection(),
                if (_selectedTabIndex == 1) _buildItemFilter(),
                Expanded(child: _buildDonationsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDonationDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'تبرع جديد',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalDonations = donations.length;
    final totalQuantity = donations.fold<int>(
      0,
      (sum, item) => sum + ((item['quantity_change'] as int?)?.abs() ?? 0),
    );
    final uniqueItems = donations.map((d) => d['item_id']).toSet().length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
          _buildStatItem(Icons.card_giftcard, 'إجمالي', totalDonations),
          _buildStatItem(Icons.inventory, 'أصناف', uniqueItems),
          _buildStatItem(Icons.monetization_on, 'كمية', totalQuantity),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'بحث باسم الصنف أو المتبرع...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
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

  Widget _buildItemFilter() {
    if (allItems.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allItems.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip('الكل', null);
          }
          final item = allItems[index - 1];
          final count = itemStats[item['id']] ?? 0;
          return _buildFilterChip('${item['item_name']} ($count)', item['id']);
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int? itemId) {
    final isSelected = selectedItemId == itemId;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedItemId = selected ? itemId : null;
            _filterDonations();
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildDonationsList() {
    if (filteredDonations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubMessage(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDonationDialog,
              icon: const Icon(Icons.add),
              label: const Text('تسجيل أول تبرع'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDonations.length,
      itemBuilder: (context, index) {
        final donation = filteredDonations[index];
        return _buildDonationCard(donation);
      },
    );
  }

  String _getEmptyStateMessage() {
    if (_selectedTabIndex == 1 && selectedItemId != null) {
      return 'لا توجد تبرعات لهذا الصنف';
    }
    if (searchQuery.isNotEmpty) {
      return 'لا توجد نتائج للبحث';
    }
    return 'لا توجد تبرعات مسجلة';
  }

  String _getEmptyStateSubMessage() {
    if (_selectedTabIndex == 1 && selectedItemId != null) {
      return 'اختر صنف آخر أو سجل تبرع جديد';
    }
    if (searchQuery.isNotEmpty) {
      return 'جرب كلمات بحث أخرى';
    }
    return 'سجل أول تبرع للمخزون';
  }

  Widget _buildDonationCard(Map<String, dynamic> donation) {
    final quantity = donation['quantity_change']?.abs() ?? 0;
    final date = donation['transaction_date'];
    final donor = _extractDonorName(donation['notes'] ?? 'تبرع مجهول');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
        child: InkWell(
          onTap: () => _showDonationDetails(donation),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation['item_name'] ?? 'صنف غير محدد',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              donor,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+$quantity',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        donation['unit'] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _extractDonorName(String notes) {
    if (notes.startsWith('تبرع')) {
      if (notes.contains('من')) {
        final parts = notes.split('من');
        if (parts.length > 1) {
          return parts[1].split('-')[0].trim();
        }
      }
    }
    return notes;
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.card_giftcard,
                      color: Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'تفاصيل التبرع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                'الصنف',
                donation['item_name'] ?? 'غير محدد',
                Icons.category,
              ),
              _buildDetailItem(
                'الكمية',
                '+${donation['quantity_change']?.abs() ?? 0} ${donation['unit'] ?? ''}',
                Icons.numbers,
              ),
              _buildDetailItem(
                'المتبرع',
                _extractDonorName(donation['notes'] ?? 'غير محدد'),
                Icons.person,
              ),
              _buildDetailItem(
                'التاريخ',
                _formatDate(donation['transaction_date']),
                Icons.calendar_today,
              ),

              if (donation['notes'] != null &&
                  donation['notes'].toString().isNotEmpty)
                _buildDetailItem('ملاحظات', donation['notes'], Icons.note),
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

  void _showAddDonationDialog() {
    int? selectedItemId;
    Map<String, dynamic>? selectedItem;
    final quantityController = TextEditingController();
    final donorController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'تسجيل تبرع جديد',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Container(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // اختيار الصنف
                    const Text(
                      'اختر الصنف:',
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
                        value: selectedItemId,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('-- اختر الصنف --'),
                        isExpanded: true,
                        items: [
                          ...allItems.map(
                            (item) => DropdownMenuItem(
                              value: item['id'],
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.inventory,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item['item_name']} (${item['unit']})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
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
                            selectedItemId = value;
                            selectedItem = allItems.firstWhere(
                              (element) => element['id'] == value,
                              orElse: () => {},
                            );
                          });
                        },
                      ),
                    ),

                    if (selectedItem != null) ...[
                      const SizedBox(height: 16),

                      // إدخال الكمية
                      const Text(
                        'الكمية:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'أدخل الكمية',
                          suffixText: selectedItem!['unit'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // اسم المتبرع
                      const Text(
                        'المتبرع:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: donorController,
                        decoration: InputDecoration(
                          hintText: 'اسم المتبرع (اختياري)',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ملاحظات
                      const Text(
                        'ملاحظات:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'أضف ملاحظات (اختياري)',
                          prefixIcon: const Icon(
                            Icons.note,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
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
                    selectedItem == null || quantityController.text.isEmpty
                    ? null
                    : () async {
                        final quantity =
                            int.tryParse(quantityController.text) ?? 0;
                        if (quantity > 0) {
                          Navigator.pop(context);
                          await _saveDonation(
                            selectedItem!,
                            quantity,
                            donorController.text,
                            notesController.text,
                          );
                        }
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
                child: const Text('تسجيل التبرع'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveDonation(
    Map<String, dynamic> item,
    int quantity,
    String donor,
    String notes,
  ) async {
    try {
      final dbHelper = DatabaseHelper();

      String note = 'تبرع';
      if (donor.isNotEmpty) {
        note += ' من $donor';
      }
      if (notes.isNotEmpty) {
        note += ' - $notes';
      }

      await dbHelper.updateInventoryQuantity(item['id'], quantity, note);

      if (mounted) {
        _showSuccessSnackBar(
          'تم تسجيل تبرع $quantity ${item['unit']} من ${item['item_name']} ✅',
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('خطأ في تسجيل التبرع: $e');
      }
    }
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
}
