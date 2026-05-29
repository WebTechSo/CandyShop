import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';

class AdminLoginController extends GetxController {
  final emailCont = TextEditingController();
  final passwordCont = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final isLoading = false.obs;

  // Use default database instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> adminLogin() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Authenticate with Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailCont.text.trim(),
        password: passwordCont.text.trim(),
      );

      // 2. Allow admin if email is whitelisted in admin_setting.admin_emails
      final String? email = userCredential.user?.email?.toLowerCase().trim();
      try {
        final adminDoc = await _db
            .collection('admin_setting')
            .doc('vw0U6xyVtJRKsL2b7F57')
            .get();
        final data = adminDoc.data() as Map<String, dynamic>?;
        final List<String> adminEmails = (data?['admin_emails'] as List?)
                ?.map((e) => e.toString().toLowerCase().trim())
                .toList() ??
            [];
        if (email != null && adminEmails.contains(email)) {
          Get.offAll(() => AdminDashboardScreen());
          Get.snackbar(
            "Success",
            "Welcome Admin",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          return;
        }
      } catch (_) {
        // ignore whitelist errors and continue to role-based check
      }

      // 3. Check if user exists and has admin role in Firestore
      DocumentSnapshot userDoc =
          await _db.collection('Users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Check if user has admin role (you might need to add this field to your user model/data if not present)
        // For now assuming we check a 'role' field or 'user_type'
        String userType = userData['user_type'] ?? '';
        String role = userData['role'] ?? '';

        if (userType.toLowerCase() == 'admin' ||
            role.toLowerCase() == 'admin') {
          // Success - Navigate to Admin Dashboard
          Get.offAll(() => AdminDashboardScreen());
          Get.snackbar(
            "Success",
            "Welcome Admin",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          // Not an admin
          await _auth.signOut();
          Get.snackbar(
            "Access Denied",
            "You do not have admin privileges",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } else {
        await _auth.signOut();
        Get.snackbar(
          "Error",
          "User record not found",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Authentication Failed",
        e.message ?? "Unknown error occurred",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailCont.dispose();
    passwordCont.dispose();
    super.onClose();
  }
}
