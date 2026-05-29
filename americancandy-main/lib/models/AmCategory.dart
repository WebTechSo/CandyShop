import 'package:cloud_firestore/cloud_firestore.dart';

class AmCategory {
  int? count;
  String? description;
  int? id;
  bool? isSelected;
  int? menuOrder;
  String? name;
  int? parent;
  String? slug;
  String? image;
  String? docId;

  AmCategory({
    this.count,
    this.description,
    this.id,
    this.isSelected,
    this.menuOrder,
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
    if (cleaned.contains(',')) {
      cleaned = cleaned.split(',').first.trim();
    }
    return cleaned;
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count ?? 0,
      'description': description ?? "",
      'id': id ?? 0,
      'isSelected': isSelected ?? false,
      'menu_order': menuOrder ?? 0,
      'name': name ?? "",
      'parent': parent ?? 0,
      'slug': slug ?? "",
      'image': image ?? "",
    };
  }

  factory AmCategory.fromJson(Map<String, dynamic> json) {
    return AmCategory(
      count: json['count'],
      description: json['description'],
      id: json['id'],
      isSelected: json['isSelected'],
      menuOrder: json['menu_order'],
      name: json['name'],
      parent: json['parent'],
      slug: json['slug'],
      image: _cleanUrl(json['image']),
    );
  }

  factory AmCategory.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return AmCategory(
      docId: document.id,
      count: data['count'],
      description: data['description'],
      id: data['id'],
      isSelected: data['isSelected'],
      menuOrder: data['menu_order'],
      name: data['name'],
      parent: data['parent'],
      slug: data['slug'],
      image: _cleanUrl(data['image']),
    );
  }

  factory AmCategory.fromQuerySnapshot(
      QueryDocumentSnapshot<Object?> document) {
    final data = document.data() as Map<String, dynamic>;
    return AmCategory(
      docId: document.id,
      count: data['count'],
      description: data['description'],
      id: data['id'],
      isSelected: data['isSelected'],
      menuOrder: data['menu_order'],
      name: data['name'],
      parent: data['parent'],
      slug: data['slug'],
      image: _cleanUrl(data['image']),
    );
  }
}
