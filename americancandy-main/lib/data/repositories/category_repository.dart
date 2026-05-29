import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/utils/constants/keys.dart';
import 'package:american_sweets/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:american_sweets/utils/exceptions/firebase_exceptions.dart';
import 'package:american_sweets/utils/exceptions/format_exceptions.dart';
import 'package:american_sweets/utils/exceptions/platform_exceptions.dart';

class CategoryRepository extends GetxController {
  static CategoryRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  /// Upload categories from an asset JSON file into Firestore collection `UKeys.categoryCollection`.
  Future<void> uploadCategoriesFromAsset(
      {String assetPath = 'assets/sweet_data/category.json'}) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      final categories = data
          .map((e) => AmCategory.fromJson(e as Map<String, dynamic>))
          .toList();

      final batch = _db.batch();
      for (final c in categories) {
        final docId =
            (c.id ?? c.slug ?? c.name ?? DateTime.now().millisecondsSinceEpoch)
                .toString();
        final docRef = _db.collection(UKeys.categoryCollection).doc(docId);
        batch.set(docRef, c.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
    } on FirebaseAuthException catch (e) {
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw UFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const UFormatException().message;
    } on PlatformException catch (e) {
      throw UPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Fetch all categories from Firestore.
  Future<List<AmCategory>> fetchAllCategories() async {
    try {
      final query = await _db.collection(UKeys.categoryCollection).get();
      return query.docs.map((doc) => AmCategory.fromJson(doc.data())).toList();
    } on FirebaseAuthException catch (e) {
      throw UFirebaseAuthException(e.code).message;
    } on FirebaseException catch (e) {
      throw UFirebaseException(e.code).message;
    } on PlatformException catch (e) {
      throw UPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }
}
