import 'package:cloud_firestore/cloud_firestore.dart';

class AmProductModel {
  String? id;
  String? brand;
  int? category;
  String? categoryName; // Added to support string-based categories
  DateTime? createdAt;
  String? currency;
  String? description;
  List<String>? images;
  String? ingredients;
  String? name;
  double? price;
  double? unitPrice;
  double? vatRate;
  String? priceDescription;
  String? sku;
  String? thumbnail;
  AmVariant? variants;
  // Helper field for cart/order logic
  int? quantity;
  int? availableQuantity;
  String? status; // active, inactive, hold
  bool? featured;

  AmProductModel({
    this.id,
    this.brand,
    this.category,
    this.categoryName,
    this.createdAt,
    this.currency,
    this.description,
    this.images,
    this.ingredients,
    this.name,
    this.price,
    this.unitPrice,
    this.vatRate,
    this.priceDescription,
    this.sku,
    this.thumbnail,
    this.variants,
    this.quantity,
    this.availableQuantity,
    this.status,
    this.featured,
  });

  Map<String, dynamic> toJson() {
    return {
      'brand': brand ?? "",
      'category': category,
      'currency': currency ?? "GBP",
      'description': description ?? "",
      'images': images ?? [],
      'ingredients': ingredients ?? "",
      'name': name ?? "",
      'price': price ?? 0.0,
      'unit_price': unitPrice ?? 0.0,
      'vat_rate': vatRate ?? 0.0,
      'priceDescription': priceDescription ?? "",
      'sku': sku ?? "",
      'variants': variants?.toJson() ?? {},
      'available_quantity': availableQuantity,
      'product_status': status ?? 'active',
      if (featured != null) 'featured': featured,
    };
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == 'yes' || s == '1') return true;
    if (s == 'false' || s == 'no' || s == '0') return false;
    return null;
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is num) return price.toDouble();
    String priceStr = price.toString();
    if (priceStr.contains(',') && !priceStr.contains('.')) {
      priceStr = priceStr.replaceAll(',', '.');
    } else {
      priceStr = priceStr.replaceAll(',', '');
    }
    return double.tryParse(priceStr) ?? 0.0;
  }

  factory AmProductModel.fromJson(Map<String, dynamic> json) {
    // Handle legacy JSON structure mapping to new schema
    List<String> imgs = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        for (var img in json['images']) {
          if (img is Map && img.containsKey('src')) {
            imgs.add(_cleanUrl(img['src']));
          } else if (img is String) {
            imgs.add(_cleanUrl(img));
          }
        }
      }
    }

    double parsedPrice = 0.0;
    if (json['price'] != null) {
      parsedPrice = _parsePrice(json['price']);
    }
    final parsedUnitPrice = _parsePrice(json['unit_price']);

    AmVariant? vars;
    if (json['attributes'] != null && json['attributes'] is List) {
      String size = "";
      for (var attr in json['attributes']) {
        if (attr['name'] == 'Size' &&
            attr['options'] != null &&
            (attr['options'] as List).isNotEmpty) {
          size = (attr['options'] as List)[0].toString();
        }
      }
      vars = AmVariant(size: size);
    } else if (json['variants'] != null) {
      vars = AmVariant.fromJson(json['variants']);
    }

    int catId = 18; // Default to Sweets
    if (json['categories'] != null && json['categories'] is List) {
      for (var cat in json['categories']) {
        String name = cat['name'].toString().toLowerCase();
        if (name == 'chocolates')
          catId = 45;
        else if (name == 'sweets')
          catId = 18;
        else if (name == 'snacks')
          catId = 53;
        else if (name == 'candy')
          catId = 19;
        else if (name == 'cold drinks')
          catId = 21;
        else if (name == 'instant meals') catId = 20;
      }
    }

    return AmProductModel(
      id: json['id'].toString(),
      brand: json['brand'],
      category: catId,
      currency: "GBP",
      description: json['description'] ?? json['short_description'],
      images: imgs,
      ingredients: "",
      name: json['name'],
      price: parsedPrice,
      unitPrice: parsedUnitPrice > 0 ? parsedUnitPrice : parsedPrice,
      vatRate: _parsePrice(json['vat_rate']),
      priceDescription: json['priceDescription'],
      sku: json['sku'],
      thumbnail: json['thumbnail'],
      variants: vars,
      quantity: json['quantity'] != null
          ? int.tryParse(json['quantity'].toString())
          : null,
      availableQuantity: json['available_quantity'] != null
          ? int.tryParse(json['available_quantity'].toString())
          : null,
      status: json['product_status'] ?? 'active',
      featured: _parseBool(json['featured']),
    );
  }

  factory AmProductModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    var cat = data['category'];
    int? catId;
    String? catName;
    if (cat is int) {
      catId = cat;
    } else if (cat is String) {
      catId = int.tryParse(cat);
      if (catId == null) catName = cat;
    }

    return AmProductModel(
      id: document.id,
      brand: data['brand'],
      category: catId,
      categoryName: catName,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      currency: data['currency'],
      description: data['description'],
      images: data['images'] != null
          ? (data['images'] as List)
              .map((e) => _cleanUrl(e.toString()))
              .toList()
          : [],
      ingredients: data['ingredients'],
      name: data['name'],
      price: _parsePrice(data['price']),
      unitPrice: _parsePrice(data['unit_price']),
      vatRate: _parsePrice(data['vat_rate']),
      priceDescription: data['priceDescription'],
      sku: data['sku'],
      thumbnail: _cleanUrl(data['thumbnail']?.toString() ?? ''),
      variants: data['variants'] != null
          ? AmVariant.fromJson(data['variants'])
          : null,
      availableQuantity: data['available_quantity'] != null
          ? int.tryParse(data['available_quantity'].toString())
          : null,
      status: data['product_status'] ?? 'active',
      featured: _parseBool(data['featured']),
    );
  }

  factory AmProductModel.fromQuerySnapshot(
      QueryDocumentSnapshot<Object?> document) {
    final data = document.data() as Map<String, dynamic>;
    var cat = data['category'];
    int? catId;
    String? catName;
    if (cat is int) {
      catId = cat;
    } else if (cat is String) {
      catId = int.tryParse(cat);
      if (catId == null) catName = cat;
    }

    return AmProductModel(
      id: document.id,
      brand: data['brand'],
      category: catId,
      categoryName: catName,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : null,
      currency: data['currency'],
      description: data['description'],
      images: data['images'] != null
          ? (data['images'] as List)
              .map((e) => _cleanUrl(e.toString()))
              .toList()
          : [],
      ingredients: data['ingredients'],
      name: data['name'],
      price: _parsePrice(data['price']),
      unitPrice: _parsePrice(data['unit_price']),
      vatRate: _parsePrice(data['vat_rate']),
      priceDescription: data['priceDescription'],
      sku: data['sku'],
      thumbnail: _cleanUrl(data['thumbnail']?.toString() ?? ''),
      variants: data['variants'] != null
          ? AmVariant.fromJson(data['variants'])
          : null,
      availableQuantity: data['available_quantity'] != null
          ? int.tryParse(data['available_quantity'].toString())
          : null,
      status: data['product_status'] ?? 'active',
      featured: _parseBool(data['featured']),
    );
  }

  static String _cleanUrl(String url) {
    String u = url.replaceAll('`', '').replaceAll('"', '').trim();
    if (u.isEmpty) return u;
    // Normalize leading slash from JSON like "/candy-1.jpg"
    if (u.startsWith('/')) u = u.substring(1);
    // If looks like a bare filename, route to app product images folder
    final hasFolder = u.contains('/');
    final isHttp = u.startsWith('http://') || u.startsWith('https://');
    if (!isHttp && !hasFolder) {
      u = 'images/sweets/img/products/$u';
    }
    return u;
  }
}

class AmVariant {
  String? flavor;
  String? packaging;
  String? size;
  String? country;

  AmVariant({this.flavor, this.packaging, this.size, this.country});

  Map<String, dynamic> toJson() {
    return {
      'flavor': flavor ?? "",
      'packaging': packaging ?? "",
      'size': size ?? "",
      'country': country ?? "",
    };
  }

  factory AmVariant.fromJson(Map<String, dynamic> json) {
    return AmVariant(
      flavor: json['flavor'],
      packaging: json['packaging'],
      size: json['size'],
      country: json['country'],
    );
  }
}
