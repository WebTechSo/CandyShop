import 'package:cloud_firestore/cloud_firestore.dart';

class AmProductCategory{
  final String productId;
  final String categoryId;

  AmProductCategory({
    required this.productId,
    required this.categoryId
  });


  Map<String, dynamic> toJson(){
    return {
      'productId' : productId,
      'categoryId' : categoryId
    };
  }

  factory AmProductCategory.fromSnapshot(DocumentSnapshot snapshot){
    final data = snapshot.data() as Map<String, dynamic>;

    return AmProductCategory(
        productId: data['productId'] as String,
        categoryId: data['categoryId'] as String
    );
  }
}