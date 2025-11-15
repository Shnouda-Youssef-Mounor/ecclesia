import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import '../../utils/app_colors.dart';
import '../../utils/enhanced_data_table.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import 'area_details_screen.dart';
import 'add_edit_area_screen.dart';

class AreasScreen extends StatefulWidget {
  const AreasScreen({super.key});

  @override
  State<AreasScreen> createState() => _AreasScreenState();
}

class _AreasScreenState extends State<AreasScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _areas = [];
  List<Map<String, dynamic>> _filteredAreas = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreas();
    _searchController.addListener(_filterAreas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    setState(() => _isLoading = true);
    _areas = await _db.getAllAreas();
    _filteredAreas = _areas;
    setState(() => _isLoading = false);
  }

  void _filterAreas() {
    setState(() {
      _filteredAreas = _areas.where((area) {
        final name = area['area_name']?.toString().toLowerCase() ?? '';
        final description =
            area['area_description']?.toString().toLowerCase() ?? '';
        final searchTerm = _searchController.text.toLowerCase();
        return name.contains(searchTerm) || description.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _deleteArea(int id) async {
    await _db.deleteArea(id);
    _loadAreas();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المناطق',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: AuthService.canEdit()
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: "add",
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddEditAreaScreen(),
                        ),
                      );
                      _loadAreas();
                    },
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: "import",
                    onPressed: () => _showImportDialog(),
                    backgroundColor: AppColors.secondary,
                    child: const Icon(Icons.upload_file, color: Colors.white),
                  ),
                ],
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: _filteredAreas.isEmpty
                        ? _buildEmptyState()
                        : isDesktop
                        ? _buildDesktopView()
                        : _buildMobileView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'بحث في المناطق...',
            hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.cairo(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'لا توجد مناطق',
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EnhancedDataTable(
        headers: const ['اسم المنطقة', 'الوصف'],
        rows: _filteredAreas
            .map(
              (area) => [
                (area['area_name'] ?? '').toString(),
                (area['area_description'] ?? '').toString(),
              ],
            )
            .toList(),
        actions: _filteredAreas
            .map(
              (area) => [
                _buildActionButton(
                  Icons.visibility,
                  AppColors.primary,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AreaDetailsScreen(area: area),
                    ),
                  ),
                ),
                if (AuthService.canEdit()) ...[
                  const SizedBox(width: 4),
                  _buildActionButton(Icons.edit, AppColors.secondary, () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditAreaScreen(area: area),
                      ),
                    );
                    _loadAreas();
                  }),
                  const SizedBox(width: 4),
                  _buildActionButton(
                    Icons.delete,
                    Colors.red,
                    () => _showDeleteDialog(area['id']),
                  ),
                ],
              ],
            )
            .toList(),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAreas.length,
      itemBuilder: (context, index) {
        final area = _filteredAreas[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.light.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AreaDetailsScreen(area: area),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          child: Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            area['area_name'] ?? '',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الوصف: ${area['area_description'] ?? 'غير محدد'}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: _buildActionButtons(area),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(Map<String, dynamic> area) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AreaDetailsScreen(area: area),
            ),
          ),
        ),
        if (AuthService.canEdit()) ...[
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.secondary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditAreaScreen(area: area),
                ),
              );
              _loadAreas();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(area['id']),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> area) {
    return [
      _buildActionButton(
        Icons.visibility,
        AppColors.primary,
        () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AreaDetailsScreen(area: area),
          ),
        ),
      ),
      if (AuthService.canEdit()) ...[
        const SizedBox(width: 8),
        _buildActionButton(Icons.edit, AppColors.secondary, () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditAreaScreen(area: area),
            ),
          );
          _loadAreas();
        }),
        const SizedBox(width: 8),
        _buildActionButton(
          Icons.delete,
          Colors.red,
          () => _showDeleteDialog(area['id']),
        ),
      ],
    ];
  }

  Widget _buildActionButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        onPressed: onPressed,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
          content: Text(
            'هل أنت متأكد من حذف هذه المنطقة؟',
            style: GoogleFonts.cairo(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteArea(id);
              },
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      final file = File(result.files.single.path!);
      String content;
      try {
        content = await file.readAsString(encoding: utf8);
      } catch (_) {
        content = await file.readAsString(encoding: latin1);
      }

      content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      print('Content: $content');

      final fields = const CsvToListConverter().convert(content);
      print('Total fields: ${fields.length}');

      for (int i = 0; i < fields.length && i < 3; i++) {
        print('Row $i: ${fields[i]}');
      }

      if (fields.isEmpty) {
        _showMessage('الملف فارغ', Colors.red);
        return;
      }

      List<List<dynamic>> dataRows = fields;

      // تحقق من الهيدر وتجاهله تمامًا
      if (dataRows.isNotEmpty) {
        final firstRowText = dataRows.first[0].toString().trim();
        print('First row text: "$firstRowText"');

        if (firstRowText.contains('اسم') || firstRowText.contains('منطقة')) {
          print('Header detected, skipping first row');
          if (fields.length > 1) {
            dataRows = dataRows.skip(1).toList();
          } else {
            // Manual line splitting as fallback
            final lines = content
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
            print('Manual line split: ${lines.length} lines found');

            if (lines.length > 1) {
              dataRows = [];
              for (int i = 1; i < lines.length; i++) {
                try {
                  final row = const CsvToListConverter().convert(lines[i]);
                  if (row.isNotEmpty) {
                    dataRows.addAll(row);
                  }
                } catch (e) {
                  // Fallback: simple comma split
                  final simpleSplit = lines[i]
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                  if (simpleSplit.isNotEmpty && simpleSplit[0].isNotEmpty) {
                    dataRows.add(simpleSplit);
                  }
                }
              }
            }
          }
        }
      }

      print('Data rows after header check: ${dataRows.length}');

      if (dataRows.isEmpty) {
        _showMessage('لا توجد بيانات للاستيراد', Colors.red);
        return;
      }

      int successCount = 0;
      int errorCount = 0;

      for (var row in dataRows) {
        if (row.isEmpty || row[0].toString().trim().isEmpty) {
          errorCount++;
          continue;
        }

        try {
          await _db.insertArea({
            'area_name': row[0].toString().trim(),
            'area_description':
                row.length > 1 && row[1].toString().trim().isNotEmpty
                ? row[1].toString().trim()
                : null,
          });
          successCount++;
        } catch (_) {
          errorCount++;
        }
      }

      _loadAreas();
      _showMessage(
        'تم استيراد $successCount منطقة بنجاح${errorCount > 0 ? " مع $errorCount خطأ" : ""}',
        Colors.green,
      );
    } catch (e) {
      _showMessage('فشل في استيراد الملف', Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.cairo()),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'استيراد بيانات المناطق',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تنسيق ملف CSV المطلوب:',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'اسم المنطقة, الوصف',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ملاحظات:',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              Text(
                '• اسم المنطقة مطلوب\n• الوصف اختياري',
                style: GoogleFonts.cairo(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _importFromCSV();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: Text('اختيار ملف', style: GoogleFonts.cairo()),
            ),
          ],
        ),
      ),
    );
  }
}
