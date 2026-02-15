import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class ItemsManagementScreen extends StatefulWidget {
  const ItemsManagementScreen({super.key});

  @override
  State<ItemsManagementScreen> createState() => _ItemsManagementScreenState();
}

class _ItemsManagementScreenState extends State<ItemsManagementScreen> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String selectedCategory = 'الكل';
  String selectedSort = 'الأحدث';

  final List<String> categories = [
    'الكل',
    'طعام',
    'ملابس',
    'أدوات',
    'طقسي',
    'تعليمي',
    'صحي',
    'أخرى',
  ];

  final List<String> sortOptions = [
    'الأحدث',
    'الأقل مخزوناً',
    'الأعلى مخزوناً',
    'الأبجدي',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      items = await dbHelper.getAllInventoryItems();
      _filterAndSortItems();
    } catch (e) {
      _showErrorSnackbar('خطأ في تحميل الأصناف: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _filterAndSortItems() {
    filteredItems = List.from(items);

    // فلترة حسب الفئة
    if (selectedCategory != 'الكل') {
      filteredItems = filteredItems
          .where((item) => item['category'] == selectedCategory)
          .toList();
    }

    // فلترة حسب البحث
    if (searchController.text.isNotEmpty) {
      final searchText = searchController.text.toLowerCase();
      filteredItems = filteredItems
          .where(
            (item) =>
                (item['item_name']?.toString().toLowerCase().contains(
                      searchText,
                    ) ??
                    false) ||
                (item['category']?.toString().toLowerCase().contains(
                      searchText,
                    ) ??
                    false),
          )
          .toList();
    }

    // ترتيب النتائج
    switch (selectedSort) {
      case 'الأحدث':
        filteredItems.sort((a, b) {
          final dateA = DateTime.parse(a['created_at'] ?? '2020-01-01');
          final dateB = DateTime.parse(b['created_at'] ?? '2020-01-01');
          return dateB.compareTo(dateA);
        });
        break;
      case 'الأقل مخزوناً':
        filteredItems.sort((a, b) {
          final qtyA = a['current_quantity'] ?? 0;
          final qtyB = b['current_quantity'] ?? 0;
          return qtyA.compareTo(qtyB);
        });
        break;
      case 'الأعلى مخزوناً':
        filteredItems.sort((a, b) {
          final qtyA = a['current_quantity'] ?? 0;
          final qtyB = b['current_quantity'] ?? 0;
          return qtyB.compareTo(qtyA);
        });
        break;
      case 'الأبجدي':
        filteredItems.sort((a, b) {
          final nameA = a['item_name']?.toString() ?? '';
          final nameB = b['item_name']?.toString() ?? '';
          return nameA.compareTo(nameB);
        });
        break;
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditItemDialog(),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text('صنف جديد'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'إدارة الأصناف',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _loadItems,
                              tooltip: 'تحديث',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '🔍 ابحث عن صنف...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: Colors.grey.shade500,
                              ),
                              onPressed: () {
                                searchController.clear();
                                _filterAndSortItems();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      _filterAndSortItems();
                      setState(() {});
                    },
                  ),
                ),

                // Filters Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildFilterChip('الفئة', selectedCategory, (
                          value,
                        ) {
                          selectedCategory = value;
                          _filterAndSortItems();
                          setState(() {});
                        }, categories),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterChip('الترتيب', selectedSort, (
                          value,
                        ) {
                          selectedSort = value;
                          _filterAndSortItems();
                          setState(() {});
                        }, sortOptions),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildStatCard(
                        title: 'إجمالي الأصناف',
                        value: items.length.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'ناقص المخزون',
                        value: items
                            .where(
                              (item) =>
                                  (item['current_quantity'] ?? 0) <=
                                  (item['min_quantity'] ?? 0),
                            )
                            .length
                            .toString(),
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFE74C3C),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'ممتلئ',
                        value: items
                            .where(
                              (item) =>
                                  (item['current_quantity'] ?? 0) >
                                  (item['min_quantity'] ?? 0) * 2,
                            )
                            .length
                            .toString(),
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF2ECC71),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Items List
                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredItems.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return _buildModernItemCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    Function(String) onSelected,
    List<String> options,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          underline: const SizedBox(),
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.textSecondary,
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Row(
                children: [
                  Icon(
                    _getFilterIcon(label, option),
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(option),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onSelected(value);
          },
        ),
      ),
    );
  }

  IconData _getFilterIcon(String label, String option) {
    if (label == 'الفئة') {
      switch (option) {
        case 'طعام':
          return Icons.restaurant_rounded;
        case 'ملابس':
          return Icons.checkroom_rounded;
        case 'طقسي':
          return Icons.church_rounded;
        default:
          return Icons.category_rounded;
      }
    } else {
      switch (option) {
        case 'الأحدث':
          return Icons.access_time_rounded;
        case 'الأقل مخزوناً':
          return Icons.trending_down_rounded;
        case 'الأعلى مخزوناً':
          return Icons.trending_up_rounded;
        default:
          return Icons.sort_by_alpha_rounded;
      }
    }
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernItemCard(Map<String, dynamic> item) {
    final currentQty = item['current_quantity'] ?? 0;
    final minQty = item['min_quantity'] ?? 1;
    final isLowStock = currentQty <= minQty;
    final isCritical = currentQty == 0;
    final percentage = (currentQty / (minQty * 2)).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showItemDetailsDialog(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          item['category'],
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          item['item_name'][0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _getCategoryColor(item['category']),
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
                            item['item_name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['category'] ?? 'غير محدد',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) => _handleMenuItem(value, item),
                      itemBuilder: (context) => [
                        _buildPopupMenuItem(
                          'تعديل',
                          Icons.edit_rounded,
                          Colors.blue,
                        ),
                        _buildPopupMenuItem(
                          'إضافة كمية',
                          Icons.add_box_rounded,
                          Colors.green,
                        ),
                        _buildPopupMenuItem(
                          'سحب كمية',
                          Icons.indeterminate_check_box_rounded,
                          Colors.orange,
                        ),
                        const PopupMenuDivider(),
                        _buildPopupMenuItem(
                          'حذف',
                          Icons.delete_rounded,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Container(
                      height: 6,
                      width:
                          MediaQuery.of(context).size.width * 0.7 * percentage,
                      decoration: BoxDecoration(
                        color: isCritical
                            ? Colors.red
                            : isLowStock
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$currentQty ${item['unit']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? Colors.red.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCritical
                                ? Colors.red.shade100
                                : Colors.orange.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCritical
                                  ? Icons.error_outline_rounded
                                  : Icons.warning_amber_rounded,
                              size: 12,
                              color: isCritical ? Colors.red : Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCritical ? 'منتهي' : 'تحت الحد',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isCritical ? Colors.red : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (item['location'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item['location']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد أصناف',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedCategory != 'الكل'
                ? 'جرب تغيير الفئة أو البحث'
                : 'اضغط على + لإضافة صنف جديد',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String text,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  void _handleMenuItem(String value, Map<String, dynamic> item) {
    switch (value) {
      case 'تعديل':
        _showAddEditItemDialog(item: item);
        break;
      case 'إضافة كمية':
        _showStockDialog(item, isAdd: true);
        break;
      case 'سحب كمية':
        _showStockDialog(item, isAdd: false);
        break;
      case 'حذف':
        _showDeleteDialog(item);
        break;
    }
  }

  Color _getCategoryColor(String? category) {
    final colors = {
      'طعام': const Color(0xFF2ECC71),
      'ملابس': const Color(0xFF3498DB),
      'أدوات': const Color(0xFF9B59B6),
      'طقسي': const Color(0xFFE74C3C),
      'تعليمي': const Color(0xFFF39C12),
      'صحي': const Color(0xFF1ABC9C),
      'أخرى': Colors.grey,
    };
    return colors[category] ?? AppColors.primary;
  }

  void _showItemDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        item['category'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: _getCategoryColor(item['category']),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['item_name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item['category'] ?? 'غير محدد',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ..._buildDetailRow('الوحدة', item['unit'] ?? '-'),
              ..._buildDetailRow(
                'الكمية الحالية',
                '${item['current_quantity'] ?? 0} ${item['unit']}',
              ),
              ..._buildDetailRow(
                'الحد الأدنى',
                '${item['min_quantity'] ?? 0} ${item['unit']}',
              ),
              if (item['location'] != null)
                ..._buildDetailRow('الموقع', item['location']!),
              if (item['notes'] != null && item['notes'].isNotEmpty)
                ..._buildDetailRow('ملاحظات', item['notes']!),
              ..._buildDetailRow('تاريخ الإضافة', item['created_at'] ?? '-'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditItemDialog(item: item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('تعديل'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetailRow(String label, String value) {
    return [
      const SizedBox(height: 12),
      Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    ];
  }

  void _showAddEditItemDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameController = TextEditingController(text: item?['item_name']);
    final categoryController = TextEditingController(text: item?['category']);
    final unitController = TextEditingController(text: item?['unit']);
    final minQtyController = TextEditingController(
      text: item?['min_quantity']?.toString() ?? '0',
    );
    final currQtyController = TextEditingController(
      text: item?['storage_unit']?.toString() ?? '0',
    );
    final locationController = TextEditingController(text: item?['location']);
    final notesController = TextEditingController(text: item?['notes']);

    final categories = [
      'طعام',
      'ملابس',
      'أدوات',
      'طقسي',
      'تعليمي',
      'صحي',
      'أخرى',
    ];
    final units = ['كيلو', 'جرام', 'لتر', 'قطعة', 'علبة', 'كرتون', 'زوج'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'تعديل صنف' : 'إضافة صنف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الصنف',
                  prefixIcon: Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoryController.text.isEmpty
                    ? null
                    : categoryController.text,
                decoration: const InputDecoration(
                  labelText: 'الفئة',
                  prefixIcon: Icon(Icons.category),
                ),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) => categoryController.text = value!,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: unitController.text.isEmpty ? null : unitController.text,
                decoration: const InputDecoration(
                  labelText: 'الوحدة',
                  prefixIcon: Icon(Icons.scale),
                ),
                items: units
                    .map(
                      (unit) =>
                          DropdownMenuItem(value: unit, child: Text(unit)),
                    )
                    .toList(),
                onChanged: (value) => unitController.text = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minQtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الحد الأدنى للإعادة',
                  prefixIcon: Icon(Icons.warning),
                ),
              ),
              const SizedBox(height: 12),
              if (!isEdit)
                TextField(
                  controller: currQtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية الحالية',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'الموقع (اختياري)',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.notes),
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
              final dbHelper = DatabaseHelper();
              final newItem = {
                'item_name': nameController.text,
                'category': categoryController.text,
                'unit': unitController.text,
                'min_quantity': int.tryParse(minQtyController.text) ?? 0,
                'storage_unit': int.tryParse(currQtyController.text) ?? 0,
                'location': locationController.text,
                'notes': notesController.text,
                'updated_at': DateTime.now().toIso8601String(),
              };

              if (isEdit) {
                await dbHelper.updateInventoryItem(item!['id'], newItem);
              } else {
                newItem['current_quantity'] =
                    int.tryParse(currQtyController.text) ?? 0;
                newItem['created_at'] = DateTime.now().toIso8601String();
                await dbHelper.insertInventoryItem(newItem);
              }

              Navigator.pop(context);
              _loadItems();
            },
            child: Text(isEdit ? 'تحديث' : 'إضافة'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف الصنف "${item['item_name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dbHelper = DatabaseHelper();
                await dbHelper.deleteInventoryItem(item['id']);
                Navigator.pop(context);
                _loadItems();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('تم حذف الصنف "${item['item_name']}"'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showStockDialog(Map<String, dynamic> item, {required bool isAdd}) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final currentQty = item['current_quantity'] ?? 0;
    final unit = item['unit'] ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isAdd
                                ? const Color(0xFF2ECC71).withOpacity(0.1)
                                : const Color(0xFFE74C3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isAdd
                                ? Icons.add_circle_rounded
                                : Icons.remove_circle_rounded,
                            color: isAdd
                                ? const Color(0xFF2ECC71)
                                : const Color(0xFFE74C3C),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdd ? 'إضافة كمية' : 'سحب كمية',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                item['item_name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Current stock info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المخزون الحالي',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$currentQty $unit',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          if (!isAdd)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'الحد الأدنى',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['min_quantity'] ?? 0} $unit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        (item['min_quantity'] ?? 0) > currentQty
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quantity input
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'الكمية ($unit)',
                        hintText: isAdd
                            ? 'أدخل الكمية المضافة'
                            : 'أدخل الكمية المسحوبة',
                        prefixIcon: const Icon(Icons.numbers_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            final current =
                                int.tryParse(quantityController.text) ?? 0;
                            quantityController.text = (current + 1).toString();
                            setState(() {});
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 16),

                    // Warning for insufficient stock
                    if (!isAdd)
                      FutureBuilder<int>(
                        future: _calculateAvailableQuantity(
                          item,
                          quantityController.text,
                        ),
                        builder: (context, snapshot) {
                          final availableQty = snapshot.data ?? currentQty;
                          final requestedQty =
                              int.tryParse(quantityController.text) ?? 0;
                          final isInsufficient = requestedQty > availableQty;

                          if (quantityController.text.isNotEmpty &&
                              isInsufficient) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade100,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'المخزون المتاح: $availableQty $unit فقط',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),

                    const SizedBox(height: 16),

                    // Reason input
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'السبب',
                        hintText: isAdd
                            ? 'مثال: تبرع، شراء، إرجاع...'
                            : 'مثال: تجهيز كرتون، تلف، إعارة...',
                        prefixIcon: const Icon(Icons.note_add_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 8),

                    // Suggested reasons
                    if (isAdd)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildReasonChip('تبرع', reasonController, setState),
                          _buildReasonChip('شراء', reasonController, setState),
                          _buildReasonChip('إرجاع', reasonController, setState),
                          _buildReasonChip('هدية', reasonController, setState),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildReasonChip(
                            'تجهيز كرتون',
                            reasonController,
                            setState,
                          ),
                          _buildReasonChip('تلف', reasonController, setState),
                          _buildReasonChip('إعارة', reasonController, setState),
                          _buildReasonChip('هبة', reasonController, setState),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Preview of new quantity
                    if (quantityController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.light.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$currentQty',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isAdd
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_back_rounded,
                              color: isAdd ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _calculateNewQuantity(
                                currentQty,
                                quantityController.text,
                                isAdd,
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isAdd ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              unit,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'إلغاء',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _submitStockChange(
                              item,
                              quantityController.text,
                              reasonController.text,
                              isAdd,
                              context,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: isAdd
                                  ? const Color(0xFF2ECC71)
                                  : const Color(0xFFE74C3C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'تأكيد',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<int> _calculateAvailableQuantity(
    Map<String, dynamic> item,
    String requestedQuantity,
  ) async {
    // يمكن هنا حساب الكمية المتاحة بناءً على الكميات المحجوزة في المستقبل
    // أو أي قيود أخرى
    final currentQty = item['current_quantity'] ?? 0;
    return currentQty;
  }

  Widget _buildReasonChip(
    String text,
    TextEditingController controller,
    StateSetter setState,
  ) {
    return GestureDetector(
      onTap: () {
        controller.text = text;
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.light.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.light.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(color: AppColors.primary, fontSize: 12),
        ),
      ),
    );
  }

  String _calculateNewQuantity(int current, String input, bool isAdd) {
    final quantity = int.tryParse(input) ?? 0;
    if (isAdd) {
      return (current + quantity).toString();
    } else {
      final newQty = current - quantity;
      return newQty >= 0 ? newQty.toString() : '0';
    }
  }

  Future<void> _submitStockChange(
    Map<String, dynamic> item,
    String quantityText,
    String reason,
    bool isAdd,
    BuildContext context,
  ) async {
    final quantity = int.tryParse(quantityText) ?? 0;
    final currentQty = item['current_quantity'] ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('الرجاء إدخال كمية صحيحة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!isAdd && quantity > currentQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن سحب $quantity ، المتاح فقط $currentQty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.updateInventoryQuantity(
        item['id'],
        isAdd ? quantity : -quantity,
        reason.isEmpty ? (isAdd ? 'إضافة يدوية' : 'سحب يدوي') : reason,
      );

      Navigator.pop(context);

      // إظهار رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isAdd ? Icons.check_circle : Icons.remove_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAdd
                      ? '✅ تم إضافة $quantity ${item['unit']} بنجاح'
                      : '✅ تم سحب $quantity ${item['unit']} بنجاح',
                ),
              ),
            ],
          ),
          backgroundColor: isAdd ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // إعادة تحميل البيانات
      _loadItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('خطأ: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
