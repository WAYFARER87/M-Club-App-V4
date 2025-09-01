class Category {
  final String id;
  final String name;
  final String? faIcon;

  Category({required this.id, required this.name, this.faIcon});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      faIcon: json['fa_icon']?.toString(),
    );
  }
}
