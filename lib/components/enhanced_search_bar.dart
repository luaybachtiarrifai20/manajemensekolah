// Versi paling compact dengan IntrinsicWidth
import 'package:flutter/material.dart';

class EnhancedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final List<String>? filterOptions;
  final String? selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final bool showFilter;

  const EnhancedSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Cari...',
    this.onChanged,
    this.filterOptions,
    this.selectedFilter,
    this.onFilterChanged,
    this.showFilter = false,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search Icon
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.search, color: Colors.grey, size: 20),
            ),
            
            // Search Field
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: widget.controller,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    isDense: true,
                  ),
                  onChanged: widget.onChanged,
                ),
              ),
            ),
            
            // Clear Search Button
            if (widget.controller.text.isNotEmpty)
              SizedBox(
                width: 36,
                height: 36,
                child: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            
            // Vertical Divider
            if (widget.showFilter && widget.filterOptions != null)
              Container(
                width: 1,
                height: 24,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 4),
              ),
            
            // Filter Dropdown dengan width intrinsic
            if (widget.showFilter && widget.filterOptions != null)
              IntrinsicWidth(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.selectedFilter,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    items: widget.filterOptions!.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        widget.onFilterChanged?.call(newValue);
                      }
                    },
                  ),
                ),
              ),
            
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}