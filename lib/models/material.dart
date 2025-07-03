class MaterialModel {
  final int id;
  final String? fileName;
  final String? filePath;
  final String? videoLink;
  final String category;
  final String updatedAt;
  final String? className;
  final String? batch;

  MaterialModel({
    required this.id,
    this.fileName,
    this.filePath,
    this.videoLink,
    required this.category,
    required this.updatedAt,
    this.className,
    this.batch,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      videoLink: json['videoLink'],
      category: json['category'] ?? 'file',
      updatedAt: json['updatedAt'] ?? '',
      className: json['class'],
      batch: json['batch'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'videoLink': videoLink,
      'category': category,
      'updatedAt': updatedAt,
      'class': className,
      'batch': batch,
    };
  }
}
