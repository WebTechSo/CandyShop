import 'package:cloud_firestore/cloud_firestore.dart';

/// ---------------------------------------------------------------------------
/// 👤 User Model
/// ---------------------------------------------------------------------------
class UserModel {
  final String uid;
  final String businessName;
  final String registrationCountry;
  final String registrationNumber;
  final String vatNumber;

  String fullName;
  String email;
  String phone;
  final String profilePicture;
  final String? gender;

  final AddressModel billingAddress;
  final AddressModel deliveryAddress;

  final bool termsAccepted;
  final String userType;
  final String role;
  final String status;

  final DateTime createdAt;
  final DateTime lastLogin;
  final DateTime updatedAt;

  // 🏗️ Constructor
  UserModel({
    required this.uid,
    required this.businessName,
    required this.registrationCountry,
    required this.registrationNumber,
    required this.vatNumber,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePicture = "",
    this.gender,
    required this.billingAddress,
    required this.deliveryAddress,
    required this.termsAccepted,
    this.userType = "business",
    this.role = "customer",
    this.status = "active",
    required this.createdAt,
    required this.lastLogin,
    required this.updatedAt,
  });

  // 🌑 Empty State
  static UserModel empty() => UserModel(
        uid: '',
        businessName: '',
        registrationCountry: '',
        registrationNumber: '',
        vatNumber: '',
        fullName: '',
        email: '',
        phone: '',
        profilePicture: '',
        billingAddress: AddressModel.empty(),
        deliveryAddress: AddressModel.empty(),
        termsAccepted: false,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  // 📤 To JSON (Firestore Write)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'business_name': businessName,
      'registration_country': registrationCountry,
      'registration_number': registrationNumber,
      'vat_number': vatNumber,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
      'billing_address': billingAddress.toJson(),
      'delivery_address': deliveryAddress.toJson(),
      'terms_accepted': termsAccepted,
      'user_type': userType,
      'role': role,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'last_login': Timestamp.fromDate(lastLogin),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // 📥 From Snapshot (Firestore Read)
  factory UserModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.data() != null) {
      final data = snapshot.data()!;
      return UserModel(
        uid: data['uid'] ?? snapshot.id,
        businessName: data['business_name'] ?? '',
        registrationCountry: data['registration_country'] ?? '',
        registrationNumber: data['registration_number'] ?? '',
        vatNumber: data['vat_number'] ?? '',
        fullName: data['full_name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        profilePicture: data['profile_picture'] ?? '',
        gender: data['gender'] ?? 'Male',
        billingAddress: AddressModel.fromJson(data['billing_address'] ?? {}),
        deliveryAddress: AddressModel.fromJson(data['delivery_address'] ?? {}),
        termsAccepted: data['terms_accepted'] ?? false,
        userType: data['user_type'] ?? 'business',
        role: data['role'] ?? 'customer',
        status: data['status'] ?? 'active',
        createdAt:
            (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLogin:
            (data['last_login'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } else {
      return UserModel.empty();
    }
  }
}

/// ---------------------------------------------------------------------------
/// 🏠 Address Model (Nested)
/// ---------------------------------------------------------------------------
class AddressModel {
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String zip;
  final String country;

  const AddressModel({
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
  });

  static AddressModel empty() => const AddressModel(
        address1: '',
        address2: '',
        city: '',
        state: '',
        zip: '',
        country: '',
      );

  Map<String, dynamic> toJson() {
    return {
      'address1': address1,
      'address2': address2,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      address1: json['address1'] ?? '',
      address2: json['address2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zip: json['zip'] ?? '',
      country: json['country'] ?? '',
    );
  }
}
