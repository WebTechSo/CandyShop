import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class SeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _images = [
    "https://firebasestorage.googleapis.com/v0/b/amaricancandy-c87c3.firebasestorage.app/o/products%2F1766768871852_WVLmSOYxUtIDsUND9adRC6fGi8XuLyVDKWt86809.jpg?alt=media&token=e0e89ebd-e4ec-446d-9b90-142e563e55b5",
    "https://firebasestorage.googleapis.com/v0/b/amaricancandy-c87c3.firebasestorage.app/o/products%2F1766768892335_OksCHpHLgLBi79rJ8fDoR2H6qHBHmWv3LIlIhbgf.jpg?alt=media&token=1886a987-c0f9-40f2-97b2-ec085582773f",
    "https://firebasestorage.googleapis.com/v0/b/amaricancandy-c87c3.firebasestorage.app/o/products%2F1766768904606_F6IFEmfuk638WOBMEcWwvnceQca7uacmMgYd0dmW.jpg?alt=media&token=a038336f-9998-4f65-9fa0-94a80b1d398d",
    "https://firebasestorage.googleapis.com/v0/b/amaricancandy-c87c3.firebasestorage.app/o/products%2F1766768922472_Cs60MI1tdnVG4Kkko9zRyRkOEhiG01cF8Fnu4kqP.jpg?alt=media&token=5b46f67e-cb05-45dd-99d1-cb8f25644721"
  ];

  final List<String> _names = [
    "American Jelly Cubes",
    "Sour Patch Kids",
    "Reese's Peanut Butter Cups",
    "Hershey's Kisses",
    "Nerds Rope",
    "Twizzlers",
    "Mike and Ike",
    "Jolly Rancher",
    "Warheads",
    "Butterfinger",
    "Baby Ruth",
    "Milky Way",
    "3 Musketeers",
    "Smarties",
    "Sweet Tarts"
  ];

  final List<String> _categories = [
    "1",
    "2",
    "3",
  ];

  final List<String> _brands = [
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
  ];

  Future<void> seedProducts() async {
    final CollectionReference productsCollection = _db.collection('Products');
    final Random random = Random();

    for (int i = 0; i < 10; i++) {
      String id =
          DateTime.now().millisecondsSinceEpoch.toString() + i.toString();

      Map<String, dynamic> productData = {
        'category':  _categories[random.nextInt(_categories.length)],
        'brand': _brands[random.nextInt(_brands.length)],
        'created_at': FieldValue.serverTimestamp(),
        'currency': "GBP",
        'description':
            "Delicious American candy imported straight from the USA. Enjoy the sweet taste of ${_names[i % _names.length]}.",
        'featured': random.nextBool(),
        'id': id,
        'images': [
          _images[i % _images.length],
          _images[(i + 1) % _images.length] // Add a second image for variety
        ],
        'thumbnail': _images[i % _images.length],
        'ingredients':
            "Sugar, Corn Syrup, Modified Corn Starch, Citric Acid, Tartaric Acid, Natural and Artificial Flavors",
        'name': _names[i % _names.length] +
            " " +
            (random.nextInt(100) + 1).toString(),
        'price':
            double.parse((random.nextDouble() * 10 + 1).toStringAsFixed(2)),
        'vat_rate': 0.0,
        'priceDescription': "",
        'sku': "AV-${random.nextInt(10000)}",
        'variants': {
          'flavor': [
            "Strawberry",
            "Grape",
            "Orange",
            "Apple"
          ][random.nextInt(4)],
          'packaging': "Pouch",
          'size': ["Small", "Medium", "Large"][random.nextInt(3)],
          'country': [
            "USA",
            "UK",
            "Canada",
            "Brazil",
            "Japan"
          ][random.nextInt(3)]
        }
      };

      await productsCollection.doc(id).set(productData);
      print("Added product: ${productData['name']}");
    }
  }
}
