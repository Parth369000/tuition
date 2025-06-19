import 'package:flutter/material.dart';

class MaterialsSection extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final Function(String) onViewMaterial;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Materials',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${materials.length} files',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: materials.isEmpty
                ? _buildEmptyState()
                : _buildMaterialsList(),
          ),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No materials uploaded yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to upload PDFs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList() {
    return ListView.builder(
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                material['category'] == 'file'
                    ? Icons.picture_as_pdf
                    : Icons.video_library,
                color: material['category'] == 'file' ? Colors.red : Colors.blue,
                size: 28,
              ),
            ),
            title: Text(
              material['fileName'] ?? material['videoLink'] ?? 'Untitled',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Uploaded on: ${material['updatedAt']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: () => onViewMaterial(material['filePath'] ?? material['videoLink'] ?? ''),
              tooltip: 'View PDF',
            ),
            onTap: () => onViewMaterial(material['filePath'] ?? material['videoLink'] ?? ''),
          ),
        );
      },
    );
  }
} 