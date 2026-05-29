import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class StripeServices extends GetxController {
  static StripeServices get instance => Get.put(StripeServices());

  /// Main function to handle the payment flow
  Future<void> makePayment({
    required double amount,
    required String currency,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    try {
      print("StripeServices: Starting payment flow");

      if (!kIsWeb) {
        if (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          throw 'Stripe is not supported on Desktop. Please use Android, iOS, or Web.';
        }
      }

      // 1. Fetch Stripe Publishable Key from Firestore
      // Note: Secret Key is NO LONGER needed on the client side.
      print("StripeServices: Fetching keys from Firestore");
      final snapshot = await FirebaseFirestore.instance
          .collection('payment_methods')
          .where('name', isEqualTo: 'Stripe')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw 'Stripe payment method not configured.';
      }

      final data = snapshot.docs.first.data();
      final mode = data['payment_mode'] ?? 'Test';
      String? publishableKey;

      if (mode == 'Live') {
        publishableKey = data['live_publishable_key'];
      } else {
        publishableKey = data['test_publishable_key'];
      }

      if (publishableKey == null || publishableKey.isEmpty) {
        throw 'Stripe publishable key is missing for $mode mode.';
      }
      print(
          "StripeServices: Publishable Key fetched successfully ($mode mode)");

      // 2. Configure Stripe Client-side
      print("StripeServices: Applying settings");
      Stripe.publishableKey = publishableKey;

      // applySettings is not required and can cause platform issues; skip it.

      if (kIsWeb) {
        throw 'Stripe payments are not supported on Web in this build.';
      }

      print("StripeServices: Creating Payment Intent via Stripe API");
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        secretKey:
            mode == 'Live' ? data['live_secret_key'] : data['test_secret_key'],
      );

      if (paymentIntent['clientSecret'] == null) {
        throw 'Failed to get client secret from Stripe';
      }

      print("StripeServices: Payment Intent created");

      // 4. Initialize Payment Sheet
      print("StripeServices: Initializing Payment Sheet");
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'Sweet Stop',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.blue,
            ),
          ),
        ),
      );

      // 5. Present Payment Sheet
      print("StripeServices: Presenting Payment Sheet");
      await Stripe.instance.presentPaymentSheet();

      // 6. Success
      print("StripeServices: Payment Successful");
      onSuccess();
    } on StripeException catch (e) {
      print("StripeServices: StripeException: ${e.error.localizedMessage}");
      if (e.error.code == FailureCode.Canceled) {
        onError('Payment Canceled');
      } else {
        onError('Stripe Error: ${e.error.localizedMessage}');
      }
    } catch (e) {
      print("StripeServices: Generic Error: $e");
      onError(e.toString());
    }
  }

  Future<String> getClientSecret({
    required double amount,
    required String currency,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('payment_methods')
        .where('name', isEqualTo: 'Stripe')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw 'Stripe payment method not configured.';
    }
    final data = snapshot.docs.first.data();
    final mode = data['payment_mode'] ?? 'Test';
    final publishableKey = mode == 'Live'
        ? data['live_publishable_key']
        : data['test_publishable_key'];
    final secretKey =
        mode == 'Live' ? data['live_secret_key'] : data['test_secret_key'];
    if (publishableKey == null || publishableKey.isEmpty) {
      throw 'Stripe publishable key is missing for $mode mode.';
    }
    if (secretKey == null || secretKey.isEmpty) {
      throw 'Stripe secret key is missing for $mode mode.';
    }
    Stripe.publishableKey = publishableKey;
    final res = await _createPaymentIntent(
      amount: amount,
      currency: currency,
      secretKey: secretKey,
    );
    return res['clientSecret'];
  }

  /// Helper to create Payment Intent using Stripe API directly
  Future<Map<String, dynamic>> _createPaymentIntent({
    required double amount,
    required String currency,
    required String? secretKey,
  }) async {
    if (secretKey == null || secretKey.isEmpty) {
      throw 'Stripe secret key is missing.';
    }
    final int amountInCents = (amount * 100).toInt();
    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountInCents.toString(),
        'currency': currency,
        'automatic_payment_methods[enabled]': 'true',
      },
    );
    if (response.statusCode != 200) {
      throw 'Stripe error: ${response.body}';
    }
    final data = jsonDecode(response.body);
    return {'clientSecret': data['client_secret']};
  }
}
