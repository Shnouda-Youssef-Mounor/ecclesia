import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class AreaDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> area;

  const AreaDetailsScreen({super.key, required this.area});

  @override
  State<AreaDetailsScreen> createState() => _AreaDetailsScreenState();
}

class _AreaDetailsScreenState extends State<AreaDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _individuals = [];
  List<Map<String, dynamic>> _families = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAreaDetails();
  }

  Future<void> _loadAreaDetails() async {
    setState(() => _isLoading = true);
    
    final allIndividuals = await _db.getAllIndividuals();
    final allFamilies = await _db.getAllFamilies();
    
    _individuals = allIndividuals.where((individual) => 
      individual['area_id'] == widget.area['id']
    ).toList();
    
    _families = allFamilies.where((family) => 
      family['area_id'] == widget.area['id']
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
          title: Text('تفاصيل المنطقة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                        _buildAreaInfo(),
                        const SizedBox(height: 24),
                        _buildStatistics(),
                        const SizedBox(height: 24),
                        _buildIndividualsInfo(),
                        const SizedBox(height: 24),
                        _buildFamiliesInfo(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildAreaInfo() {
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
                  child: Icon(Icons.location_on, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(widget.area['area_name'] ?? '', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.light.withOpacity(0.3), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.accent.withOpacity(0.5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('وصف المنطقة', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                  const SizedBox(height: 4),
                  Text(widget.area['area_description']?.toString() ?? 'غير محدد', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إحصائيات المنطقة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('عدد الأفراد', _individuals.length.toString(), Icons.people, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('عدد الأسر', _families.length.toString(), Icons.family_restroom, Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(count, style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[700])),
        ],
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
                Text('الأفراد في هذه المنطقة (${_individuals.length})', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                    Text('لا يوجد أفراد في هذه المنطقة', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _individuals.length > 5 ? 5 : _individuals.length,
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
                              Text(individual['full_name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16), overflow: TextOverflow.ellipsis),
                              Text(individual['phone'] ?? '', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (_individuals.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('وعدد ${_individuals.length - 5} آخرين...', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600])),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamiliesInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.family_restroom, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text('الأسر في هذه المنطقة (${_families.length})', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            if (_families.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Text('لا توجد أسر في هذه المنطقة', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _families.length > 5 ? 5 : _families.length,
                itemBuilder: (context, index) {
                  final family = _families[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.light.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Icon(Icons.home, color: AppColors.secondary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(family['family_name'] ?? '', style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 16), overflow: TextOverflow.ellipsis),
                              Text(family['family_address'] ?? '', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            if (_families.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('وعدد ${_families.length - 5} أسر أخرى...', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[600])),
              ),
          ],
        ),
      ),
    );
  }
}