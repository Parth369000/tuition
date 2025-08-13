import 'package:flutter/material.dart';
import 'package:tuition/core/themes/app_colors.dart';

class MaterialsSection extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final Function(Map<String, dynamic>) onViewMaterial;
  final VoidCallback onUploadMaterial;

  const MaterialsSection({
    super.key,
    required this.materials,
    required this.onViewMaterial,
    required this.onUploadMaterial,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subject Materials',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              Text(
                '${materials.length} files',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          materials.isEmpty
              ? _buildEmptyState()
              : _buildMaterialsList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No materials uploaded yet',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to upload PDFs',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        final isFile = material['category'] == 'file';
        final iconBgColor = isFile ? AppColors.error : AppColors.secondary;
        return Card(
          elevation: 3,
          color: AppColors.cardBackground,
          shadowColor: AppColors.primary.withOpacity(0.10),
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              // Top accent bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: iconBgColor.withOpacity(0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFile ? Icons.picture_as_pdf : Icons.video_library,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material['fileName'] ??
                                material['videoLink'] ??
                                'Untitled',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Uploaded on: ${material['updatedAt']}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_outlined,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      onPressed: () => onViewMaterial(material),
                      tooltip: 'View PDF',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
