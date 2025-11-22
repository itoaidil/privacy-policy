class InfoItemModel {
  final int id;
  final String text;
  final bool isActive;
  final int sortOrder;

  InfoItemModel({
    required this.id,
    required this.text,
    required this.isActive,
    required this.sortOrder,
  });

  factory InfoItemModel.fromJson(Map<String, dynamic> json) {
    return InfoItemModel(
      id: json['id'] ?? 0,
      text: json['text'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}

class PromoModel {
  final int id;
  final String title;
  final String description;
  final bool isActive;
  final String? iconColor; // hex color
  final int sortOrder;

  PromoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    this.iconColor,
    required this.sortOrder,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      iconColor: json['icon_color'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
