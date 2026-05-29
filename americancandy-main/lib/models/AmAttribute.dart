

import 'package:american_sweets/models/AmCategory.dart';

class AmAttributes {
  List<AmSize>? size;
  List<AmFlavor>? flavor;

  AmAttributes({this.size, this.flavor});

  factory AmAttributes.fromJson(Map<String, dynamic> json) {
    return AmAttributes(
      size: json['size'] != null ? (json['size'] as List).map((i) => AmSize.fromJson(i)).toList() : null,
      flavor: json['flavor'] != null ? (json['flavor'] as List).map((i) => AmFlavor.fromJson(i)).toList() : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.size != null) {
      data['size'] = this.size!.map((v) => v.toJson()).toList();
    }
    if (this.flavor != null) {
      data['flavor'] = this.flavor!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
class ShColor {
  int? count;
  String? description;
  int? id;
  // ignore: non_constant_identifier_names
  int? menu_order;
  String? name;
  String? slug;
  bool isSelected = false;

  // ignore: non_constant_identifier_names
  ShColor({this.count, this.description, this.id, this.menu_order, this.name, this.slug});

  factory ShColor.fromJson(Map<String, dynamic> json) {
    return ShColor(
      count: json['count'],
      description: json['description'],
      id: json['id'],
      menu_order: json['menu_order'],
      name: json['name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['description'] = this.description;
    data['id'] = this.id;
    data['menu_order'] = this.menu_order;
    data['name'] = this.name;
    data['slug'] = this.slug;
    return data;
  }
}

class AmSize {
  int? count;
  String? description;
  int? id;
  // ignore: non_constant_identifier_names
  int? menu_order;
  String? name;
  String? slug;
  bool isSelected = false;

  // ignore: non_constant_identifier_names
  AmSize({this.count, this.description, this.id, this.menu_order, this.name, this.slug});

  factory AmSize.fromJson(Map<String, dynamic> json) {
    return AmSize(
      count: json['count'],
      description: json['description'],
      id: json['id'],
      menu_order: json['menu_order'],
      name: json['name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['description'] = this.description;
    data['id'] = this.id;
    data['menu_order'] = this.menu_order;
    data['name'] = this.name;
    data['slug'] = this.slug;
    return data;
  }
}

class AmFlavor {
  int? count;
  String? description;
  int? id;
  // ignore: non_constant_identifier_names
  int? menu_order;
  String? name;
  String? slug;
  bool isSelected = false;

  // ignore: non_constant_identifier_names
  AmFlavor({this.count, this.description, this.id, this.menu_order, this.name, this.slug});

  factory AmFlavor.fromJson(Map<String, dynamic> json) {
    return AmFlavor(
      count: json['count'],
      description: json['description'],
      id: json['id'],
      menu_order: json['menu_order'],
      name: json['name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['count'] = this.count;
    data['description'] = this.description;
    data['id'] = this.id;
    data['menu_order'] = this.menu_order;
    data['name'] = this.name;
    data['slug'] = this.slug;
    return data;
  }
}

class Brand {
  String? name;
  String? slug;
  bool isSelected = false;

  Brand({this.name, this.slug});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      name: json['name'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['slug'] = this.slug;
    return data;
  }
}
