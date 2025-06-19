import 'package:flutter/material.dart';

import '../../../core/themes/app_colors.dart';

class StudentListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearchChanged;
  final Function() onClearSearch;
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const StudentListHeader({
    Key? key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.selectedFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  // decoration: BoxDecoration(
                  //   color: Colors.grey[50],
                  //   borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  // ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            // border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      if (searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          onPressed: onClearSearch,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                // Container(
                //   height: 1,
                //   color: Colors.grey[200],
                // ),
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                //   child: SingleChildScrollView(
                //     scrollDirection: Axis.horizontal,
                //     child: Row(
                //       children: [
                //         _buildFilterChip('All', selectedFilter == 'All'),
                //         _buildFilterChip('Name', selectedFilter == 'Name'),
                //         _buildFilterChip('ID', selectedFilter == 'ID'),
                //         _buildFilterChip('Class', selectedFilter == 'Class'),
                //         _buildFilterChip('Batch', selectedFilter == 'Batch'),
                //       ],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFilterChip(String label, bool isSelected) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 4),
  //     child: FilterChip(
  //       label: Text(
  //         label,
  //         style: TextStyle(
  //           color: isSelected ? Colors.white : Colors.grey[700],
  //           fontSize: 12,
  //           fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
  //         ),
  //       ),
  //       selected: isSelected,
  //       onSelected: (selected) {
  //         if (selected) {
  //           onFilterChanged(label);
  //         }
  //       },
  //       backgroundColor: Colors.grey[100],
  //       selectedColor: const Color(0xFF328ECC),
  //       checkmarkColor: Colors.white,
  //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(20),
  //         side: BorderSide(
  //           color: isSelected ? const Color(0xFF328ECC) : Colors.grey[300]!,
  //           width: 1,
  //         ),
  //       ),
  //       elevation: 0,
  //       pressElevation: 0,
  //     ),
  //   );
  // }
}
