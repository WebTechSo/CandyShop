import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:american_sweets/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:american_sweets/utils/exceptions/firebase_exceptions.dart';
import 'package:american_sweets/utils/exceptions/platform_exceptions.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/data/services/address_service.dart';
import 'package:american_sweets/screens/VerifyEmailScreen.dart';
import 'package:american_sweets/data/repositories/authentication_repository.dart';
import 'package:american_sweets/data/services/AdminCountryService.dart';
import 'package:country_state_city/country_state_city.dart' as csc;

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find();

  final signupFormKey = GlobalKey<FormState>();

  // BUSINESS
  final businessNameCont = TextEditingController();
  final registrationCountryCont = ''.obs;

  // CONTACT
  final fullNameCont = TextEditingController();
  final emailCont = TextEditingController();
  final contactNumberCont = TextEditingController();
  final whatsappNumberCont = TextEditingController();
  final passwordCont = TextEditingController();

  final termsAccepted = false.obs;
  final sameAsBilling = false.obs;
  final isLoading = false.obs;
  final variantCountries = <String>[].obs;
  final variantCountryIsoByName = <String, String>{}.obs;
  final variantCountryDialByName = <String, String>{}.obs;

  final _auth = FirebaseAuth.instance;

  // IMPORTANT: Use your specific database name
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _loadVariantCountries();
  }

  Future<void> _loadVariantCountries() async {
    try {
      final List<csc.Country> countries =
          await AdminCountryService.instance.getAllowedCountries();
      variantCountries.assignAll(countries.map((e) => e.name).toList());
      variantCountryIsoByName.assignAll(
          {for (final c in countries) c.name: c.isoCode.toUpperCase()});
      variantCountryDialByName.assignAll({
        for (final c in countries)
          c.name: c.phoneCode.toString().trim().isNotEmpty
              ? '+${c.phoneCode.toString().trim()}'
              : ''
      });
    } catch (e) {
      print('Failed to load variant_countries: $e');
    }
  }

  // TEST FUNCTION
  Future<void> testFirestoreConnection() async {
    try {
      print("🧪 Testing Firestore connection to 'amaricancandy' database...");

      final testData = {
        'test_message': 'Firestore connection test',
        'timestamp': DateTime.now().toString(),
        'database': 'amaricancandy',
      };

      print("📤 Sending test data: $testData");

      await _firestore
          .collection("ConnectionTests")
          .doc("test_${DateTime.now().millisecondsSinceEpoch}")
          .set(testData);

      print("✅ Firestore test PASSED for 'amaricancandy' database!");
    } on FirebaseException catch (e) {
      print("❌ FirebaseException: ${e.code} - ${e.message}");
      print("❌ Details: ${e.toString()}");
    } catch (e) {
      print("❌ Test error: $e");
    }
  }

  // ------------------------------------------------------------
  // ⛳ MAIN SIGNUP FUNCTION
  // ------------------------------------------------------------
  Future<void> registerUser() async {
    try {
      // Reset any previous errors
      Get.closeCurrentSnackbar();

      // Validate form
      if (!signupFormKey.currentState!.validate()) {
        final missing = _collectValidationErrors();
        final message = missing.isEmpty
            ? 'Please fill all required fields correctly'
            : 'Please fill: ${missing.join(', ')}';
        Get.snackbar('Validation Error', message);
        return;
      }

      if (!termsAccepted.value) {
        Get.snackbar('Terms Required', 'Please accept Terms & Conditions');
        return;
      }

      // Start loading
      isLoading.value = true;

      // Test Firestore first
      await testFirestoreConnection();

      // 🔐 1. CREATE AUTH USER
      print("🔐 Creating auth user...");
      final cred = await _auth.createUserWithEmailAndPassword(
        email: emailCont.text.trim(),
        password: passwordCont.text.trim(),
      );

      final uid = cred.user!.uid;
      print("✅ Auth user created with UID: $uid");

      // 💾 2. SAVE TO FIRESTORE DIRECTLY
      print("💾 Saving user to Firestore in 'amaricancandy' database...");

      final userData = {
        'uid': uid,
        'business_name': businessNameCont.text.trim(),
        'registration_country': registrationCountryCont.value,
        'full_name': fullNameCont.text.trim(),
        'email': emailCont.text.trim(),
        'phone': contactNumberCont.text.trim(),
        'whatsapp_number': whatsappNumberCont.text.trim(),
        'terms_accepted': termsAccepted.value,
        'user_type': "business",
        'role': "customer",
        'status': "active",
        'created_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      print("📊 Data to save: $userData");

      // Save to your specific database
      await _firestore
          .collection("Users")
          .doc(uid)
          .set(userData, SetOptions(merge: false));

      print(
          "🎉 SUCCESS! User data saved to Firestore database 'amaricancandy'!");
      print("📊 Collection: Users, Document ID: $uid");

      // 💾 3. SAVE DELIVERY ADDRESS TO ADDRESSES COLLECTION
      try {
        final addressModel = AmAddressModel(
          full_name: fullNameCont.text.trim(),
          phone: contactNumberCont.text.trim(),
          address_type: "Delivery",
          user_id: uid,
          default_address: true,
        );
        await AddressService().addAddress(addressModel);
        print("✅ Delivery address saved to Addresses collection as default.");
      } catch (e) {
        print("⚠️ Failed to save delivery address to Addresses collection: $e");
      }

      // ✉️ 4. SEND EMAIL VERIFICATION
      await AuthenticationRepository.instance.sendEmailVerification();
      print("📧 Verification email sent");

      // ✅ 4. SHOW SUCCESS & NAVIGATE
      isLoading.value = false;

      Get.snackbar(
        "Success!",
        "Account created successfully. Please check your email for verification.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );

      // Wait a bit before navigating
      await Future.delayed(Duration(seconds: 3));

      // Clear all form fields
      clearForm();

      // Navigate to verification screen
      Get.offAll(() => const VerifyEmailScreen());
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      print("❌ Firebase Auth Error: ${e.code} - ${e.message}");

      final errorMessage = UFirebaseAuthException(e.code).message;

      Get.snackbar(
        "Registration Failed",
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } on FirebaseException catch (e) {
      isLoading.value = false;
      print("❌ FirebaseException: Code: ${e.code}, Message: ${e.message}");
      print("❌ Firestore Error Details: ${e.toString()}");

      final msg = UFirebaseException(e.code).message;
      Get.snackbar(
        "Firestore Error",
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } on PlatformException catch (e) {
      isLoading.value = false;
      print("❌ Platform Error: ${e.code} - ${e.message}");
      final msg = UPlatformException(e.code).message;
      Get.snackbar(
        "Registration Failed",
        msg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      isLoading.value = false;
      print("❌ Unexpected Error: $e");
      print("❌ Stack Trace: ${e.toString()}");

      Get.snackbar(
        "Error",
        "Failed to create account. Please try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 4),
      );
    }
  }

  List<String> _collectValidationErrors() {
    final missing = <String>[];
    if (businessNameCont.text.trim().isEmpty) missing.add('Business Name');
    if (registrationCountryCont.value.trim().isEmpty) {
      missing.add('Country of Registration');
    }
    if (fullNameCont.text.trim().isEmpty) missing.add('Full Name');
    final emailVal = emailCont.text.trim();
    final emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (emailVal.isEmpty) {
      missing.add('Email');
    } else if (!emailRe.hasMatch(emailVal)) {
      missing.add('Valid Email');
    }
    final phoneDigits = contactNumberCont.text.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isEmpty) {
      missing.add('Contact Telephone Number');
    } else if (phoneDigits.length < 7) {
      missing.add('Valid Telephone Number');
    }
    if (whatsappNumberCont.text.trim().isEmpty) {
      missing.add('Whatsapp Number');
    }
    final pass = passwordCont.text.trim();
    if (pass.isEmpty) {
      missing.add('Password');
    } else if (pass.length < 6) {
      missing.add('Password (min 6 chars)');
    }
    return missing;
  }

  // Clear all form fields
  void clearForm() {
    businessNameCont.clear();
    registrationCountryCont.value = '';
    fullNameCont.clear();
    emailCont.clear();
    contactNumberCont.clear();
    whatsappNumberCont.clear();
    passwordCont.clear();
    termsAccepted.value = false;
  }

  // ------------------------------------------------------------
  // Cleanup
  // ------------------------------------------------------------
  @override
  void onClose() {
    businessNameCont.dispose();
    fullNameCont.dispose();
    emailCont.dispose();
    contactNumberCont.dispose();
    whatsappNumberCont.dispose();
    passwordCont.dispose();

    super.onClose();
  }
}
