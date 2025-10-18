import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_colors.dart';
import '../../helpers/db_helper.dart';

class ServantDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> servant;

  const ServantDetailsScreen({super.key, required this.servant});

  @override
  State<ServantDetailsScreen> createState() => _ServantDetailsScreenState();
}

class _ServantDetailsScreenState extends State<ServantDetailsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  Map<String, dynamic>? _confessionFather;
  Map<String, dynamic>? _sector;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServantDetails();
  }

  Future<void> _loadServantDetails() async {
    setState(() => _isLoading = true);
    
    // تحميل أب الاعتراف
    if (widget.servant['confession_father_id'] != null) {
      final priests = await _db.getAllPriests();
      _confessionFather = priests.firstWhere((p) => p['id'] == widget.servant['confession_father_id'], orElse: () => {});
    }

    // تحميل القطاع
    if (widget.servant['sector_id'] != null) {
      final sectors = await _db.getAllSectors();
      _sector = sectors.firstWhere((s) => s['id'] == widget.servant['sector_id'], orElse: () => {});
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('تفاصيل الخادم', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
                        _buildServantInfo(),
                        const SizedBox(height: 24),
                        _buildServiceInfo(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildServantInfo() {
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
                  child: Icon(Icons.volunteer_activism, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.servant['full_name'] ?? '', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text('${widget.servant['gender'] ?? ''} - ${widget.servant['marital_status'] ?? ''}', style: GoogleFonts.cairo(fontSize: 16, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone, 'الهاتف', widget.servant['phone']),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'المنطقة', widget.servant['area']),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.church, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text('معلومات الخدمة', style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                      Icon(Icons.person_pin, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('أب الاعتراف', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            const SizedBox(height: 4),
                            Text(_confessionFather?['priest_name']?.toString() ?? 'غير محدد', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.category, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('القطاع', style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                            const SizedBox(height: 4),
                            Text(_sector?['sector_name']?.toString() ?? 'غير محدد', style: GoogleFonts.cairo(fontSize: 16, color: Colors.black87)),
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

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.light.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: GoogleFonts.cairo(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value ?? 'غير محدد',
              style: GoogleFonts.cairo(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}