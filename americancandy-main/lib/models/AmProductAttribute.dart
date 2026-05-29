class ProductAttributeModel {
  String name;
  List<String> values;

  ProductAttributeModel({required this.name, required this.values});

  factory ProductAttributeModel.fromJson(Map<String, dynamic> json) {
    return ProductAttributeModel(
      name: json['name']?.toString() ?? '',
      values: (json['values'] as List?)?.map((e) => e.toString()).toList() ??
          <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'values': values,
    };
  }
}
