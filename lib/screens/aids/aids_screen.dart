import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import 'aid_details_screen.dart';
import 'add_edit_aid_screen.dart';

class AidsScreen extends StatefulWidget {
  const AidsScreen({super.key});

  @override
  State<AidsScreen> createState() => _AidsScreenState();
}

class _AidsScreenState extends State<AidsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _aids = [];
  List<Map<String, dynamic>> _filteredAids = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAids();
    _searchController.addListener(_filterAids);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAids() async {
    setState(() => _isLoading = true);
    _aids = await _db.getAllAids();
    _filteredAids = _aids;
    setState(() => _isLoading = false);
  }

  void _filterAids() {
    setState(() {
      _filteredAids = _aids.where((aid) {
        final name = aid['organization_name']?.toString().toLowerCase() ?? '';
        final description = aid['description']?.toString().toLowerCase() ?? '';
        final searchTerm = _searchController.text.toLowerCase();
        return name.contains(searchTerm) || description.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _deleteAid(int id) async {
    await _db.deleteAid(id);
    _loadAids();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'المساعدات',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: AuthService.canEdit()
            ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditAidScreen(),
                    ),
                  );
                  _loadAids();
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
                    child: _filteredAids.isEmpty
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
            hintText: 'بحث في المساعدات...',
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
          Icon(
            Icons.volunteer_activism_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد مساعدات',
            style: GoogleFonts.cairo(fontSize: 18, color: Colors.grey[600]),
          ),
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
            DataColumn(
              label: Text(
                'اسم الجهة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الوصف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'المواعيد',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الإجراءات',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: _filteredAids
              .map(
                (aid) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        aid['organization_name'] ?? '',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                    DataCell(
                      Text(
                        aid['description'] ?? '',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                    DataCell(
                      Text(aid['schedule'] ?? '', style: GoogleFonts.cairo()),
                    ),
                    DataCell(_buildActions(aid)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredAids.length,
      itemBuilder: (context, index) {
        final aid = _filteredAids[index];
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
                  builder: (context) => AidDetailsScreen(aid: aid),
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
                            Icons.volunteer_activism,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            aid['organization_name'] ?? '',
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
                            'الوصف: ${aid['description'] ?? 'غير محدد'}',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'المواعيد: ${aid['schedule'] ?? 'غير محدد'}',
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
                      children: _buildActionButtons(aid),
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

  Widget _buildActions(Map<String, dynamic> aid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility, color: AppColors.primary),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AidDetailsScreen(aid: aid)),
          ),
        ),
        if (AuthService.canEdit()) ...[
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.secondary),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditAidScreen(aid: aid),
                ),
              );
              _loadAids();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteDialog(aid['id']),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> aid) {
    return [
      _buildActionButton(
        Icons.visibility,
        AppColors.primary,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AidDetailsScreen(aid: aid)),
        ),
      ),
      if (AuthService.canEdit()) ...[
        const SizedBox(width: 8),
        _buildActionButton(Icons.edit, AppColors.secondary, () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditAidScreen(aid: aid)),
          );
          _loadAids();
        }),
        const SizedBox(width: 8),
        _buildActionButton(
          Icons.delete,
          Colors.red,
          () => _showDeleteDialog(aid['id']),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
            'هل أنت متأكد من حذف هذه المساعدة؟',
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
                _deleteAid(id);
              },
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
