import 'dart:io';

import 'package:ecclesia/helpers/db_helper.dart';
import 'package:ecclesia/screens/church/add_church_screen.dart';
import 'package:ecclesia/services/auth_service.dart';
import 'package:ecclesia/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViewChurchScreen extends StatefulWidget {
  const ViewChurchScreen({Key? key}) : super(key: key);

  @override
  State<ViewChurchScreen> createState() => _ViewChurchScreenState();
}

class _ViewChurchScreenState extends State<ViewChurchScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _churches = [];
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadChurches();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  Future<void> _loadChurches() async {
    final data = await DatabaseHelper().getAllChurches();
    setState(() {
      _churches = data;
      _isLoading = false;
    });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          title: Text(
            'الكنائس',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButton: AuthService.canEdit() && _churches.isEmpty
            ? FloatingActionButton.extended(
                backgroundColor: AppColors.secondary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'إضافة كنيسة',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChurchAddScreen(),
                    ),
                  );
                  _loadChurches();
                },
              )
            : null,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _churches.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.church_outlined,
                            size: 90,
                            color: AppColors.light,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'لا توجد كنائس بعد',
                            style: GoogleFonts.cairo(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 800;
                        final crossAxisCount = isWide ? 2 : 1;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _churches.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isWide ? 1.3 : 1.1,
                              ),
                          itemBuilder: (context, index) {
                            final church = _churches[index];
                            final animation = Tween<double>(begin: 0, end: 1)
                                .animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Interval(
                                      (index / _churches.length),
                                      1.0,
                                      curve: Curves.easeOut,
                                    ),
                                  ),
                                );
                            return FadeTransition(
                              opacity: animation,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - animation.value)),
                                child: _buildChurchCard(church),
                              ),
                            );
                          },
                        );
                      },
                    ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsetsGeometry.all( 8),
                child: Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    'تُستخدم هذه البيانات في إعداد التقارير، ويُسمح فقط للمدير بإضافة أو تعديل البيانات غير الموجودة مسبقًا.',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.blueGrey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChurchCard(Map<String, dynamic> church) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2A80), Color(0xFF7A85C1)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // خلفية الصورة
            if (church['church_logo'] != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.file(
                    File(church['church_logo']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // المحتوى
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (church['church_logo'] != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.file(
                          File(church['church_logo']),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    church['church_name'],
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'البلد: ${church['church_country']}',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'المطرانية: ${church['diocese_name']}',
                    style: GoogleFonts.cairo(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (church['diocese_logo'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(church['diocese_logo']),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChurchAddScreen(item: church),
                            ),
                          ).then((value) {
                            _loadChurches();
                          });
                        },
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
}
