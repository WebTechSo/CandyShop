import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/models/AmAttribute.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/models/AmProduct.dart';

Future<String> loadContentAsset(String path) async {
  return await rootBundle.loadString(path);
}

Future<List<AmCategory>> loadCategory() async {
  String jsonString = await loadContentAsset('assets/sweet_data/category.json');
  final jsonResponse = json.decode(jsonString);
  return (jsonResponse as List).map((i) => AmCategory.fromJson(i)).toList();
}

Future<List<AmProductModel>> loadProducts() async {
  String jsonString = await loadContentAsset('assets/sweet_data/products.json');
  final jsonResponse = json.decode(jsonString);
  return (jsonResponse as List).map((i) => AmProductModel.fromJson(i)).toList();
}

Future<List<AmProductModel>> loadCartProducts() async {
  String jsonString =
      await loadContentAsset('assets/sweet_data/cart_products.json');
  final jsonResponse = json.decode(jsonString);
  return (jsonResponse as List).map((i) => AmProductModel.fromJson(i)).toList();
}

Future<AmAttributes> loadAttributes() async {
  String jsonString =
      await loadContentAsset('assets/sweet_data/attributes.json');
  final jsonResponse = json.decode(jsonString);
  return AmAttributes.fromJson(jsonResponse);
}

Future<List<AmAddressModel>> loadAddresses() async {
  String jsonString = await loadContentAsset('assets/sweet_data/address.json');
  final jsonResponse = json.decode(jsonString);
  return (jsonResponse as List).map((i) => AmAddressModel.fromJson(i)).toList();
}

Future<List<AmOrder>> loadOrders() async {
  String jsonString = await loadContentAsset('assets/sweet_data/orders.json');
  final jsonResponse = json.decode(jsonString);
  return (jsonResponse as List).map((i) => AmOrder.fromJson(i)).toList();
}

Future<List<String>> loadBanners() async {
  List<AmProductModel> products = await loadProducts();
  List<String> banner = [];

  products.forEach((product) {
    if (product.images!.isNotEmpty) {
      final src = product.images![0];
      // Ensure correct asset path for web/mobile
      if (src.startsWith('http')) {
        banner.add(src);
      } else {
        String p = src;
        if (p.startsWith('/')) p = p.substring(1);
        if (!p.contains('/')) {
          p = 'images/sweets/img/products/$p';
        }
        banner.add(p);
      }
    }
  });
  return banner;
}

extension StringExtension on String? {
  String? toCurrencyFormat({var format = '£'}) {
    return format + this;
  }

  String formatDateTime() {
    if (this == null || this!.isEmpty || this == "null") {
      return "NA";
    } else {
      return DateFormat("HH:mm dd MMM yyyy", "en_US")
          .format(DateFormat("yyyy-MM-dd HH:mm:ss.0", "en_US").parse(this!));
    }
  }

  String formatDate() {
    if (this == null || this!.isEmpty || this == "null") {
      return "NA";
    } else {
      return DateFormat("dd MMM yyyy", "en_US")
          .format(DateFormat("yyyy-MM-dd", "en_US").parse(this!));
    }
  }
}

// Add this in a new file or in your existing extension file
extension CurrencyFormat on double {
  String toCurrencyFormat() {
    return '£${toStringAsFixed(2)}';
  }
}

extension IntCurrencyFormat on int {
  String toCurrencyFormat() {
    return '£$this';
  }
}

extension StringCurrencyFormat on String {
  String toCurrencyFormat() {
    // Try to parse as double first, then as int
    final doubleValue = double.tryParse(this);
    if (doubleValue != null) {
      return '£${doubleValue.toStringAsFixed(2)}';
    }
    final intValue = int.tryParse(this);
    if (intValue != null) {
      return '£$intValue';
    }
    return '£$this'; // Fallback
  }
}
