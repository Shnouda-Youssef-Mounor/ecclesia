import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';

class BoxContentsScreen extends StatefulWidget {
  final int boxTypeId;
  final String boxTypeName;

  const BoxContentsScreen({
    super.key,
    required this.boxTypeId,
    required this.boxTypeName,
  });

  @override
  State<BoxContentsScreen> createState() => _BoxContentsScreenState();
}

class _BoxContentsScreenState extends State<BoxContentsScreen> {
  List<Map<String, dynamic>> contents = [];
  List<Map<String, dynamic>> inventoryItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final dbHelper = DatabaseHelper();

      // جلب محتويات الكرتون الحالية
      contents = await dbHelper.getBoxTypeContents(widget.boxTypeId);

      // جلب جميع أصناف المخزون لإضافتها
      inventoryItems = await dbHelper.getAllInventoryItems();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل البيانات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> _addContent() async {
    int? selectedItemId;
    int quantity = 1;
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('إضافة مكون للكرتون'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // اختيار الصنف
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'اختر الصنف',
                    border: OutlineInputBorder(),
                  ),
                  items: inventoryItems.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text('${item['item_name']} (${item['unit']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedItemId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // إدخال الكمية
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الكمية في الكرتون',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    quantity = int.tryParse(value) ?? 1;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: selectedItemId == null
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _saveContent(
                          selectedItemId!,
                          int.tryParse(quantityController.text) ?? 1,
                        );
                      },
                child: const Text('إضافة'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveContent(int itemId, int quantity) async {
    try {
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // التحقق إذا كان المكون موجود مسبقاً
      final existing = await db.query(
        'box_type_contents',
        where: 'box_type_id = ? AND item_id = ?',
        whereArgs: [widget.boxTypeId, itemId],
      );

      if (existing.isNotEmpty) {
        // تحديث الكمية إذا كان موجوداً
        await db.update(
          'box_type_contents',
          {'quantity': quantity},
          where: 'box_type_id = ? AND item_id = ?',
          whereArgs: [widget.boxTypeId, itemId],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث كمية المكون'),
            backgroundColor: Colors.blue,
          ),
        );
      } else {
        // إضافة مكون جديد
        await db.insert('box_type_contents', {
          'box_type_id': widget.boxTypeId,
          'item_id': itemId,
          'quantity': quantity,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المكون بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadData(); // إعادة تحميل البيانات
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في إضافة المكون: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editContent(Map<String, dynamic> content) async {
    final quantityController = TextEditingController(
      text: content['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الكمية'),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'الكمية',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(quantityController.text);
              if (newQuantity == null || newQuantity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('الرجاء إدخال كمية صحيحة'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);

              try {
                final dbHelper = DatabaseHelper();
                final db = await dbHelper.database;

                await db.update(
                  'box_type_contents',
                  {'quantity': newQuantity},
                  where: 'id = ?',
                  whereArgs: [content['id']],
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث الكمية بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );

                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('خطأ: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContent(int contentId, String itemName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "$itemName" من مكونات الكرتون؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final dbHelper = DatabaseHelper();
                final db = await dbHelper.database;

                await db.delete(
                  'box_type_contents',
                  where: 'id = ?',
                  whereArgs: [contentId],
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف المكون بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );

                _loadData();
              } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مكونات ${widget.boxTypeName}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addContent,
            tooltip: 'إضافة مكون',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ملخص
                Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.inventory, color: Colors.blue),
                        const SizedBox(width: 12),
                        Text(
                          'إجمالي المكونات: ${contents.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // قائمة المكونات
                Expanded(
                  child: contents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'لا توجد مكونات لهذا الكرتون',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _addContent,
                                icon: const Icon(Icons.add),
                                label: const Text('إضافة مكونات'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: contents.length,
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final item = contents[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  item['item_name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('الوحدة: ${item['unit'] ?? ''}'),
                                    Text(
                                      'المتوفر: ${item['current_quantity'] ?? 0}',
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editContent(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteContent(
                                        item['id'],
                                        item['item_name'] ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: contents.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addContent,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// أضف هذه الدالة في DatabaseHelper
extension DatabaseHelperExtension on DatabaseHelper {
  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
    final db = await database;
    return await db.query('inventory_items', orderBy: 'item_name');
  }
}
