import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class FamilyDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> family;

  const FamilyDetailsScreen({super.key, required this.family});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic>? _father;
  Map<String, dynamic>? _mother;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyDetails();
  }

  Future<void> _loadFamilyDetails() async {
    setState(() => _isLoading = true);
    
    // تحميل بيانات الأب والأم
    if (widget.family['father_id'] != null) {
      final individuals = await _db.getAllIndividuals();
      _father = individuals.firstWhere(
        (individual) => individual['id'] == widget.family['father_id'],
        orElse: () => {},
      );
    }
    
    if (widget.family['mother_id'] != null) {
      final individuals = await _db.getAllIndividuals();
      _mother = individuals.firstWhere(
        (individual) => individual['id'] == widget.family['mother_id'],
        orElse: () => {},
      );
    }

    // تحميل أعضاء الأسرة
    final allIndividuals = await _db.getAllIndividuals();
    _members = allIndividuals.where((individual) => 
      individual['family_name'] == widget.family['family_name']
    ).toList();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تفاصيل الأسرة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 32 : 16),
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 800 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFamilyInfo(),
                        const SizedBox(height: 24),
                        _buildParentsInfo(),
                        const SizedBox(height: 24),
                        _buildMembersInfo(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildFamilyInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.family['family_name'] ?? '',
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.light.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عنوان الأسرة',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.family['family_address']?.toString() ?? 'غير محدد',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentsInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الوالدان',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildParentCard('الأب', _father),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildParentCard('الأم', _mother),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentCard(String title, Map<String, dynamic>? parent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.light.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            parent?['full_name']?.toString() ?? 'غير محدد',
            style: GoogleFonts.cairo(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أعضاء الأسرة (${_members.length})',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (_members.isEmpty)
              Text(
                'لا توجد أعضاء في هذه الأسرة',
                style: GoogleFonts.cairo(fontSize: 16),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.light.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          member['gender'] == 'ذكر' ? Icons.person : Icons.person_outline,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['full_name'] ?? '',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${member['gender'] ?? ''} - ${member['marital_status'] ?? ''}',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}