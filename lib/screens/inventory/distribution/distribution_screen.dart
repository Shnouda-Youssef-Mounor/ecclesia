import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/screens/inventory/box/prepare_boxes_screen.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class DistributionScreen extends StatefulWidget {
  const DistributionScreen({super.key});

  @override
  State<DistributionScreen> createState() => _DistributionScreenState();
}

class _DistributionScreenState extends State<DistributionScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> readyBoxes = [];
  List<Map<String, dynamic>> allFamilies = [];
  List<Map<String, dynamic>> allIndividuals = [];

  // قوائم متعددة للتوزيع على عدة مستلمين
  List<RecipientSelection> recipients = [];
  List<Map<String, dynamic>> selectedBoxes = [];

  bool isLoading = true;
  String searchQuery = '';
  String? selectedRecipientType; // 'family' or 'individual'

  late TabController _tabController;
  int _selectedTabIndex = 0;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  // أضف هذه الدالة الجديدة لفتح نافذة اختيار المستلم
  Future<void> _showRecipientPicker(RecipientSelection recipient) async {
    String searchQuery = '';

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Map<String, dynamic>> items =
                recipient.recipientType == 'individual'
                ? allIndividuals
                : allFamilies;

            // تطبيق البحث
            if (searchQuery.isNotEmpty) {
              items = items.where((item) {
                final name = recipient.recipientType == 'individual'
                    ? item['full_name'].toString().toLowerCase()
                    : item['family_name'].toString().toLowerCase();
                return name.contains(searchQuery.toLowerCase());
              }).toList();
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 500,
                height: 600,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // العنوان
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                (recipient.recipientType == 'family'
                                        ? Colors.blue
                                        : Colors.green)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            recipient.recipientType == 'family'
                                ? Icons.family_restroom
                                : Icons.person,
                            color: recipient.recipientType == 'family'
                                ? Colors.blue
                                : Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recipient.recipientType == 'individual'
                                ? 'اختر فرداً'
                                : 'اختر عائلة',
                            style: const TextStyle(
                              fontSize: 20,
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

                    const SizedBox(height: 20),

                    // حقل البحث
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ابحث بالاسم...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.primary,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // عدد النتائج
                    Row(
                      children: [
                        Text(
                          'النتائج: ${items.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // قائمة النتائج
                    Expanded(
                      child: items.isEmpty
                          ? Center(
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
                                      Icons.search_off,
                                      size: 50,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد نتائج',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'حاول البحث بكلمة أخرى',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: items.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _buildRecipientListItem(
                                  item,
                                  recipient.recipientType!,
                                  () {
                                    Navigator.pop(context);
                                    setState(() {
                                      recipient.recipient = item;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // تحديث الواجهة بعد العودة من الحوار
    setState(() {});
  }

  Widget _buildRecipientListItem(
    Map<String, dynamic> item,
    String type,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (type == 'family' ? Colors.blue : Colors.green).withOpacity(
              0.1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            type == 'family' ? Icons.family_restroom : Icons.person,
            color: type == 'family' ? Colors.blue : Colors.green,
          ),
        ),
        title: Text(
          type == 'family' ? item['family_name'] : item['full_name'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          type == 'family'
              ? (item['family_address'] ?? 'لا يوجد عنوان')
              : (item['phone'] ?? 'لا يوجد هاتف'),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (type == 'family' ? Colors.blue : Colors.green).withOpacity(
              0.1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.check,
            color: type == 'family' ? Colors.blue : Colors.green,
            size: 20,
          ),
        ),
      ),
    );
  }

  // تحديث دالة _buildRecipientCard لاستخدام الـ onTap المباشر
  Widget _buildRecipientCard(RecipientSelection recipient, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recipient.recipient != null ? Colors.green : Colors.grey[300]!,
          width: recipient.recipient != null ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // رأس البطاقة
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (recipient.recipientType == 'family'
                              ? Colors.blue
                              : Colors.green)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  recipient.recipientType == 'family'
                      ? Icons.family_restroom
                      : Icons.person,
                  color: recipient.recipientType == 'family'
                      ? Colors.blue
                      : Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مستلم ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (recipient.recipient != null)
                      Text(
                        recipient.recipientType == 'family'
                            ? recipient.recipient!['family_name']
                            : recipient.recipient!['full_name'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              if (recipients.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                  onPressed: () => _removeRecipient(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // اختيار نوع المستلم والمستلم
          Row(
            children: [
              // اختيار النوع
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: recipient.recipientType,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    hint: const Text('النوع'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'individual',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('فرد'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'family',
                        child: Row(
                          children: [
                            Icon(
                              Icons.family_restroom,
                              size: 16,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            Text('عائلة'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        recipient.recipientType = value;
                        recipient.recipient = null;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // اختيار المستلم
              Expanded(
                child: GestureDetector(
                  onTap: recipient.recipientType == null
                      ? null
                      : () => _showRecipientPicker(recipient),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: recipient.recipientType == null
                          ? Colors.grey[100]
                          : (recipient.recipient == null
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: recipient.recipientType == null
                            ? Colors.grey[300]!
                            : (recipient.recipient == null
                                  ? Colors.orange
                                  : Colors.green),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          recipient.recipientType == null
                              ? Icons.lock
                              : (recipient.recipient == null
                                    ? Icons.person_search
                                    : Icons.check_circle),
                          size: 16,
                          color: recipient.recipientType == null
                              ? Colors.grey
                              : (recipient.recipient == null
                                    ? Colors.orange
                                    : Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recipient.recipientType == null
                                ? 'اختر النوع أولاً'
                                : (recipient.recipient == null
                                      ? 'انقر لاختيار المستلم'
                                      : (recipient.recipientType == 'family'
                                            ? recipient
                                                  .recipient!['family_name']
                                            : recipient
                                                  .recipient!['full_name'])),
                            style: TextStyle(
                              color: recipient.recipientType == null
                                  ? Colors.grey
                                  : (recipient.recipient == null
                                        ? Colors.orange
                                        : Colors.green),
                              fontWeight: recipient.recipient != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (recipient.recipientType != null &&
                            recipient.recipient == null)
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // إظهار معلومات إضافية عن المستلم المختار
          if (recipient.recipient != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (recipient.recipientType == 'family'
                            ? Colors.blue
                            : Colors.green)
                        .withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: recipient.recipientType == 'family'
                        ? Colors.blue
                        : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recipient.recipientType == 'family'
                          ? (recipient.recipient!['family_address'] ??
                                'لا يوجد عنوان')
                          : (recipient.recipient!['phone'] ?? 'لا يوجد هاتف'),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),

            // حقل ملاحظات خاص بالمستلم
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                recipient.notes = value;
              },
              decoration: InputDecoration(
                hintText: 'ملاحظات لهذا المستلم (اختياري)',
                prefixIcon: const Icon(
                  Icons.note,
                  size: 16,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadData();
    searchController.addListener(_onSearchChanged);

    // إضافة مستلم افتراضي
    _addNewRecipient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchController.text;
    });
  }

  void _addNewRecipient() {
    setState(() {
      recipients.add(RecipientSelection());
    });
  }

  void _removeRecipient(int index) {
    setState(() {
      recipients.removeAt(index);
    });
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final dbHelper = DatabaseHelper();

    try {
      final db = await dbHelper.database;

      // جلب الكرتونات الجاهزة
      final result = await db.rawQuery('''
      SELECT 
        rb.*,
        bt.type_name,
        bt.description as type_description
      FROM ready_boxes rb
      JOIN box_types bt ON rb.box_type_id = bt.id
      WHERE rb.status = 'ready' OR rb.status = 'جاهز'
      ORDER BY rb.prepared_at DESC
    ''');

      readyBoxes = result;
      print('✅ تم تحميل ${readyBoxes.length} كرتون جاهز');

      // جلب العائلات والأفراد
      allFamilies = await dbHelper.getAllFamilies();
      allIndividuals = await dbHelper.getAllIndividuals();
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
          'التوزيع',
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
            Tab(icon: Icon(Icons.inventory), text: 'كرتونات جاهزة'),
            Tab(icon: Icon(Icons.people), text: 'توزيع متعدد'),
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
                    'جاري تحميل البيانات...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildReadyBoxesTab(), _buildMultiDistributionTab()],
            ),
    );
  }

  // ================== تبويب الكرتونات الجاهزة ==================
  Widget _buildReadyBoxesTab() {
    return Column(children: [_buildQuickStats(), _buildBoxesList()]);
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shadowColor: Colors.green.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'كرتونات جاهزة',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${readyBoxes.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: readyBoxes.isEmpty
                      ? null
                      : () {
                          _tabController.animateTo(1);
                        },
                  icon: const Icon(Icons.people),
                  label: const Text('توزيع متعدد'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoxesList() {
    if (readyBoxes.isEmpty) {
      return Expanded(
        child: Center(
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
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد كرتونات جاهزة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'قم بتجهيز كرتونات جديدة للتوزيع',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrepareBoxesScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                icon: const Icon(Icons.add_box),
                label: const Text('تجهيز كرتونات جديدة'),
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
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.inventory,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'الكرتونات المتاحة',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${readyBoxes.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: readyBoxes.length,
              itemBuilder: (context, index) {
                final box = readyBoxes[index];
                return _buildBoxCard(box);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxCard(Map<String, dynamic> box) {
    String boxNumber = box['box_number'] ?? box['id'].toString() ?? 'غير محدد';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 1),
        ),
        child: InkWell(
          onTap: () => _showBoxDetails(box),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        box['type_name'] ?? 'كرتون',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.qr_code,
                                  size: 12,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'رقم: $boxNumber',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (box['prepared_at'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(box['prepared_at']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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
      ),
    );
  }

  // ================== تبويب التوزيع المتعدد ==================
  Widget _buildMultiDistributionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBoxesSelector(),
          const SizedBox(height: 20),
          _buildRecipientsList(),
          const SizedBox(height: 20),
          _buildDistributionActions(),
        ],
      ),
    );
  }

  Widget _buildBoxesSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: const Icon(
                  Icons.inventory,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'اختر الكرتونات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${selectedBoxes.length} مختار',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // زر تحديد الكل
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      if (selectedBoxes.length == readyBoxes.length) {
                        selectedBoxes.clear();
                      } else {
                        selectedBoxes = List.from(readyBoxes);
                      }
                    });
                  },
                  icon: Icon(
                    selectedBoxes.length == readyBoxes.length
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                    size: 18,
                  ),
                  label: Text(
                    selectedBoxes.length == readyBoxes.length
                        ? 'إلغاء تحديد الكل'
                        : 'تحديد الكل',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.green.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // قائمة الكرتونات
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.25,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: readyBoxes.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final box = readyBoxes[index];
                final isSelected = selectedBoxes.any(
                  (b) => b['id'] == box['id'],
                );

                return CheckboxListTile(
                  title: Text(
                    box['type_name'] ?? 'كرتون',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('رقم: ${box['box_number'] ?? box['id']}'),
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedBoxes.add(box);
                      } else {
                        selectedBoxes.removeWhere((b) => b['id'] == box['id']);
                      }
                    });
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory,
                      color: isSelected ? Colors.green : Colors.grey,
                    ),
                  ),
                  activeColor: Colors.green,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.people, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'المستلمين',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${recipients.length} مستلم',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // قائمة المستلمين
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recipients.length,
            separatorBuilder: (context, index) => const Divider(height: 16),
            itemBuilder: (context, index) {
              return _buildRecipientCard(recipients[index], index);
            },
          ),

          const SizedBox(height: 16),

          // زر إضافة مستلم جديد
          OutlinedButton.icon(
            onPressed: _addNewRecipient,
            icon: const Icon(Icons.add),
            label: const Text('إضافة مستلم آخر'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionActions() {
    bool isValid =
        selectedBoxes.isNotEmpty &&
        recipients.isNotEmpty &&
        recipients.every((r) => r.recipient != null);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          // ملاحظات عامة
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'ملاحظات عامة (اختياري)',
              hintText: 'أضف ملاحظات حول عملية التوزيع...',
              prefixIcon: const Icon(Icons.note, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),

          const SizedBox(height: 16),

          // ملخص التوزيع
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isValid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.info,
                  color: isValid ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isValid ? 'جاهز للتوزيع' : 'يرجى إكمال البيانات',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isValid ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '${selectedBoxes.length} كرتون - ${recipients.length} مستلم',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // زر التوزيع
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isValid ? () => _processMultiDistribution() : null,
              icon: const Icon(Icons.send),
              label: Text(
                'توزيع ${selectedBoxes.length} كرتون على ${recipients.length} مستلم',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processMultiDistribution() async {
    try {
      final dbHelper = DatabaseHelper();
      int totalDistributed = 0;

      // توزيع الكرتونات على المستلمين بشكل دوري
      for (int i = 0; i < selectedBoxes.length; i++) {
        final box = selectedBoxes[i];

        // اختيار المستلم بشكل دوري (round-robin)
        final recipientIndex = i % recipients.length;
        final recipient = recipients[recipientIndex];

        final recipientType = recipient.recipientType!;
        final recipientData = recipient.recipient!;
        final recipientId = recipientData['id'];
        final recipientName = recipientType == 'family'
            ? recipientData['family_name']
            : recipientData['full_name'];

        // تنسيق المعلومات للتخزين
        final recipientInfo = '$recipientType|$recipientId|$recipientName';

        // إضافة ملاحظات المستلم إن وجدت
        String boxNotes = notesController.text;
        if (recipient.notes.isNotEmpty) {
          boxNotes = boxNotes.isEmpty
              ? recipient.notes
              : '$boxNotes\nملاحظات للمستلم ${recipientIndex + 1}: ${recipient.notes}';
        }

        await dbHelper.distributeReadyBox(box['id'], recipientInfo, boxNotes);
        totalDistributed++;
      }

      if (mounted) {
        // عرض ملخص التوزيع
        _showDistributionSummary();
      }

      await _loadData();

      // إعادة تعيين النموذج
      setState(() {
        selectedBoxes.clear();
        recipients.clear();
        _addNewRecipient();
        notesController.clear();
      });
    } catch (e) {
      print('❌ خطأ في التوزيع: $e');
      if (mounted) {
        _showErrorSnackBar('خطأ في التوزيع: $e');
      }
    }
  }

  void _showDistributionSummary() {
    Map<String, int> recipientCount = {};

    for (var recipient in recipients) {
      if (recipient.recipient != null) {
        String name = recipient.recipientType == 'family'
            ? recipient.recipient!['family_name']
            : recipient.recipient!['full_name'];
        recipientCount[name] = (recipientCount[name] ?? 0) + 1;
      }
    }

    String summary = 'تم توزيع ${selectedBoxes.length} كرتون:\n\n';
    recipientCount.forEach((name, count) {
      summary += '• $name: $count كرتون\n';
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ تم التوزيع بنجاح'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  summary,
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  void _showBoxDetails(Map<String, dynamic> box) {
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
                      Icons.inventory,
                      color: Colors.green,
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
              _buildDetailItem('الحالة', 'جاهز للتوزيع', Icons.check_circle),

              if (box['prepared_by'] != null)
                _buildDetailItem('المجهز', box['prepared_by'], Icons.person),

              if (box['prepared_at'] != null)
                _buildDetailItem(
                  'تاريخ التجهيز',
                  _formatDate(box['prepared_at']),
                  Icons.calendar_today,
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

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

// كلاس مساعد لتخزين بيانات المستلم
class RecipientSelection {
  String? recipientType; // 'individual' or 'family'
  Map<String, dynamic>? recipient;
  String notes = '';

  RecipientSelection({this.recipientType, this.recipient});
}
