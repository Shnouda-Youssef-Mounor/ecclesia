import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/db_helper.dart';
import '../../utils/app_colors.dart';

class PriestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> priest;

  const PriestDetailsScreen({super.key, required this.priest});

  @override
  State<PriestDetailsScreen> createState() => _PriestDetailsScreenState();
}

class _PriestDetailsScreenState extends State<PriestDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic>? _sector;
  List<Map<String, dynamic>> _servants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPriestDetails();
  }

  Future<void> _loadPriestDetails() async {
    setState(() => _isLoading = true);

    // تحميل القطاع
    if (widget.priest['sector_id'] != null) {
      final sectors = await _db.getAllSectors();
      _sector = sectors.firstWhere(
        (s) => s['id'] == widget.priest['sector_id'],
        orElse: () => {},
      );
    }

    // تحميل الخدام الذين يعترفون عند هذا الكاهن
    final allServants = await _db.getAllServants();
    final confessionServants = allServants
        .where((s) => s['confession_father_id'] == widget.priest['id'])
        .toList();

    final individuals = await _db.getAllIndividuals();
    _servants = confessionServants.map((servant) {
      final individual = individuals.firstWhere(
        (i) => i['id'] == servant['individual_id'],
        orElse: () => {},
      );
      return {...servant, ...individual};
    }).toList();

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
            'تفاصيل الكاهن',
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
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 800 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriestInfo(),
                        const SizedBox(height: 24),
                        _buildSectorInfo(),
                        const SizedBox(height: 24),
                        _buildServantsInfo(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPriestInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.church, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.priest['priest_name'] ?? '',
                    style: GoogleFonts.cairo(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.light.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: AppColors.secondary, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'رقم الهاتف',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.priest['phone']?.toString() ?? 'غير محدد',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectorInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'القطاع المسؤول عنه',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.light.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.category,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _sector?['sector_name']?.toString() ?? 'غير محدد',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
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

  Widget _buildServantsInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'الخدام المعترفين (${_servants.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_servants.isEmpty)
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text(
                      'لا يوجد خدام يعترفون عند هذا الكاهن',
                      style: GoogleFonts.cairo(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _servants.length,
                itemBuilder: (context, index) {
                  final servant = _servants[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.light.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.volunteer_activism,
                            color: AppColors.secondary,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                servant['full_name'] ?? '',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                servant['phone'] ?? '',
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
