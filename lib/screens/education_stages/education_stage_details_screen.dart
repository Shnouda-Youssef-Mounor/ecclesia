import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class EducationStageDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stage;

  const EducationStageDetailsScreen({super.key, required this.stage});

  @override
  State<EducationStageDetailsScreen> createState() => _EducationStageDetailsScreenState();
}

class _EducationStageDetailsScreenState extends State<EducationStageDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _individuals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStageDetails();
  }

  Future<void> _loadStageDetails() async {
    setState(() => _isLoading = true);
    
    final allIndividuals = await _db.getAllIndividuals();
    _individuals = allIndividuals.where((individual) => 
      individual['education_stage_id'] == widget.stage['id']
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
          title: Text('تفاصيل المرحلة التعليمية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                        _buildStageInfo(),
                        const SizedBox(height: 24),
                        _buildIndividualsInfo(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStageInfo() {
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
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.school, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(widget.stage['stage_name'] ?? '', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualsInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text('الأفراد في هذه المرحلة (${_individuals.length})', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            if (_individuals.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text('لا يوجد أفراد في هذه المرحلة التعليمية', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _individuals.length,
                itemBuilder: (context, index) {
                  final individual = _individuals[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.light.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Icon(individual['gender'] == 'ذكر' ? Icons.person : Icons.person_outline, color: AppColors.secondary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                individual['full_name'] ?? '',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                individual['education_institution'] ?? '',
                                style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]),
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