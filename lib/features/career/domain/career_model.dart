class CareerDream {
  final int id;
  final String title;
  final String description;
  final List<String> imageUrls;

  CareerDream({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrls = const [],
  });

  factory CareerDream.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List?)
        ?.map((img) => img['img_url'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList() ?? [];

    return CareerDream(
      id: json['id'],
      title: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrls: images,
    );
  }
}
