import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class EnhancedDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<List<Widget>>? actions;
  final bool showIndex;

  const EnhancedDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.actions,
    this.showIndex = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(
              AppColors.primary.withOpacity(0.1),
            ),
            headingRowHeight: 56,
            dataRowHeight: 60,
            columnSpacing: 24,
            horizontalMargin: 16,
            columns: [
              if (showIndex)
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '#',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ...headers.map((header) => DataColumn(
                label: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    header,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )),
              if (actions != null)
                DataColumn(
                  label: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'الإجراءات',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
            rows: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              
              return DataRow(
                color: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (index % 2 == 0) {
                      return Colors.grey.withOpacity(0.05);
                    }
                    return null;
                  },
                ),
                cells: [
                  if (showIndex)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ...row.map((cell) => DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        cell,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  )),
                  if (actions != null && actions!.length > index)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions![index],
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}