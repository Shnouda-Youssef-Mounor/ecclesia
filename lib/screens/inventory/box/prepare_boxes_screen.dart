import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class PrepareBoxesScreen extends StatefulWidget {
  const PrepareBoxesScreen({super.key});

  @override
  State<PrepareBoxesScreen> createState() => _PrepareBoxesScreenState();
}

class _PrepareBoxesScreenState extends State<PrepareBoxesScreen> {
  List<Map<String, dynamic>> boxTypes = [];
  int? selectedBoxTypeId;
  Map<String, dynamic>? selectedBoxType;
  List<Map<String, dynamic>> boxContents = [];
  TextEditingController quantityController = TextEditingController(text: '1');
  TextEditingController preparedByController = TextEditingController();
  bool isLoading = true;
  bool isPreparing = false;

  @override
  void initState() {
    super.initState();
    _loadBoxTypes();
  }

  Future<void> _loadBoxTypes() async {
    setState(() => isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      boxTypes = await dbHelper.getAllBoxTypes();
      // إعادة تعيين التحديد
      selectedBoxTypeId = null;
      selectedBoxType = null;
      boxContents.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل أنواع الكرتونات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadBoxContents() async {
    if (selectedBoxTypeId == null) return;

    setState(() => isLoading = true);
    try {
      final dbHelper = DatabaseHelper();
      boxContents = await dbHelper.getBoxTypeContents(selectedBoxTypeId!);
      // العثور على BoxType المحدد
      selectedBoxType = boxTypes.firstWhere(
        (type) => type['id'] == selectedBoxTypeId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل المحتويات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _calculateRequirements() async {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    if (quantity <= 0 || selectedBoxTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار نوع الكرتون وإدخال عدد صحيح موجب'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String message = 'المتطلبات:\n\n';
    bool canPrepare = true;

    for (var item in boxContents) {
      final requiredQuantity = (item['quantity'] ?? 0) * quantity;
      final availableQuantity = item['current_quantity'] ?? 0;

      message += '${item['item_name']}:\n';
      message += '  المطلوب: $requiredQuantity ${item['unit']}\n';
      message += '  المتاح: $availableQuantity ${item['unit']}\n';

      if (availableQuantity < requiredQuantity) {
        message += '  ⚠️ غير كافي\n';
        canPrepare = false;
      } else {
        message += '  ✅ كافي\n';
      }
      message += '\n';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فحص المتطلبات'),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
          if (canPrepare)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showPrepareConfirmation(quantity);
              },
              child: const Text(
                'بدء التجهيز',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  void _showPrepareConfirmation(int quantity) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'تأكيد التجهيز',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تجهيز $quantity كرتون من نوع "${selectedBoxType?['type_name'] ?? ''}"',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: preparedByController,
                  decoration: InputDecoration(
                    labelText: 'اسم المجهز',
                    hintText: 'أدخل اسمك',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
              ElevatedButton(
                onPressed: preparedByController.text.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _prepareBoxes(quantity);
                      },
                child: const Text('تأكيد التجهيز'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _prepareBoxes(int quantity) async {
    if (selectedBoxTypeId == null || preparedByController.text.isEmpty) {
      return;
    }

    setState(() => isPreparing = true);

    final dbHelper = DatabaseHelper();
    final preparedBy = preparedByController.text.trim();

    // عرض تحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      ),
    );

    try {
      // استخدام الطريقة الآمنة
      final createdBoxes = await dbHelper.prepareBoxesSafe(
        selectedBoxTypeId!,
        quantity,
        preparedBy,
      );

      // إغلاق dialog التحميل
      Navigator.pop(context);

      // Reset form
      quantityController.text = '1';
      preparedByController.clear();

      // إظهار نجاح
      _showSuccessDialog(createdBoxes);

      // إعادة تحميل البيانات
      await Future.delayed(const Duration(milliseconds: 500));
      await _loadBoxContents();
    } catch (e) {
      // إغلاق dialog التحميل
      Navigator.pop(context);

      // عرض خطأ
      _showErrorDialog(e.toString());
    } finally {
      if (mounted) {
        setState(() => isPreparing = false);
      }
    }
  }

  void _showSuccessDialog(int createdBoxes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم التجهيز بنجاح',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'تم تجهيز $createdBoxes كرتون',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('موافق', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'خطأ في التجهيز',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                error.contains('غير كافي')
                    ? error.split(' - ')[1]
                    : 'حدث خطأ أثناء تجهيز الكرتونات',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حاول مرة أخرى',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تجهيز الكرتونات'),
        centerTitle: true,
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: isLoading ? null : _loadBoxTypes,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // اختيار نوع الكرتون
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'اختر نوع الكرتون',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            // الحل: استخدام int بدلاً من Map
                            value: selectedBoxTypeId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              hintText: 'اختر نوع الكرتون',
                              prefixIcon: const Icon(Icons.arrow_drop_down),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: boxTypes.map((type) {
                              return DropdownMenuItem<int>(
                                // الحل: تخزين الـ ID فقط
                                value: type['id'] as int?,
                                child: Text(
                                  type['type_name'] ?? 'بدون اسم',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedBoxTypeId = value;
                                if (value != null) {
                                  _loadBoxContents();
                                } else {
                                  selectedBoxType = null;
                                  boxContents.clear();
                                }
                              });
                            },
                            validator: (value) =>
                                value == null ? 'الرجاء اختيار نوع' : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // إذا تم اختيار نوع الكرتون
                  if (selectedBoxType != null) ...[
                    // معلومات النوع
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.light.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedBoxType!['type_name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (selectedBoxType!['description'] !=
                                          null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            selectedBoxType!['description'],
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
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

                    const SizedBox(height: 20),

                    // محتويات الكرتون
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📦 محتويات الكرتون الواحد:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...boxContents.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: index == boxContents.length - 1
                                      ? 0
                                      : 12,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.light.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${item['quantity']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['item_name'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['unit'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'المتاح: ${item['current_quantity'] ?? 0}',
                                      style: TextStyle(
                                        color:
                                            (item['current_quantity'] ?? 0) >=
                                                (item['quantity'] ?? 0)
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // إدخال عدد الكرتونات
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔢 عدد الكرتونات:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                labelText: 'العدد',
                                hintText: 'أدخل عدد الكرتونات',
                                prefixIcon: const Icon(Icons.numbers),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    final current =
                                        int.tryParse(quantityController.text) ??
                                        1;
                                    quantityController.text = (current + 1)
                                        .toString();
                                    setState(() {});
                                  },
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {});
                              },
                            ),
                            const SizedBox(height: 16),

                            // ملخص المتطلبات
                            if (boxContents.isNotEmpty &&
                                int.tryParse(quantityController.text) != null)
                              ..._buildRequirementsSummary(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // أزرار التحكم
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isPreparing
                                ? null
                                : () => _calculateRequirements(),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'فحص المتطلبات',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 24,
                              ),
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isPreparing
                                ? null
                                : selectedBoxTypeId != null &&
                                      quantityController.text.isNotEmpty &&
                                      int.tryParse(quantityController.text) !=
                                          null &&
                                      int.parse(quantityController.text) > 0
                                ? () => _showPrepareConfirmation(
                                    int.parse(quantityController.text),
                                  )
                                : null,
                            icon: const Icon(
                              Icons.build_circle_outlined,
                              color: Colors.white,
                            ),
                            label: isPreparing
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'جاري التجهيز...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'بدء التجهيز',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 24,
                              ),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // إذا لم يتم اختيار نوع
                  if (selectedBoxType == null)
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 100,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'اختر نوع الكرتون للبدء',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'الرجاء اختيار نوع الكرتون من القائمة أعلاه',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildRequirementsSummary() {
    final quantity = int.tryParse(quantityController.text) ?? 0;
    final List<Widget> widgets = [];

    widgets.add(
      const Text(
        '📊 المتطلبات الكلية:',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

    widgets.add(const SizedBox(height: 12));

    bool allSufficient = true;

    for (var item in boxContents) {
      final requiredQuantity = (item['quantity'] ?? 0) * quantity;
      final availableQuantity = item['current_quantity'] ?? 0;
      final isSufficient = availableQuantity >= requiredQuantity;

      if (!isSufficient) allSufficient = false;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSufficient ? Colors.green.shade50 : Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSufficient
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSufficient ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isSufficient ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['item_name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSufficient
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المطلوب: $requiredQuantity ${item['unit']} | المتاح: $availableQuantity ${item['unit']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                isSufficient ? 'كافي' : 'ناقص',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSufficient ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Summary status
    widgets.add(
      Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: allSufficient ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              allSufficient ? Icons.check_circle_outline : Icons.info_outline,
              color: allSufficient ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                allSufficient
                    ? '✅ جميع المواد متوفرة لـ $quantity كرتون'
                    : '⚠️ بعض المواد غير كافية لـ $quantity كرتون',
                style: TextStyle(
                  color: allSufficient
                      ? Colors.green.shade800
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return widgets;
  }
}
