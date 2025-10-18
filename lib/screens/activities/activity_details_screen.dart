import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class ActivityDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailsScreen({super.key, required this.activity});

  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _individuals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivityDetails();
  }

  Future<void> _loadActivityDetails() async {
    setState(() => _isLoading = true);
    
    // تحميل الأفراد المشاركين في هذا النشاط
    final allIndividuals = await _db.getAllIndividuals();
    final activityRelations = await _db.database.then((db) => db.query('individual_activities', where: 'activity_id = ?', whereArgs: [widget.activity['id']]));
    
    _individuals = activityRelations.map((relation) {
      return allIndividuals.firstWhere((individual) => individual['id'] == relation['individual_id'], orElse: () => {});
    }).where((individual) => individual.isNotEmpty).toList();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تفاصيل النشاط', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                        _buildActivityInfo(),
                        const SizedBox(height: 24),
                        _buildParticipantsInfo(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActivityInfo() {
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
                  child: Icon(Icons.event, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(widget.activity['activity_name'] ?? '', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.light.withOpacity(0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.accent.withOpacity(0.5))),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('الوصف', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            const SizedBox(height: 4),
                            Text(widget.activity['description']?.toString() ?? 'غير محدد', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المواعيد', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            const SizedBox(height: 4),
                            Text(widget.activity['schedule']?.toString() ?? 'غير محدد', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87)),
                          ],
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

  Widget _buildParticipantsInfo() {
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
                Text('المشاركون (${_individuals.length})', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                    Text('لا يوجد مشاركون في هذا النشاط', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
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
                                individual['phone'] ?? '',
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