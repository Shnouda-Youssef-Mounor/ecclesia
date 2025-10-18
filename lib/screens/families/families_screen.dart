import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import 'family_details_screen.dart';
import 'add_edit_family_screen.dart';

class FamiliesScreen extends StatefulWidget {
  const FamiliesScreen({super.key});

  @override
  State<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends State<FamiliesScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _families = [];
  List<Map<String, dynamic>> _filteredFamilies = [];
  List<Map<String, dynamic>> _areas = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedArea = 'الكل';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterFamilies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _areas = await _db.getAllAreas();
    _families = await _db.getAllFamilies();
    _filteredFamilies = _families;
    setState(() => _isLoading = false);
  }

  Future<void> _loadFamilies() async {
    _families = await _db.getAllFamilies();
    _filteredFamilies = _families;
    _filterFamilies();
  }

  void _filterFamilies() {
    setState(() {
      _filteredFamilies = _families.where((family) {
        final name = family['family_name']?.toString().toLowerCase() ?? '';
        final address = family['family_address']?.toString().toLowerCase() ?? '';
        final searchTerm = _searchController.text.toLowerCase();

        final matchesSearch = name.contains(searchTerm) || address.contains(searchTerm);
        final matchesArea = _selectedArea == 'الكل' || family['area_id']?.toString() == _selectedArea;

        return matchesSearch && matchesArea;
      }).toList();
    });
  }

  Future<void> _deleteFamily(int id) async {
    await _db.deleteFamily(id);
    _loadFamilies();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الأسر',
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
                      builder: (context) => const AddEditFamilyScreen(),
                    ),
                  );
                  _loadFamilies();
                },
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildSearchAndFilters(),
                  Expanded(
                    child: _filteredFamilies.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد أسر مطابقة',
                              style: GoogleFonts.cairo(fontSize: 18),
                            ),
                          )
                        : isDesktop
                            ? _buildDesktopView()
                            : _buildMobileView(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: DataTable(
          columns: [
            DataColumn(label: Text('اسم الأسرة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('العنوان', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الإجراءات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))),
          ],
          rows: _filteredFamilies.map((family) {
            return DataRow(cells: [
              DataCell(Text(family['family_name'] ?? '', style: GoogleFonts.cairo())),
              DataCell(Text(family['family_address'] ?? '', style: GoogleFonts.cairo())),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: AppColors.primary),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FamilyDetailsScreen(family: family),
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
                            builder: (context) => AddEditFamilyScreen(family: family),
                          ),
                        );
                        _loadFamilies();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(family['id']),
                    ),
                  ],
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredFamilies.length,
      itemBuilder: (context, index) {
        final family = _filteredFamilies[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              family['family_name'] ?? '',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'العنوان: ${family['family_address'] ?? ''}',
              style: GoogleFonts.cairo(),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      const Icon(Icons.visibility),
                      const SizedBox(width: 8),
                      Text('عرض', style: GoogleFonts.cairo()),
                    ],
                  ),
                ),
                if (AuthService.canEdit()) ...[
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        Text('تعديل', style: GoogleFonts.cairo()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'view':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FamilyDetailsScreen(family: family),
                      ),
                    );
                    break;
                  case 'edit':
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditFamilyScreen(family: family),
                      ),
                    );
                    _loadFamilies();
                    break;
                  case 'delete':
                    _showDeleteDialog(family['id']);
                    break;
                }
              },
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تأكيد الحذف', style: GoogleFonts.cairo()),
          content: Text('هل أنت متأكد من حذف هذه الأسرة؟', style: GoogleFonts.cairo()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: GoogleFonts.cairo()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteFamily(id);
              },
              child: Text('حذف', style: GoogleFonts.cairo(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
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
      child: Column(
        children: [
          // شريط البحث
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'بحث في الأسر...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          _filterFamilies();
                        },
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
          const SizedBox(height: 12),
          // فلتر المناطق
          _buildAreaFilterDropdown(),
          const SizedBox(height: 8),
          // عداد النتائج
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد النتائج: ${_filteredFamilies.length}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_searchController.text.isNotEmpty || _selectedArea != 'الكل')
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _selectedArea = 'الكل');
                    _filterFamilies();
                  },
                  icon: Icon(
                    Icons.clear_all,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    'مسح الفلاتر',
                    style: GoogleFonts.cairo(color: AppColors.secondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaFilterDropdown() {
    List<String> areaOptions = ['الكل'];
    for (var area in _areas) {
      areaOptions.add(area['id'].toString());
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedArea,
          isExpanded: true,
          hint: Text('المنطقة', style: GoogleFonts.cairo(fontSize: 14)),
          items: areaOptions.map((areaId) {
            String displayName = 'الكل';
            if (areaId != 'الكل') {
              final area = _areas.firstWhere((a) => a['id'].toString() == areaId, orElse: () => {});
              displayName = area['area_name'] ?? 'غير محدد';
            }
            return DropdownMenuItem(
              value: areaId,
              child: Text(displayName, style: GoogleFonts.cairo(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedArea = value!);
            _filterFamilies();
          },
        ),
      ),
    );
  }
}