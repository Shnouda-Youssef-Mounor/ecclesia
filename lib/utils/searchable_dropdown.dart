import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<Map<String, dynamic>> items;
  final String displayKey;
  final String valueKey;
  final Function(T?) onChanged;
  final String? hintText;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.displayKey,
    required this.valueKey,
    required this.onChanged,
    this.value,
    this.hintText,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final displayValue = item[widget.displayKey]?.toString().toLowerCase() ?? '';
          return displayValue.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getDisplayText() {
    if (widget.value == null) return widget.hintText ?? 'اختر ${widget.label}';
    final item = widget.items.firstWhere(
      (item) => item[widget.valueKey] == widget.value,
      orElse: () => {},
    );
    return item[widget.displayKey]?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isOpen = !_isOpen),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: GoogleFonts.cairo(
                      color: widget.value == null ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                ),
                Icon(_isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
        if (_isOpen) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      hintStyle: GoogleFonts.cairo(),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    style: GoogleFonts.cairo(),
                    onChanged: _filterItems,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return ListTile(
                          title: Text('اختر ${widget.label}', style: GoogleFonts.cairo()),
                          onTap: () {
                            widget.onChanged(null);
                            setState(() => _isOpen = false);
                            _searchController.clear();
                            _filteredItems = widget.items;
                          },
                        );
                      }
                      
                      final item = _filteredItems[index - 1];
                      return ListTile(
                        title: Text(
                          item[widget.displayKey]?.toString() ?? '',
                          style: GoogleFonts.cairo(),
                        ),
                        onTap: () {
                          widget.onChanged(item[widget.valueKey] as T);
                          setState(() => _isOpen = false);
                          _searchController.clear();
                          _filteredItems = widget.items;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}