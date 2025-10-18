import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';
import '../../services/auth_service.dart';
import 'individual_details_screen.dart';
import 'add_edit_individual_screen.dart';

class IndividualsScreen extends StatefulWidget {
  const IndividualsScreen({super.key});

  @override
  State<IndividualsScreen> createState() => _IndividualsScreenState();
}

class _IndividualsScreenState extends State<IndividualsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _individuals = [];
  List<Map<String, dynamic>> _filteredIndividuals = [];
  List<Map<String, dynamic>> _areas = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedGender = 'الكل';
  String _selectedMaritalStatus = 'الكل';
  String _selectedArea = 'الكل';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterIndividuals);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _areas = await _db.getAllAreas();
    _individuals = await _db.getAllIndividuals();
    _filteredIndividuals = _individuals;
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIndividuals() async {
    _individuals = await _db.getAllIndividuals();
    _filteredIndividuals = _individuals;
    _filterIndividuals();
  }

  void _filterIndividuals() {
    setState(() {
      _filteredIndividuals = _individuals.where((individual) {
        final name = individual['full_name']?.toString().toLowerCase() ?? '';
        final phone = individual['phone']?.toString() ?? '';
        final area = individual['area']?.toString().toLowerCase() ?? '';
        final searchTerm = _searchController.text.toLowerCase();

        final matchesSearch =
            name.contains(searchTerm) ||
            phone.contains(searchTerm) ||
            area.contains(searchTerm);

        final matchesGender =
            _selectedGender == 'الكل' ||
            individual['gender'] == _selectedGender;

        final matchesMarital =
            _selectedMaritalStatus == 'الكل' ||
            individual['marital_status'] == _selectedMaritalStatus;

        final matchesArea = _selectedArea == 'الكل' || 
            individual['area_id']?.toString() == _selectedArea;

        return matchesSearch && matchesGender && matchesMarital && matchesArea;
      }).toList();
    });
  }

  Future<void> _deleteIndividual(int id) async {
    await _db.deleteIndividual(id);
    _loadIndividuals();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الأفراد',
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
                      builder: (context) => const AddEditIndividualScreen(),
                    ),
                  );
                  _loadIndividuals();
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
                    child: _filteredIndividuals.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد نتائج مطابقة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
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
            DataColumn(
              label: Text(
                'الاسم',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الرقم القومي',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الهاتف',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'المنطقة',
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
          rows: _filteredIndividuals.map((individual) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    individual['full_name'] ?? '',
                    style: GoogleFonts.cairo(),
                  ),
                ),
                DataCell(
                  Text(
                    individual['national_id'] ?? '',
                    style: GoogleFonts.cairo(),
                  ),
                ),
                DataCell(
                  Text(individual['phone'] ?? '', style: GoogleFonts.cairo()),
                ),
                DataCell(
                  Text(individual['area'] ?? '', style: GoogleFonts.cairo()),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          color: AppColors.primary,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                IndividualDetailsScreen(individual: individual),
                          ),
                        ),
                      ),
                      if (AuthService.canEdit()) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: AppColors.secondary,
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddEditIndividualScreen(
                                  individual: individual,
                                ),
                              ),
                            );
                            _loadIndividuals();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteDialog(individual['id']),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredIndividuals.length,
      itemBuilder: (context, index) {
        final individual = _filteredIndividuals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, AppColors.light.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        IndividualDetailsScreen(individual: individual),
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
                              individual['gender'] == 'ذكر'
                                  ? Icons.person
                                  : Icons.person_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  individual['full_name'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '${individual['gender'] ?? ''} - ${individual['marital_status'] ?? ''}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.credit_card,
                        'الرقم القومي',
                        individual['national_id'],
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.phone, 'الهاتف', individual['phone']),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        'المنطقة',
                        individual['area'],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton(
                            Icons.visibility,
                            AppColors.primary,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IndividualDetailsScreen(
                                  individual: individual,
                                ),
                              ),
                            ),
                          ),
                          if (AuthService.canEdit()) ...[
                            const SizedBox(width: 8),
                            _buildActionButton(
                              Icons.edit,
                              AppColors.secondary,
                              () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AddEditIndividualScreen(
                                          individual: individual,
                                        ),
                                  ),
                                );
                                _loadIndividuals();
                              },
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              Icons.delete,
                              Colors.red,
                              () => _showDeleteDialog(individual['id']),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        /*trailing: PopupMenuButton(
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
                        builder: (context) => IndividualDetailsScreen(individual: individual),
                      ),
                    );
                    break;
                  case 'edit':
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditIndividualScreen(individual: individual),
                      ),
                    );
                    _loadIndividuals();
                    break;
                  case 'delete':
                    _showDeleteDialog(individual['id']);
                    break;
                }
              },
            ),*/
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
          content: Text(
            'هل أنت متأكد من حذف هذا الفرد؟',
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
                _deleteIndividual(id);
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
                hintText: 'بحث بالاسم أو الهاتف أو المنطقة...',
                hintStyle: GoogleFonts.cairo(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          _filterIndividuals();
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
          // فلاتر النوع والحالة الاجتماعية
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'النوع',
                  _selectedGender,
                  ['الكل', 'ذكر', 'أنثى'],
                  (value) {
                    setState(() => _selectedGender = value!);
                    _filterIndividuals();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'الحالة الاجتماعية',
                  _selectedMaritalStatus,
                  ['الكل', 'أعزب', 'متزوج', 'مطلق', 'أرمل'],
                  (value) {
                    setState(() => _selectedMaritalStatus = value!);
                    _filterIndividuals();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // فلتر المناطق
          _buildAreaFilterDropdown(),
          // عداد النتائج
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عدد النتائج: ${_filteredIndividuals.length}',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_searchController.text.isNotEmpty ||
                  _selectedGender != 'الكل' ||
                  _selectedMaritalStatus != 'الكل' ||
                  _selectedArea != 'الكل')
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedGender = 'الكل';
                      _selectedMaritalStatus = 'الكل';
                      _selectedArea = 'الكل';
                    });
                    _filterIndividuals();
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

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label, style: GoogleFonts.cairo(fontSize: 14)),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, style: GoogleFonts.cairo(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'غير محدد',
            style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
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
            _filterIndividuals();
          },
        ),
      ),
    );
  }
}
