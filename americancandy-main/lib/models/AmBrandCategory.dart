import 'package:cloud_firestore/cloud_firestore.dart';

class AmBrandCategory{
  final String brandId;
  final String categoryId;

  AmBrandCategory({
    required this.brandId,
    required this.categoryId
});


  Map<String, dynamic> toJson(){
    return {
      'brandId' : brandId,
      'categoryId' : categoryId
    };
  }

  factory AmBrandCategory.fromSnapshot(DocumentSnapshot snapshot){
    final data = snapshot.data() as Map<String, dynamic>;

    return AmBrandCategory(
        brandId: data['brandId'] as String,
        categoryId: data['categoryId'] as String
    );
  }
}