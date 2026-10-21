class ArticleModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String status;
  final String? coverImageUrl;
  final String authorId;
  final String? authorName;
  final DateTime? publishedAt;
  final DateTime createdAt;

  ArticleModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.status,
    this.coverImageUrl,
    required this.authorId,
    this.authorName,
    this.publishedAt,
    required this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'] ?? 'edukasi_tsunami',
      status: json['status'] ?? 'draft',
      coverImageUrl: json['coverImageUrl'],
      authorId: json['authorId'] ?? (json['author'] is Map ? json['author']['id'] ?? '' : ''),
      authorName: json['author'] is Map ? json['author']['name'] : null,
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String get readTime {
    if (content.trim().isEmpty) return '1 mnt baca';
    final words = content.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 150).ceil().clamp(1, 60);
    return '$minutes mnt baca';
  }

  String get categoryLabel {
    switch (category) {
      case 'edukasi_tsunami':
        return 'Edukasi Tsunami';
      case 'mitigasi_bencana':
        return 'Mitigasi Bencana';
      case 'berita':
        return 'Berita';
      case 'tips_keselamatan':
        return 'Tips Keselamatan';
      default:
        return category;
    }
  }
}
