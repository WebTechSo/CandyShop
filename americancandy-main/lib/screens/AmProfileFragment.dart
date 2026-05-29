import 'dart:io';
import 'package:american_sweets/data/repositories/authentication_repository.dart';
import 'package:american_sweets/data/repositories/user_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:american_sweets/utils/StorageUpload.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/screens/AmAccountScreen.dart';

class AmProfileFragment extends StatefulWidget {
  static String tag = '/AmProfileFragment';

  @override
  AmProfileFragmentState createState() => AmProfileFragmentState();
}

class AmProfileFragmentState extends State<AmProfileFragment> {
  final _userRepo = Get.put(UserRepository());
  final _auth = FirebaseAuth.instance;

  // Personal
  var firstNameCont = TextEditingController();
  var emailCont = TextEditingController();
  String? selectedGender = "Male";
  var phoneCont = TextEditingController();
  var whatsappCont = TextEditingController();

  // Business
  var businessNameCont = TextEditingController();
  var registrationCountryCont = TextEditingController();
  var registrationNumberCont = TextEditingController();
  var vatNumberCont = TextEditingController();

  // Billing Address
  var billingAddress1Cont = TextEditingController();
  var billingAddress2Cont = TextEditingController();
  var billingCityCont = TextEditingController();
  var billingStateCont = TextEditingController();
  var billingZipCont = TextEditingController();
  var billingCountryCont = TextEditingController();

  // Delivery Address
  var deliveryAddress1Cont = TextEditingController();
  var deliveryAddress2Cont = TextEditingController();
  var deliveryCityCont = TextEditingController();
  var deliveryStateCont = TextEditingController();
  var deliveryZipCont = TextEditingController();
  var deliveryCountryCont = TextEditingController();

  File? _imageFile;
  String? _profileImageUrl;

  bool isLoading = false;
  List<String> _countries = [];

  @override
  void initState() {
    super.initState();
    _loadCountries();
    _fetchUserData();
  }

  Future<void> _loadCountries() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_setting')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final list = (data['variant_countries'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((e) => e.trim().isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          _countries = list;
        });
      }
    } catch (e) {
      print('Failed to load variant_countries: $e');
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userModel = await _userRepo.fetchUserDetails(user.uid);

        // Personal
        firstNameCont.text = userModel.fullName;
        emailCont.text = userModel.email;
        phoneCont.text = userModel.phone;
        if (userModel.profilePicture.isNotEmpty) {
          _profileImageUrl = userModel.profilePicture;
        }
        if (userModel.gender != null && userModel.gender!.isNotEmpty) {
          selectedGender = userModel.gender;
        }

        try {
          final doc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
          final extra = doc.data() as Map<String, dynamic>?;
          if (extra != null) {
            whatsappCont.text = (extra['whatsapp_number'] ?? '').toString();
          }
        } catch (_) {}

        // Business
        businessNameCont.text = userModel.businessName;
        registrationCountryCont.text = userModel.registrationCountry;
        registrationNumberCont.text = userModel.registrationNumber;
        vatNumberCont.text = userModel.vatNumber;

        // Billing
        billingAddress1Cont.text = userModel.billingAddress.address1;
        billingAddress2Cont.text = userModel.billingAddress.address2;
        billingCityCont.text = userModel.billingAddress.city;
        billingStateCont.text = userModel.billingAddress.state;
        billingZipCont.text = userModel.billingAddress.zip;
        billingCountryCont.text = userModel.billingAddress.country;

        // Delivery
        deliveryAddress1Cont.text = userModel.deliveryAddress.address1;
        deliveryAddress2Cont.text = userModel.deliveryAddress.address2;
        deliveryCityCont.text = userModel.deliveryAddress.city;
        deliveryStateCont.text = userModel.deliveryAddress.state;
        deliveryZipCont.text = userModel.deliveryAddress.zip;
        deliveryCountryCont.text = userModel.deliveryAddress.country;

        setState(() {}); // Update UI
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Camera'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage(String uid) async {
    if (_imageFile == null) return null;
    try {
      final url = await StorageUpload.uploadFile(
        _imageFile!,
        'user_images/$uid.jpg',
        contentType: 'image/jpeg',
      );
      return url;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = _auth.currentUser;
      if (user != null) {
        String existingRole = '';
        try {
          final doc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
          final data = doc.data();
          existingRole = (data?['role'] ?? '').toString().trim();
        } catch (_) {}

        String? newProfilePicUrl;
        if (_imageFile != null) {
          newProfilePicUrl = await _uploadImage(user.uid);
        }

        final fullName = "${firstNameCont.text.trim()}".trim();

        final billingMap = {
          'address1': billingAddress1Cont.text.trim(),
          'address2': billingAddress2Cont.text.trim(),
          'city': billingCityCont.text.trim(),
          'state': billingStateCont.text.trim(),
          'zip': billingZipCont.text.trim(),
          'country': billingCountryCont.text.trim(),
        };

        final deliveryMap = {
          'address1': deliveryAddress1Cont.text.trim(),
          'address2': deliveryAddress2Cont.text.trim(),
          'city': deliveryCityCont.text.trim(),
          'state': deliveryStateCont.text.trim(),
          'zip': deliveryZipCont.text.trim(),
          'country': deliveryCountryCont.text.trim(),
        };

        // Update Firestore
        await _userRepo.updateUserData(user.uid, {
          // Personal
          'full_name': fullName,
          'email': emailCont.text.trim(),
          'phone': phoneCont.text.trim(),
          'whatsapp_number': whatsappCont.text.trim(),
          'gender': selectedGender,
          if (newProfilePicUrl != null) 'profile_picture': newProfilePicUrl,

          // Business
          'business_name': businessNameCont.text.trim(),
          'registration_country': registrationCountryCont.text.trim(),
          'registration_number': registrationNumberCont.text.trim(),
          'vat_number': vatNumberCont.text.trim(),

          // Addresses
          'billing_address': billingMap,
          'delivery_address': deliveryMap,

          if (existingRole.toLowerCase() == 'admin') 'role': 'admin',
        });

        Get.snackbar("Success", "Profile updated successfully",
            backgroundColor: Colors.green, colorText: Colors.white);
        AmAccountScreen().launch(context, isNewTask: true);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update profile: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword) async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: currentPassword);

        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);

        Get.snackbar("Success", "Password changed successfully",
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Failed to change password",
          backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "An unexpected error occurred",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showChangePasswordDialog() {
    final oldPassCont = TextEditingController();
    final newPassCont = TextEditingController();
    final confirmPassCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Change Password", style: boldTextStyle(size: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(oldPassCont, "Previous Password",
                    isPassword: true),
                16.height,
                _buildTextField(newPassCont, "New Password", isPassword: true),
                16.height,
                _buildTextField(confirmPassCont, "Confirm Password",
                    isPassword: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: secondaryTextStyle()),
            ),
            TextButton(
              onPressed: () {
                if (oldPassCont.text.isEmpty ||
                    newPassCont.text.isEmpty ||
                    confirmPassCont.text.isEmpty) {
                  Get.snackbar("Error", "All fields are required",
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }
                if (newPassCont.text != confirmPassCont.text) {
                  Get.snackbar("Error", "New passwords do not match",
                      backgroundColor: Colors.red, colorText: Colors.white);
                  return;
                }
                Navigator.pop(context); // Close dialog
                _changePassword(
                    oldPassCont.text.trim(), newPassCont.text.trim());
              },
              child:
                  Text("Update", style: boldTextStyle(color: sh_colorPrimary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
                top: spacing_standard_new,
                right: spacing_standard_new,
                left: spacing_standard_new,
                bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Avatar
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(spacing_standard_new),
                        child: Card(
                          semanticContainer: true,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          elevation: spacing_standard,
                          margin: EdgeInsets.all(spacing_control),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100.0)),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SizedBox(
                              width: 110,
                              height: 110,
                              child: ClipOval(
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      )
                                    : (_profileImageUrl != null &&
                                            _profileImageUrl!.trim().isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: _profileImageUrl!.trim(),
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              color: sh_view_color,
                                              alignment: Alignment.center,
                                              child: const SizedBox(
                                                width: 26,
                                                height: 26,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          sh_colorPrimary),
                                                ),
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Image.asset(
                                              ic_user,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Image.asset(
                                            ic_user,
                                            fit: BoxFit.cover,
                                          ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          padding: EdgeInsets.all(spacing_control),
                          margin: EdgeInsets.only(bottom: 30, right: 20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.cardColor,
                            border:
                                Border.all(color: sh_colorPrimary, width: 1),
                          ),
                          child: Icon(Icons.camera_alt,
                              color: sh_colorPrimary, size: 16),
                        ),
                      )
                    ],
                  ),
                ),

                // --- contact & signup details Details ---
                Text("Contact & Signup Details",
                    style: boldTextStyle(size: 18, color: sh_colorPrimary)),
                16.height,
                _buildTextField(firstNameCont, "Full Name"),
                16.height,
                _buildTextField(emailCont, sh_hint_Email, isEmail: true),
                16.height,
                _buildTextField(phoneCont, "Phone Number", isPhone: true),
                16.height,
                _buildTextField(whatsappCont, "Whatsapp Number", isPhone: true),
                24.height,

                // --- Business Details ---
                Text("Business Details",
                    style: boldTextStyle(size: 18, color: sh_colorPrimary)),
                16.height,
                _buildTextField(businessNameCont, "Business Name"),
                16.height,
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(32.0)),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Country of Registration",
                    ),
                    value: registrationCountryCont.text.isNotEmpty
                        ? registrationCountryCont.text
                        : null,
                    items: (() {
                      final list = List<String>.from(_countries);
                      if (registrationCountryCont.text.isNotEmpty &&
                          !list.contains(registrationCountryCont.text)) {
                        list.add(registrationCountryCont.text);
                      }
                      return list;
                    })()
                        .map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c, style: primaryTextStyle()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        registrationCountryCont.text = val ?? '';
                      });
                    },
                  ),
                ),
                16.height,
                _buildTextField(registrationNumberCont, "Registration Number"),
                16.height,
                _buildTextField(vatNumberCont, "VAT Number"),
                24.height,

                // --- Billing Address ---
                Text("Billing Address",
                    style: boldTextStyle(size: 18, color: sh_colorPrimary)),
                16.height,
                _buildTextField(billingAddress1Cont, "Address Line 1"),
                16.height,
                _buildTextField(billingAddress2Cont, "Address Line 2"),
                16.height,
                Row(
                  children: [
                    Expanded(child: _buildTextField(billingCityCont, "City")),
                    16.width,
                    Expanded(child: _buildTextField(billingStateCont, "State")),
                  ],
                ),
                16.height,
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(billingZipCont, "Zip Code")),
                    16.width,
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.3), width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Country",
                          ),
                          value: billingCountryCont.text.isNotEmpty
                              ? billingCountryCont.text
                              : null,
                          items: (() {
                            final list = List<String>.from(_countries);
                            if (billingCountryCont.text.isNotEmpty &&
                                !list.contains(billingCountryCont.text)) {
                              list.add(billingCountryCont.text);
                            }
                            return list;
                          })()
                              .map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(c, style: primaryTextStyle()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              billingCountryCont.text = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                24.height,

                // --- Delivery Address ---
                Text("Delivery Address",
                    style: boldTextStyle(size: 18, color: sh_colorPrimary)),
                16.height,
                _buildTextField(deliveryAddress1Cont, "Address Line 1"),
                16.height,
                _buildTextField(deliveryAddress2Cont, "Address Line 2"),
                16.height,
                Row(
                  children: [
                    Expanded(child: _buildTextField(deliveryCityCont, "City")),
                    16.width,
                    Expanded(
                        child: _buildTextField(deliveryStateCont, "State")),
                  ],
                ),
                16.height,
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(deliveryZipCont, "Zip Code")),
                    16.width,
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.3), width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(32.0)),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Country",
                          ),
                          value: deliveryCountryCont.text.isNotEmpty
                              ? deliveryCountryCont.text
                              : null,
                          items: (() {
                            final list = List<String>.from(_countries);
                            if (deliveryCountryCont.text.isNotEmpty &&
                                !list.contains(deliveryCountryCont.text)) {
                              list.add(deliveryCountryCont.text);
                            }
                            return list;
                          })()
                              .map((c) {
                            return DropdownMenuItem<String>(
                              value: c,
                              child: Text(c, style: primaryTextStyle()),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              deliveryCountryCont.text = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                28.height,

                // Save / Cancel Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: MaterialButton(
                          padding: EdgeInsets.all(spacing_standard),
                          child: text(sh_lbl_save_profile,
                              fontSize: textSizeNormal,
                              fontFamily: fontMedium,
                              textColor: sh_white),
                          textColor: sh_white,
                          shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(40.0)),
                          color: sh_colorPrimary,
                          onPressed: () => _updateProfile(),
                        ),
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: MaterialButton(
                          padding: EdgeInsets.all(spacing_standard),
                          child: text("Cancel",
                              fontSize: textSizeNormal,
                              fontFamily: fontMedium,
                              textColor: sh_colorPrimary),
                          textColor: sh_colorPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(40.0),
                            side: BorderSide(color: sh_colorPrimary, width: 1),
                          ),
                          color: context.cardColor,
                          onPressed: () {
                            finish(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                16.height,

                // Change Password Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: MaterialButton(
                    padding: EdgeInsets.all(spacing_standard),
                    child: text(
                      sh_lbl_change_pswd,
                      fontSize: textSizeNormal,
                      fontFamily: fontMedium,
                      textColor: sh_colorPrimary,
                    ),
                    textColor: sh_white,
                    shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(40.0),
                      side: BorderSide(color: sh_colorPrimary, width: 1),
                    ),
                    color: context.cardColor,
                    onPressed: () {
                      _showChangePasswordDialog();
                    },
                  ),
                ),
                24.height,
              ],
            ),
          ),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(color: sh_colorPrimary),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isEmail = false, bool isPhone = false, bool isPassword = false}) {
    return TextFormField(
      obscureText: isPassword,
      keyboardType: isEmail
          ? TextInputType.emailAddress
          : (isPhone ? TextInputType.phone : TextInputType.text),
      autofocus: false,
      controller: controller,
      textCapitalization: (isEmail || isPassword)
          ? TextCapitalization.none
          : TextCapitalization.words,
      style: primaryTextStyle(),
      decoration: InputDecoration(
        filled: false,
        hintText: hint,
        hintStyle: primaryTextStyle(color: Colors.grey),
        contentPadding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide: BorderSide(color: sh_colorPrimary, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32.0),
          borderSide:
              BorderSide(color: Colors.grey.withOpacity(0.5), width: 0.5),
        ),
      ),
    );
  }
}
