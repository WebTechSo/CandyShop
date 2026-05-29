import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:american_sweets/models/AmUser.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  // Use your specific database name
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save user data to Firestore
  Future<void> saveUserRecord(UserModel user) async {
    try {
      print("📝 Saving user to Firestore with UID: ${user.uid}");

      await _db
          .collection("Users")
          .doc(user.uid)
          .set(user.toJson())
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw "Firestore save operation timed out. Check your internet connection or firewall.";
      });

      print("✅ User saved successfully!");
    } on FirebaseException catch (e) {
      print("❌ Firebase Exception: ${e.code} - ${e.message}");
      throw e;
    } catch (e) {
      print("❌ Unexpected error: $e");
      throw e;
    }
  }

  // Create user from registration data
  Future<UserModel> createUserFromRegistration({
    required String uid,
    required String businessName,
    required String registrationCountry,
    required String registrationNumber,
    required String vatNumber,
    required String fullName,
    required String email,
    required String phone,
    required AddressModel billingAddress,
    required AddressModel deliveryAddress,
    required bool termsAccepted,
  }) async {
    final now = DateTime.now();

    return UserModel(
      uid: uid,
      businessName: businessName,
      registrationCountry: registrationCountry,
      registrationNumber: registrationNumber,
      vatNumber: vatNumber,
      fullName: fullName,
      email: email,
      phone: phone,
      billingAddress: billingAddress,
      deliveryAddress: deliveryAddress,
      termsAccepted: termsAccepted,
      userType: "Business",
      role: "Customer",
      status: "Pending",
      createdAt: now,
      lastLogin: now,
      updatedAt: now,
    );
  }

  // Fetch user by UID
  Future<UserModel> fetchUserDetails(String uid) async {
    try {
      final snapshot = await _db.collection("Users").doc(uid).get();
      if (snapshot.exists) {
        return UserModel.fromSnapshot(snapshot);
      } else {
        return UserModel.empty();
      }
    } on FirebaseException catch (e) {
      print("Error fetching user: ${e.message}");
      throw e;
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection("Users").doc(uid).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      print("Error updating user: ${e.message}");
      throw e;
    }
  }
}
