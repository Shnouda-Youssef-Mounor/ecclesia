import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import 'sector_details_screen.dart';
import 'add_edit_sector_screen.dart';

class SectorsScreen extends StatefulWidget {
  const SectorsScreen({super.key});

  @override
  State<SectorsScreen> createState() => _SectorsScreenState();
}

class _SectorsScreenState extends State<SectorsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _sectors = [];
  List<Map<String, dynamic>> _filteredSectors = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSectors();
    _searchController.addListener(_filterSectors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSectors() async {
    setState(() => _isLoading = true);
    _sectors = await _db.getAllSectors();
    _filteredSectors = _sectors;
    setState(() => _isLoading = false);
  }

  void _filterSectors() {
    setState(() {
      _filteredSectors = _sectors.where((sector) {
        final name = sector['sector_name']?.toString().toLowerCase() ?? '';
        final searchTerm = _searchController.text.toLowerCase();
        return name.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _deleteSector(int id) async {
    await _db.deleteSector(id);
    _loadSectors();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('القطاعات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditSectorScreen()));
                      _loadSectors();
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
                    child: _filteredSectors.isEmpty
                        ? _buildEmptyState()
                        : isDesktop ? _buildDesktopView() : _buildMobileView(),
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
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2))],
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
            hintText: 'بحث في القطاعات...',
            hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(icon: Icon(Icons.clear, color: Colors.grey[600]), onPressed: () => _searchController.clear())
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد قطاعات', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: DataTable(
          columns: [
            DataColumn(label: Text('اسم القطاع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('موعد الاجتماع', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredSectors.map((sector) => DataRow(cells: [
            DataCell(Text(sector['sector_name'] ?? '', style: GoogleFonts.cairo())),
            DataCell(Text(sector['meeting_time'] ?? '', style: GoogleFonts.cairo())),
            DataCell(_buildActions(sector)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredSectors.length,
      itemBuilder: (context, index) {
        final sector = _filteredSectors[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, AppColors.light.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SectorDetailsScreen(sector: sector))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.category, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(sector['sector_name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'موعد الاجتماع: ${sector['meeting_time'] ?? 'غير محدد'}',
                            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: _buildActionButtons(sector)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(Map<String, dynamic> sector) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.visibility, color: AppColors.primary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SectorDetailsScreen(sector: sector)))),
        if (AuthService.canEdit()) ...[
          IconButton(icon: const Icon(Icons.edit, color: AppColors.secondary), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditSectorScreen(sector: sector))); _loadSectors(); }),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(sector['id'])),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> sector) {
    return [
      _buildActionButton(Icons.visibility, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SectorDetailsScreen(sector: sector)))),
      if (AuthService.canEdit()) ...[
        const SizedBox(width: 8),
        _buildActionButton(Icons.edit, AppColors.secondary, () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditSectorScreen(sector: sector))); _loadSectors(); }),
        const SizedBox(width: 8),
        _buildActionButton(Icons.delete, Colors.red, () => _showDeleteDialog(sector['id'])),
      ],
    ];
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onPressed, padding: const EdgeInsets.all(8), constraints: const BoxConstraints(minWidth: 36, minHeight: 36)),
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
          content: Text('هل أنت متأكد من حذف هذا القطاع؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(onPressed: () { Navigator.pop(context); _deleteSector(id); }, child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red))),
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
      final fields = const CsvToListConverter().convert(content);

      if (fields.isEmpty) {
        _showMessage('الملف فارغ', Colors.red);
        return;
      }

      List<List<dynamic>> dataRows = fields;

      // تحقق من الهيدر وتجاهله
      if (dataRows.isNotEmpty) {
        final firstRowText = dataRows.first[0].toString().trim();
        if (firstRowText.contains('اسم') || firstRowText.contains('قطاع')) {
          if (fields.length > 1) {
            dataRows = dataRows.skip(1).toList();
          } else {
            // Manual line splitting as fallback
            final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();
            if (lines.length > 1) {
              dataRows = [];
              for (int i = 1; i < lines.length; i++) {
                try {
                  final row = const CsvToListConverter().convert(lines[i]);
                  if (row.isNotEmpty) {
                    dataRows.addAll(row);
                  }
                } catch (e) {
                  final simpleSplit = lines[i].split(',').map((e) => e.trim()).toList();
                  if (simpleSplit.isNotEmpty && simpleSplit[0].isNotEmpty) {
                    dataRows.add(simpleSplit);
                  }
                }
              }
            }
          }
        }
      }

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
          await _db.insertSector({
            'sector_name': row[0].toString().trim(),
            'meeting_time': row.length > 1 && row[1].toString().trim().isNotEmpty
                ? row[1].toString().trim()
                : null,
          });
          successCount++;
        } catch (_) {
          errorCount++;
        }
      }

      _loadSectors();
      _showMessage(
        'تم استيراد $successCount قطاع بنجاح${errorCount > 0 ? " مع $errorCount خطأ" : ""}',
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
            'استيراد بيانات القطاعات',
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
                  'اسم القطاع, موعد الاجتماع',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ملاحظات:',
                style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
              ),
              Text(
                '• اسم القطاع مطلوب\n• موعد الاجتماع اختياري',
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