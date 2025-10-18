import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
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
        final description = area['area_description']?.toString().toLowerCase() ?? '';
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
          title: Text('المناطق', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: AuthService.canEdit()
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditAreaScreen()));
                  _loadAreas();
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
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
            hintText: 'بحث في المناطق...',
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
          Icon(Icons.location_on_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد مناطق', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600])),
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
            DataColumn(label: Text('اسم المنطقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الوصف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredAreas.map((area) => DataRow(cells: [
            DataCell(Text(area['area_name'] ?? '', style: GoogleFonts.cairo())),
            DataCell(Text(area['area_description'] ?? '', style: GoogleFonts.cairo())),
            DataCell(_buildActions(area)),
          ])).toList(),
        ),
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
            gradient: LinearGradient(colors: [Colors.white, AppColors.light.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.1), spreadRadius: 1, blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AreaDetailsScreen(area: area))),
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
                          child: Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(area['area_name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.description, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الوصف: ${area['area_description'] ?? 'غير محدد'}',
                            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: _buildActionButtons(area)),
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
        IconButton(icon: const Icon(Icons.visibility, color: AppColors.primary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AreaDetailsScreen(area: area)))),
        if (AuthService.canEdit()) ...[
          IconButton(icon: const Icon(Icons.edit, color: AppColors.secondary), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditAreaScreen(area: area))); _loadAreas(); }),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(area['id'])),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> area) {
    return [
      _buildActionButton(Icons.visibility, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AreaDetailsScreen(area: area)))),
      if (AuthService.canEdit()) ...[
        const SizedBox(width: 8),
        _buildActionButton(Icons.edit, AppColors.secondary, () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditAreaScreen(area: area))); _loadAreas(); }),
        const SizedBox(width: 8),
        _buildActionButton(Icons.delete, Colors.red, () => _showDeleteDialog(area['id'])),
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
          content: Text('هل أنت متأكد من حذف هذه المنطقة؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(onPressed: () { Navigator.pop(context); _deleteArea(id); }, child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}