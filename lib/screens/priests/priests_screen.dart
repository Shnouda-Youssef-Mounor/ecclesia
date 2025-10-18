import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import 'priest_details_screen.dart';
import 'add_edit_priest_screen.dart';

class PriestsScreen extends StatefulWidget {
  const PriestsScreen({super.key});

  @override
  State<PriestsScreen> createState() => _PriestsScreenState();
}

class _PriestsScreenState extends State<PriestsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _priests = [];
  List<Map<String, dynamic>> _filteredPriests = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPriests();
    _searchController.addListener(_filterPriests);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPriests() async {
    setState(() => _isLoading = true);
    _priests = await _db.getAllPriests();
    _filteredPriests = _priests;
    setState(() => _isLoading = false);
  }

  void _filterPriests() {
    setState(() {
      _filteredPriests = _priests.where((priest) {
        final name = priest['priest_name']?.toString().toLowerCase() ?? '';
        final phone = priest['phone']?.toString() ?? '';
        final searchTerm = _searchController.text.toLowerCase();
        return name.contains(searchTerm) || phone.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _deletePriest(int id) async {
    await _db.deletePriest(id);
    _loadPriests();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الكهنة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: AuthService.canEdit()
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditPriestScreen()));
                  _loadPriests();
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
                    child: _filteredPriests.isEmpty
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
            hintText: 'بحث في الكهنة...',
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
          Icon(Icons.church_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا يوجد كهنة', style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600])),
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
            DataColumn(label: Text('اسم الكاهن', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الهاتف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredPriests.map((priest) => DataRow(cells: [
            DataCell(Text(priest['priest_name'] ?? '', style: GoogleFonts.cairo())),
            DataCell(Text(priest['phone'] ?? '', style: GoogleFonts.cairo())),
            DataCell(_buildActions(priest)),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPriests.length,
      itemBuilder: (context, index) {
        final priest = _filteredPriests[index];
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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PriestDetailsScreen(priest: priest))),
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
                          child: Icon(Icons.church, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(priest['priest_name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الهاتف: ${priest['phone'] ?? 'غير محدد'}',
                            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: _buildActionButtons(priest)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(Map<String, dynamic> priest) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: const Icon(Icons.visibility, color: AppColors.primary), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PriestDetailsScreen(priest: priest)))),
        if (AuthService.canEdit()) ...[
          IconButton(icon: const Icon(Icons.edit, color: AppColors.secondary), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditPriestScreen(priest: priest))); _loadPriests(); }),
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteDialog(priest['id'])),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> priest) {
    return [
      _buildActionButton(Icons.visibility, AppColors.primary, () => Navigator.push(context, MaterialPageRoute(builder: (context) => PriestDetailsScreen(priest: priest)))),
      if (AuthService.canEdit()) ...[
        const SizedBox(width: 8),
        _buildActionButton(Icons.edit, AppColors.secondary, () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEditPriestScreen(priest: priest))); _loadPriests(); }),
        const SizedBox(width: 8),
        _buildActionButton(Icons.delete, Colors.red, () => _showDeleteDialog(priest['id'])),
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
          content: Text('هل أنت متأكد من حذف هذا الكاهن؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء', style: GoogleFonts.cairo())),
            TextButton(onPressed: () { Navigator.pop(context); _deletePriest(id); }, child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}