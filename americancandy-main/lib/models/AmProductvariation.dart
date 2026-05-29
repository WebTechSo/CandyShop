class ProductVariationModel {
  String id;
  String sku;
  String image;
  double price;
  double salePrice;
  int stock;
  Map<String, String> attributeValues;

  ProductVariationModel({
    required this.id,
    required this.sku,
    required this.image,
    required this.price,
    required this.salePrice,
    required this.stock,
    required this.attributeValues,
  });

  factory ProductVariationModel.fromJson(Map<String, dynamic> json) {
    return ProductVariationModel(
      id: json['id']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      salePrice: (json['salePrice'] is num) ? (json['salePrice'] as num).toDouble() : double.tryParse(json['salePrice']?.toString() ?? '') ?? 0.0,
      stock: (json['stock'] is num) ? (json['stock'] as num).toInt() : int.tryParse(json['stock']?.toString() ?? '') ?? 0,
      attributeValues: Map<String, String>.from(json['attributeValues'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'image': image,
      'price': price,
      'salePrice': salePrice,
      'stock': stock,
      'attributeValues': attributeValues,
    };
  }
}
