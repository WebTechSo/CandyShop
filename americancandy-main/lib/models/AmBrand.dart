import 'package:cloud_firestore/cloud_firestore.dart';

class AmBrand {
  int? count;
  String? description;
  int? id;
  bool? isSelected;
  int? menu_order;
  String? name;
  int? parent;
  String? slug;
  String? image;
  String? docId;

  AmBrand({
    this.count,
    this.description,
    this.id,
    this.isSelected,
    this.menu_order,
    this.name,
    this.parent,
    this.slug,
    this.image,
    this.docId,
  });

  static String? _cleanUrl(String? url) {
    if (url == null) return null;

    var cleaned =
        url.replaceAll('"', '').replaceAll("'", '').replaceAll('`', '').trim();

    // Split by comma and take the first part
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').first.trim();
    }

    return cleaned;
  }

  factory AmBrand.fromJson(Map<String, dynamic> json) {
    return AmBrand(
      count: json['count'],
      description: json['description'],
      id: json['id'],
      isSelected: json['isSelected'] ?? false,
      menu_order: json['menu_order'],
      name: json['name'],
      parent: json['parent'],
      slug: json['slug'],
      image: _cleanUrl(json['image'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count ?? 0,
      'description': description ?? "",
      'id': id ?? 0,
      'isSelected': isSelected ?? false,
      'menu_order': menu_order ?? 0,
      'name': name ?? "",
      'parent': parent ?? 0,
      'slug': slug ?? "",
      'image': image ?? "",
    };
  }

  factory AmBrand.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return AmBrand(
      docId: document.id,
      count: data['count'],
      description: data['description'],
      id: data['id'],
      isSelected: data['isSelected'],
      menu_order: data['menu_order'],
      name: data['name'],
      parent: data['parent'],
      slug: data['slug'],
      image: _cleanUrl(data['image'] as String?),
    );
  }

  factory AmBrand.fromQuerySnapshot(QueryDocumentSnapshot<Object?> document) {
    final data = document.data() as Map<String, dynamic>;
    return AmBrand(
      docId: document.id,
      count: data['count'],
      description: data['description'],
      id: data['id'],
      isSelected: data['isSelected'],
      menu_order: data['menu_order'],
      name: data['name'],
      parent: data['parent'],
      slug: data['slug'],
      image: _cleanUrl(data['image'] as String?),
    );
  }
}
