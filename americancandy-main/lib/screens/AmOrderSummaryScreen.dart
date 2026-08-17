import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/models/AmUser.dart';
import 'package:american_sweets/screens/AmAdressManagerScreen.dart';
import 'package:american_sweets/screens/AmAddNewAddress.dart';
import 'package:american_sweets/screens/AmOrderSuccessScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart'; // Ensure AmExtension is imported
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/data/services/address_service.dart';
import 'package:american_sweets/data/services/cart_service.dart';
import 'package:american_sweets/data/services/order_service.dart';
import 'package:american_sweets/data/services/stripe_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/models/AmPaymentMethod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:american_sweets/utils/StorageUpload.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

import '../main.dart';

// Enum to manage selected shipping option
enum ShippingOption { normalFree, fastPaid }

class AmOrderSummaryScreen extends StatefulWidget {
  static String tag = '/AmOrderSummaryScreen';

  @override
  AmOrderSummaryScreenState createState() => AmOrderSummaryScreenState();
}

class AmOrderSummaryScreenState extends State<AmOrderSummaryScreen> {
  List<AmProductModel> list = [];
  List<AmAddressModel> addressList = [];
  UserModel? userModel;
  String contactName = '';
  String contactPhone = '';
  String contactEmail = '';
  var selectedAddressPosition = 0;
  List<String> images = [];
  var currentIndex = 0;
  Timer? timer;
  var isLoaded = false;
  ShippingOption selectedShipping = ShippingOption.fastPaid;
  String selectedPaymentMethod = "Stripe";
  StreamSubscription? _cartSubscription;

  // Pricing and VAT
  double subtotal = 0.0;
  double shippingCost = 0.0;
  double vatAmount = 0.0;
  double totalAmount = 0.0;
  bool _includeVat = getBoolAsync('include_vat', defaultValue: true);

  // Hardcoded date for demonstration
  String deliveryDate = "16/09/2025";

  // Bank Transfer form
  DateTime? _bankPaymentDate;
  String? _bankProofUrl;
  bool _bankUploading = false;
  AmPaymentMethod? _bankAdmin;

  @override
  void initState() {
    super.initState();
    _ensureAnonymousSession();
    fetchData();
  }

  // Helper to safely parse price string to double
  double _parsePrice(String? priceStr) {
    if (priceStr == null) return 0.0;
    return double.tryParse(priceStr) ?? 0.0;
  }

  Future<void> _ensureAnonymousSession() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        print('Anonymous sign-in failed: $e');
      }
    }
  }

  fetchData() async {
    // Fetch User Profile
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          userModel = UserModel.fromSnapshot(userDoc);
          contactName = userModel!.fullName;
          contactPhone = userModel!.phone;
          contactEmail = userModel!.email;
        }
      } catch (e) {
        print("Error fetching user profile: $e");
      }
    }

    // Subscribe to Cart Stream
    _cartSubscription = CartService().getCartStream().listen((snapshot) {
      var docs = snapshot.docs.toList();
      // Client-side sort by created_at descending
      docs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        Timestamp? t1 = dataA['created_at'] as Timestamp?;
        Timestamp? t2 = dataB['created_at'] as Timestamp?;
        if (t1 == null && t2 == null) return 0;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      });

      final products = docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final size = (data['size'] ?? '').toString();
        final flavor = (data['flavor'] ?? '').toString();
        final packaging = (data['packaging'] ?? '').toString();
        final country = (data['country'] ?? '').toString();
        return AmProductModel(
          id: data['product_id'],
          name: data['name'],
          price: (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : data['price'],
          vatRate: (data['vat_rate'] is num)
              ? (data['vat_rate'] as num).toDouble()
              : double.tryParse(data['vat_rate']?.toString() ?? '') ?? 0.0,
          thumbnail: data['image'],
          sku: data['sku'],
          variants: AmVariant(
            size: size.isNotEmpty ? size : null,
            flavor: flavor.isNotEmpty ? flavor : null,
            packaging: packaging.isNotEmpty ? packaging : null,
            country: country.isNotEmpty ? country : null,
          ),
          quantity: data['quantity'] ?? 1,
        );
      }).toList();

      if (mounted) {
        setState(() {
          list.clear();
          list.addAll(products);
          subtotal = list.fold(0.0, (sum, item) {
            double price = _parsePrice(item.price.toString());
            return sum + (price * (item.quantity ?? 1));
          });
          _calculateTotal();
        });
      }
    });

    // Fetch Addresses (and merge with Profile address if needed)
    List<AmAddressModel> addresses = [];
    try {
      addresses = await AddressService().getUserAddresses().first;
    } catch (e) {
      print("Error fetching addresses: $e");
    }

    // Find default address index
    int defaultIndex = 0;
    if (addresses.isNotEmpty) {
      for (int i = 0; i < addresses.length; i++) {
        if (addresses[i].default_address == true) {
          defaultIndex = i;
          break;
        }
      }
    }

    // If no custom addresses, try to add profile delivery address
    if (addresses.isEmpty && userModel != null) {
      var addr = userModel!.deliveryAddress;
      if (addr.address1.isNotEmpty) {
        addresses.add(AmAddressModel(
          full_name: userModel!.fullName,
          address: "${addr.address1} ${addr.address2}".trim(),
          city: addr.city,
          state: addr.state,
          zip_code: addr.zip,
          country: addr.country,
          phone: userModel!.phone,
          address_type: "Delivery",
          user_id: userModel!.uid,
          default_address: true,
        ));
      }
    }

    var banner = await loadBanners();

    if (mounted) {
      setState(() {
        addressList.clear();
        addressList.addAll(addresses);
        selectedAddressPosition = defaultIndex;

        // Auto-fill Contact Info for Guest Users or if empty
        if (addressList.isNotEmpty) {
          // Ensure index is valid
          if (selectedAddressPosition >= addressList.length)
            selectedAddressPosition = 0;

          final addr = addressList[selectedAddressPosition];
          if (userModel == null || contactName.trim().isEmpty) {
            contactName = addr.full_name ?? '';
          }
          if (userModel == null || contactPhone.trim().isEmpty) {
            contactPhone = addr.phone ?? '';
          }
        }

        images.clear();
        images.addAll(banner);
        isLoaded = true;
      });
    }
  }

  void _calculateTotal() {
    shippingCost = selectedShipping == ShippingOption.fastPaid ? 50.0 : 0.0;
    vatAmount = list.fold(0.0, (sum, item) {
      final price = _parsePrice(item.price?.toString());
      final rate = (item.vatRate ?? 0.0) / 100.0;
      final qty = item.quantity ?? 1;
      return sum + price * qty * rate;
    });
    totalAmount = subtotal + shippingCost + (_includeVat ? vatAmount : 0.0);
    if (mounted) setState(() {});
  }

  void _updateQuantity(AmProductModel product, int newQty) {
    if (newQty < 1) return;
    if (product.id != null) {
      CartService().updateQuantity(product.id!, newQty);
    }
  }

  @override
  void dispose() {
    _cartSubscription?.cancel();
    super.dispose();
    timer?.cancel();
  }

  void startTimer() {
    if (timer != null) {
      return;
    }
    timer = new Timer.periodic(new Duration(seconds: 5), (time) {
      setState(() {
        if (currentIndex == images.length - 1) {
          currentIndex = 0;
        } else {
          currentIndex = currentIndex + 1;
        }
      });
    });
  }

  Widget _buildBannerImage(String src, double height) {
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      String p = src;
      if (p.startsWith('/')) p = p.substring(1);
      if (!p.contains('/')) {
        p = 'images/sweets/img/products/$p';
      }
      return Image.asset(
        p,
        fit: BoxFit.cover,
        height: height,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
  }

  String _generateRandomPassword(int length) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)])
        .join();
  }

  Future<void> _ensureGuestAccountIfNeeded() async {
    final auth = FirebaseAuth.instance;
    var user = auth.currentUser;

    // 1. Ensure we have an Auth user (Anonymous or Real)
    if (user == null) {
      try {
        final cred = await auth.signInAnonymously();
        user = cred.user;
      } catch (e) {
        print("Warning: Anonymous sign-in failed: $e");
        // If we can't create an auth user, we can't upgrade them.
        // But per previous fix, we allow them to proceed as "true guest".
        // However, the NEW requirement is to create an account.
        // So we will try to create a fresh account directly below if they are not signed in.
      }
    }

    final email = contactEmail.trim();
    final name = contactName.trim();
    // Basic validation
    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (validEmail && name.isNotEmpty) {
      // Get Shipping Address to use as Billing/Delivery
      AmAddressModel? shippingAddr;
      if (addressList.isNotEmpty &&
          selectedAddressPosition < addressList.length) {
        shippingAddr = addressList[selectedAddressPosition];
      }

      final password = _generateRandomPassword(12);

      try {
        // CASE A: User is Anonymous -> Link Credential (Upgrade)
        if (user != null && user.isAnonymous) {
          final emailCred =
              EmailAuthProvider.credential(email: email, password: password);
          final res = await user.linkWithCredential(emailCred);
          user = res.user;
        }
        // CASE B: No User (or previous anonymous failed) -> Create New Account
        else if (user == null) {
          try {
            final res = await auth.createUserWithEmailAndPassword(
                email: email, password: password);
            user = res.user;
          } catch (e) {
            // If email already in use, we might want to just sign them in?
            // But we don't know the password.
            // Ideally we just update the Firestore doc if they exist, but we can't login.
            // For now, we assume it's a new guest. If exists, we catch error.
            print("Create user failed (likely exists): $e");
            // If user exists, we can't "log them in" without password.
            // We will proceed without stopping the order, but we can't attach the new account session.
            // The order will be placed with the email string stored in the order doc.
            return;
          }
        }

        // If we successfully have a user (upgraded or created)
        if (user != null && !user.isAnonymous) {
          final uid = user.uid;

          // Construct Address JSON for Firestore
          final addrJson = shippingAddr != null
              ? {
                  'address1': shippingAddr.address ?? '',
                  'address2': '', // Add if available
                  'city': shippingAddr.city ?? '',
                  'state': shippingAddr.state ?? '',
                  'zip': shippingAddr.zip_code ?? '',
                  'country': shippingAddr.country ?? '',
                }
              : {};

          // Create/Update User Document
          final userRef =
              FirebaseFirestore.instance.collection('Users').doc(uid);
          String existingRole = '';
          String existingUserType = '';
          bool existed = false;
          try {
            final snap = await userRef.get();
            existed = snap.exists;
            final data = snap.data() as Map<String, dynamic>? ?? {};
            existingRole = (data['role'] ?? '').toString().trim();
            existingUserType = (data['user_type'] ?? '').toString().trim();
          } catch (_) {}

          final isAdmin = existingRole.toLowerCase() == 'admin' ||
              existingUserType.toLowerCase() == 'admin';

          await userRef.set({
            'uid': uid,
            'email': email,
            'full_name': name,
            'phone': contactPhone.trim(),
            if (!existed) 'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
            if (!isAdmin) 'user_type': 'customer',
            if (!isAdmin) 'role': 'customer',
            if (isAdmin) 'role': 'admin',
            'status': 'active',
            'billing_address': addrJson,
            'delivery_address': addrJson,
            'terms_accepted': true,
          }, SetOptions(merge: true));

          // Send Verification Email
          try {
            if (!user.emailVerified) {
              await user.sendEmailVerification();
            }
          } catch (_) {}

          // Migrate Guest Addresses if needed
          try {
            final gid = getStringAsync('guest_id');
            if (gid.isNotEmpty && gid != uid) {
              await AddressService().migrateGuestAddresses(gid, uid);
              await setValue('guest_id', uid);
              await _reloadAddresses();
            }
          } catch (_) {}
        }
      } catch (e) {
        print('Guest account creation/link failed: $e');
        // Don't block the order placement if account creation fails
      }
    }
  }

  Future<Uint8List> _buildInvoicePdfBytes({
    required String orderCode,
    required DateTime orderDate,
    required AmAddressModel shipping,
    required List<AmProductModel> products,
    required String shippingMethod,
    required double shippingCost,
    required String paymentMethod,
    required double grandTotal,
  }) async {
    final doc = pw.Document();
    double subTotal = 0;
    double vatTotal = 0;

    final List<List<String>> rows = [];
    for (int i = 0; i < products.length; i++) {
      final p = products[i];
      final qty = p.quantity ?? 1;
      final base = p.price ?? 0.0;
      final rate = (p.vatRate ?? 0.0) / 100.0;
      final unit = _includeVat ? base * (1 + rate) : base;
      final lineTotal = unit * qty;
      subTotal += base * qty;
      if (_includeVat) vatTotal += (base * rate) * qty;
      rows.add([
        (i + 1).toString(),
        (p.name ?? 'Product'),
        qty.toString(),
        '£${unit.toStringAsFixed(2)}',
        '£${lineTotal.toStringAsFixed(2)}',
      ]);
    }

    // Load logo asset for header
    pw.MemoryImage? logoImage;
    try {
      final data =
          await rootBundle.load('images/american-confectioners-ltd.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(24),
        ),
        header: (ctx) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                          width: 160,
                          height: 60,
                          child: pw.Image(logoImage!, fit: pw.BoxFit.contain)),
                    pw.SizedBox(height: 6),
                    pw.Text('Sweet Stop',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('United Kingdom',
                        style: const pw.TextStyle(fontSize: 10)),
                  ]),
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('INVOICE',
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text('Order: $orderCode',
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                        'Date: ${orderDate.year.toString().padLeft(4, '0')}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}',
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 8),
                    pw.Text('Total Paid: £${grandTotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  ]),
            ],
          );
        },
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To',
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text((shipping.full_name ?? contactName).trim()),
                      if ((shipping.address ?? '').trim().isNotEmpty)
                        pw.Text((shipping.address ?? '').trim()),
                      pw.Text(
                          '${(shipping.city ?? '').trim()} ${(shipping.state ?? '').trim()} ${(shipping.zip_code ?? '').trim()}'
                              .trim()),
                      pw.Text((shipping.country ?? '').trim()),
                    ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Payment: $paymentMethod'),
                      pw.Text('Shipping: $shippingMethod'),
                    ]),
              ]),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const ['#', 'Description', 'Qty', 'Rate', 'Amount'],
            data: rows,
            headerStyle:
                pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 12),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Subtotal: £${subTotal.toStringAsFixed(2)}'),
              pw.Text('VAT: £${vatTotal.toStringAsFixed(2)}'),
              pw.Text('Shipping: £${shippingCost.toStringAsFixed(2)}'),
              pw.SizedBox(height: 6),
              pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: pdf.PdfColors.grey300,
                  child: pw.Text(
                      'Total Paid: £${grandTotal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 4),
              pw.Text('Grand Total: £${grandTotal.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ])
          ]),
          pw.SizedBox(height: 20),
          pw.Text('Thank you for your business.',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    return doc.save();
  }

  Future<void> _sendOrderEmailWithInvoice({
    required String orderId,
    required String orderCode,
    required List<AmProductModel> orderProducts,
    required double orderTotalAmount,
    required double orderShippingCost,
    required double orderVatAmount,
    required String shippingMethod,
    required String paymentMethod,
    required AmAddressModel shippingAddress,
  }) async {
    final authEmail = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
    final contact = contactEmail.trim();
    final userRecipients = <String>{
      if (authEmail.isNotEmpty) authEmail,
      if (contact.isNotEmpty) contact,
    };
    if (userRecipients.isEmpty) return;

    final adminRecipients = <String>{};
    try {
      final adminSnap = await FirebaseFirestore.instance
          .collection('Users')
          .where('role', isEqualTo: 'admin')
          .get();
      for (final d in adminSnap.docs) {
        final data = d.data();
        final e = (data['email'] ?? '').toString().trim();
        if (e.isNotEmpty) adminRecipients.add(e);
      }
    } catch (_) {}

    final invoiceBytes = await _buildInvoicePdfBytes(
      orderCode: orderCode,
      orderDate: DateTime.now(),
      shipping: shippingAddress,
      products: orderProducts,
      shippingMethod: shippingMethod,
      shippingCost: orderShippingCost,
      paymentMethod: paymentMethod,
      grandTotal: orderTotalAmount,
    );

    final path = 'invoices/$orderId.pdf';
    final invoiceUrl = await StorageUpload.uploadBytes(
      invoiceBytes,
      path,
      contentType: 'application/pdf',
    );

    await FirebaseFirestore.instance.collection('Orders').doc(orderId).set({
      'invoice_url': invoiceUrl,
      'invoice_path': path,
      'vat_included': _includeVat,
      'invoice_generated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    String orderStatus = 'Pending';
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('Orders')
          .doc(orderId)
          .get();
      if (orderDoc.exists) {
        final d = orderDoc.data() as Map<String, dynamic>? ?? {};
        final s = (d['delivery_status'] ?? '').toString().trim();
        if (s.isNotEmpty) orderStatus = s;
      }
    } catch (_) {}

    final customerName = (shippingAddress.full_name ?? contactName).trim();
    final shipTo = <String>[
      (shippingAddress.address ?? '').trim(),
      (shippingAddress.city ?? '').trim(),
      (shippingAddress.state ?? '').trim(),
      (shippingAddress.zip_code ?? '').trim(),
      (shippingAddress.country ?? '').trim(),
    ].where((e) => e.isNotEmpty).join(', ');

    final productRows = orderProducts.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final p = entry.value;
      final qty = p.quantity ?? 1;
      final rate = p.price ?? 0.0;
      final amt = rate * qty;
      final name = (p.name ?? '').toString();
      return '''
        <tr>
          <td style="border:1px solid #1f2937;padding:8px;text-align:center;">$i</td>
          <td style="border:1px solid #1f2937;padding:8px;">$name</td>
          <td style="border:1px solid #1f2937;padding:8px;text-align:center;">$qty</td>
          <td style="border:1px solid #1f2937;padding:8px;text-align:right;">£${rate.toStringAsFixed(2)}</td>
          <td style="border:1px solid #1f2937;padding:8px;text-align:right;">£${amt.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }).join();

    final vatRow = _includeVat
        ? '''
          <tr>
            <td style="padding:2px 0;text-align:right;">VAT:</td>
            <td style="padding:2px 0 2px 24px;text-align:right;">£${orderVatAmount.toStringAsFixed(2)}</td>
          </tr>
        '''
        : '';

    final subtotal = (orderTotalAmount -
            orderShippingCost -
            (_includeVat ? orderVatAmount : 0.0))
        .clamp(0.0, double.infinity);

    try {
      // Create email document for Firebase "Trigger Email" Extension
      await FirebaseFirestore.instance.collection('mail').add({
        'to': userRecipients.toList(),
        if (adminRecipients.isNotEmpty) 'bcc': adminRecipients.toList(),
        'message': {
          'subject': 'Sweet Stop - Order confirmation $orderCode',
          'html': '''
            <div style="background:#f1f5f9;padding:24px 0;font-family:Arial,Helvetica,sans-serif;">
              <div style="max-width:720px;margin:0 auto;background:#ffffff;border:1px solid #e5e7eb;">
                <div style="background:#0a6a3c;color:#ffffff;padding:18px 24px;text-align:center;font-size:22px;font-weight:700;">
                  Sweet Stop
                </div>
                <div style="padding:22px 24px;color:#111827;">
                  <div style="font-size:16px;font-weight:700;">Hi ${customerName.isEmpty ? 'Customer' : customerName}</div>
                  <div style="margin-top:10px;font-size:14px;color:#374151;">
                    Thank you for your order with us. Here is your order id <b>$orderCode</b>.
                  </div>

                  <div style="margin-top:22px;text-align:center;font-size:20px;font-weight:700;color:#111827;">
                    Order information
                  </div>
                  <table style="margin-top:14px;border-top:1px solid #e5e7eb;border-collapse:collapse;width:100%;font-size:13px;">
                    <tr style="border-bottom:1px solid #e5e7eb;">
                      <td style="padding:12px 0;color:#6b7280;">Order ID</td>
                      <td style="padding:12px 0;text-align:right;font-weight:700;">$orderCode</td>
                    </tr>
                    <tr style="border-bottom:1px solid #e5e7eb;">
                      <td style="padding:12px 0;color:#6b7280;">Order Status</td>
                      <td style="padding:12px 0;text-align:right;font-weight:700;">$orderStatus</td>
                    </tr>
                    <tr style="border-bottom:1px solid #e5e7eb;">
                      <td style="padding:12px 0;color:#6b7280;">Payment method</td>
                      <td style="padding:12px 0;text-align:right;font-weight:700;">$paymentMethod</td>
                    </tr>
                    <tr style="border-bottom:1px solid #e5e7eb;">
                      <td style="padding:12px 0;color:#6b7280;">Shipping</td>
                      <td style="padding:12px 0;text-align:right;font-weight:700;">$shippingMethod</td>
                    </tr>
                    <tr style="border-bottom:1px solid #e5e7eb;">
                      <td style="padding:12px 0;color:#6b7280;">Shipping To</td>
                      <td style="padding:12px 0;text-align:right;font-weight:700;">${shipTo.isEmpty ? '-' : shipTo}</td>
                    </tr>
                  </table>

                  <div style="margin-top:26px;text-align:center;font-size:20px;font-weight:700;color:#111827;">
                    Order Details
                  </div>
                  <div style="margin-top:14px;">
                    <table style="border-collapse:collapse;width:100%;font-size:13px;">
                      <thead>
                        <tr style="background:#f3f4f6;">
                          <th style="border:1px solid #1f2937;padding:8px;width:40px;text-align:center;">#</th>
                          <th style="border:1px solid #1f2937;padding:8px;text-align:left;">Description</th>
                          <th style="border:1px solid #1f2937;padding:8px;width:70px;text-align:center;">Qty</th>
                          <th style="border:1px solid #1f2937;padding:8px;width:110px;text-align:right;">Rate</th>
                          <th style="border:1px solid #1f2937;padding:8px;width:120px;text-align:right;">Amount</th>
                        </tr>
                      </thead>
                      <tbody>
                        $productRows
                      </tbody>
                    </table>
                  </div>

                  <div style="margin-top:16px;color:#111827;font-size:14px;display:flex;justify-content:flex-end;">
                    <table style="border-collapse:collapse;font-size:14px;">
                      <tr>
                        <td style="padding:2px 0;text-align:right;">Subtotal:</td>
                        <td style="padding:2px 0 2px 24px;text-align:right;">£${subtotal.toStringAsFixed(2)}</td>
                      </tr>
                      <tr>
                        <td style="padding:2px 0;text-align:right;">Shipping:</td>
                        <td style="padding:2px 0 2px 24px;text-align:right;">£${orderShippingCost.toStringAsFixed(2)}</td>
                      </tr>
                      $vatRow
                      <tr>
                        <td style="padding:10px 0 0;text-align:right;font-weight:800;">Grand Total:</td>
                        <td style="padding:10px 0 0 24px;text-align:right;font-weight:800;">£${orderTotalAmount.toStringAsFixed(2)}</td>
                      </tr>
                    </table>
                  </div>

                  <div style="margin-top:18px;text-align:right;">
                    <a href="$invoiceUrl" style="display:inline-block;background:#0a6a3c;color:#ffffff;text-decoration:none;padding:10px 14px;border-radius:6px;font-size:14px;font-weight:700;">
                      Download Invoice PDF
                    </a>
                  </div>

                  <div style="margin-top:18px;font-size:14px;color:#374151;text-align:center;">
                    Thank you for your business.
                  </div>
                </div>
              </div>
            </div>
          ''',
          'text':
              'Sweet Stop\\n\\nHi ${customerName.isEmpty ? 'Customer' : customerName},\\n\\nThank you for your order. Order ID: $orderCode\\nStatus: $orderStatus\\nPayment: $paymentMethod\\nShipping: $shippingMethod\\nTotal: £${orderTotalAmount.toStringAsFixed(2)}\\nInvoice: $invoiceUrl',
          'attachments': [
            {
              'filename': 'invoice_$orderCode.pdf',
              'content': base64Encode(invoiceBytes),
              'encoding': 'base64',
              'contentType': 'application/pdf',
            }
          ],
        },
      });
    } catch (e) {
      print('SMTP send failed: $e');
    }
  }

  Future<void> _reloadAddresses() async {
    List<AmAddressModel> addresses = [];
    try {
      addresses = await AddressService().getUserAddresses().first;
    } catch (e) {}
    if (!mounted) return;
    setState(() {
      addressList.clear();
      addressList.addAll(addresses);
      if (addressList.isNotEmpty) {
        if (selectedAddressPosition >= addressList.length) {
          selectedAddressPosition = 0;
        }
        // Auto-fill Contact Info from selected address for Guest Users
        // or if contact info is currently empty.
        final addr = addressList[selectedAddressPosition];
        if (userModel == null || contactName.trim().isEmpty) {
          contactName = addr.full_name ?? '';
        }
        if (userModel == null || contactPhone.trim().isEmpty) {
          contactPhone = addr.phone ?? '';
        }
      } else {
        selectedAddressPosition = 0;
      }
    });
  }

  Future<void> _finalizeOrderGlobal(
      {Map<String, dynamic>? paymentDetails}) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Capture variables before clearing the cart
      final currentList = List<AmProductModel>.from(list);
      final currentTotalAmount = totalAmount;
      final currentShippingCost = shippingCost;
      final currentVatAmount = vatAmount;
      final currentShippingMethod =
          selectedShipping == ShippingOption.fastPaid ? "Express" : "Normal";
      final currentPaymentMethod = selectedPaymentMethod.trim().isEmpty
          ? (FirebaseAuth.instance.currentUser == null ? 'Guest' : 'Unknown')
          : selectedPaymentMethod.trim();
      final currentAddress = addressList[selectedAddressPosition];

      final res = await OrderService().placeOrder(
        products: currentList,
        shippingAddress: currentAddress,
        shippingOption: currentShippingMethod,
        shippingCost: currentShippingCost,
        paymentType: currentPaymentMethod,
        grandTotal: currentTotalAmount,
        vatIncluded: _includeVat,
        vatAmount: currentVatAmount,
        contactName: contactName,
        contactPhone: contactPhone,
        contactEmail: contactEmail,
        paymentDetails: paymentDetails,
      );

      await CartService().clearCart();
      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();

      unawaited(Future(() async {
        try {
          await _sendOrderEmailWithInvoice(
            orderId: res.orderId,
            orderCode: res.orderCode,
            orderProducts: currentList,
            orderTotalAmount: currentTotalAmount,
            orderShippingCost: currentShippingCost,
            orderVatAmount: currentVatAmount,
            shippingMethod: currentShippingMethod,
            paymentMethod: currentPaymentMethod,
            shippingAddress: currentAddress,
          );
        } catch (e) {
          print('Order email/invoice failed: $e');
        }
      }));
      if (!mounted) return;
      AmOrderSuccessScreen(orderNumber: res.orderCode)
          .launch(context, isNewTask: true);
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).maybePop();
      toast("Failed to place order: $e");
    }
  }

  /*
  // Deprecated manual CardField implementation - replaced by native Stripe Payment Sheet
  Future<void> _showStripeCardSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final bool isMobileSupported = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS);
        String? clientSecret;
        CardFieldInputDetails? cardDetails;
        bool loading = true;
        bool isInitializing = false;

        return StatefulBuilder(builder: (context, setState) {
          Future<void> _init() async {
            if (isInitializing) return;
            isInitializing = true;
            try {
              clientSecret = await StripeServices.instance
                  .getClientSecret(amount: totalAmount, currency: 'gbp');
            } catch (e) {
              toast(e.toString());
              Navigator.pop(context);
              return;
            }
            if (context.mounted) {
              setState(() {
                loading = false;
              });
            }
          }

          if ((isMobileSupported || kIsWeb) && loading) _init();

          return Padding(
            padding: EdgeInsets.only(
              left: spacing_standard_new,
              right: spacing_standard_new,
              top: spacing_standard_new,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom + spacing_standard,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add card', style: boldTextStyle(size: 18)),
                12.height,
                if (loading)
                  Container(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (isMobileSupported || kIsWeb)
                  Container(
                    height: 50,
                    child: CardField(
                      autofocus: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Card Details',
                        hintText: 'Number, MM/YY, CVC',
                        labelStyle: secondaryTextStyle(),
                        hintStyle: secondaryTextStyle(),
                      ),
                      style: TextStyle(
                        color: sh_textColorPrimary,
                        fontSize: 16,
                      ),
                      onCardChanged: (details) {
                        setState(() {
                          cardDetails = details;
                        });
                      },
                    ),
                  )
                else
                  Text(
                    'Stripe card entry is not supported on this platform.\nPlease run on Android, iOS, or Web.',
                    style: secondaryTextStyle(),
                  ),
                12.height,
                AppButton(
                  width: double.infinity,
                  text:
                      'Pay ${totalAmount.toCurrencyFormat().replaceAll('\$', '£')}',
                  color: sh_colorPrimary,
                  textColor: sh_white,
                  onTap: (loading || (!isMobileSupported && !kIsWeb))
                      ? () {
                          if (!loading) {
                            Navigator.pop(context);
                            toast(
                                'Stripe is not supported on Desktop. Use Android/iOS or Web.');
                          }
                        }
                      : (clientSecret == null ||
                              cardDetails == null ||
                              !(cardDetails?.complete ?? false))
                          ? null
                          : () async {
                              try {
                                await Stripe.instance.confirmPayment(
                                  paymentIntentClientSecret: clientSecret!,
                                  data: PaymentMethodParams.card(
                                    paymentMethodData: PaymentMethodData(),
                                  ),
                                );
                                Navigator.pop(context);
                                await _finalizeOrderGlobal();
                              } catch (e) {
                                toast(e.toString());
                              }
                            },
                ),
                8.height,
              ],
            ),
          );
        });
      },
    );
  }
  */

  // Custom Card Widget - Now uses consistent padding/margin similar to AmOrderListScreen
  Widget _buildCardBox(
      {required String title,
      required Widget content,
      required VoidCallback onEdit}) {
    return Container(
      // Use full-width padding similar to AmOrderListScreen structure
      margin: EdgeInsets.symmetric(vertical: spacing_control_half),
      padding: EdgeInsets.all(spacing_standard_new),
      color: context.cardColor, // Full width color
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: boldTextStyle(size: 18)),
              // Edit Button (Circle Golden)
              Container(
                padding: EdgeInsets.all(spacing_control),
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: sh_colorPrimary),
                child: Icon(Icons.edit, color: white, size: 16),
              ).onTap(onEdit),
            ],
          ),
          Divider(height: 16, color: sh_view_color),
          content,
        ],
      ),
    );
  }

  Widget _cartListWidget(double width) {
    return isLoaded
        ? ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: list.length,
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: spacing_standard_new),
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              AmProductModel product = list[index];
              int currentQty = product.quantity ?? 1;
              final double imgSize = min(width * 0.22, 72);
              final bool collapseRow = width < 420;
              final String imageSrc =
                  (product.thumbnail != null && product.thumbnail!.isNotEmpty)
                      ? product.thumbnail!
                      : ((product.images != null && product.images!.isNotEmpty)
                          ? product.images!.first
                          : '');

              return Container(
                padding: EdgeInsets.all(10.0),
                color: context.cardColor,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        width: imgSize,
                        height: imgSize,
                        decoration: BoxDecoration(shape: BoxShape.circle),
                        child: ClipOval(
                          child: imageSrc.isNotEmpty
                              ? (imageSrc.startsWith('http')
                                  ? CachedNetworkImage(
                                      imageUrl: imageSrc,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                          color: Colors.grey[200],
                                          child: Icon(Icons.image,
                                              color: Colors.grey)),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.error,
                                                  color: Colors.red)),
                                    )
                                  : Image.asset(
                                      "images/sweets/img/products" + imageSrc,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          Container(
                                              color: Colors.grey[200],
                                              child: Icon(Icons.broken_image,
                                                  color: Colors.grey)),
                                    ))
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.image_not_supported),
                                ),
                        ),
                      ).paddingRight(spacing_standard),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(product.name.toString(),
                                style: boldTextStyle(size: 16)),
                            LayoutBuilder(builder: (ctx, constraints) {
                              final bool collapse =
                                  collapseRow || constraints.maxWidth < 240;
                              final attrsText = Text(
                                "Size: ${product.variants?.size ?? "N/A"} | Flavor: ${product.variants?.flavor ?? "N/A"}",
                                style: boldTextStyle(size: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );

                              final qtyStepper = ConstrainedBox(
                                constraints:
                                    BoxConstraints(minWidth: 72, maxWidth: 110),
                                child: Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: sh_view_color, width: 1),
                                      borderRadius: radius(4)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.remove,
                                              color: appStore.isDarkModeOn
                                                  ? white
                                                  : sh_textColorPrimary,
                                              size: 16)
                                          .paddingAll(spacing_control_half)
                                          .onTap(() {
                                        _updateQuantity(
                                            product, currentQty - 1);
                                      }),
                                      VerticalDivider(
                                              width: 1,
                                              thickness: 1,
                                              color: sh_view_color)
                                          .withHeight(16),
                                      Text("$currentQty",
                                              style:
                                                  secondaryTextStyle(size: 14))
                                          .paddingSymmetric(
                                              horizontal: spacing_control),
                                      VerticalDivider(
                                              width: 1,
                                              thickness: 1,
                                              color: sh_view_color)
                                          .withHeight(16),
                                      Icon(Icons.add,
                                              color: appStore.isDarkModeOn
                                                  ? white
                                                  : sh_textColorPrimary,
                                              size: 16)
                                          .paddingAll(spacing_control_half)
                                          .onTap(() {
                                        _updateQuantity(
                                            product, currentQty + 1);
                                      }),
                                    ],
                                  ),
                                ),
                              );

                              final priceText = Text(
                                product.price.toString().toCurrencyFormat(),
                                style: boldTextStyle(
                                    color: appStore.isDarkModeOn
                                        ? sh_gradient_1st
                                        : sh_colorPrimary,
                                    size: 16),
                              );
                              if (collapse) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    attrsText,
                                    8.height,
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        qtyStepper,
                                        priceText,
                                      ],
                                    ),
                                  ],
                                ).paddingTop(8);
                              }

                              return Row(
                                children: <Widget>[
                                  Expanded(child: attrsText),
                                  8.width,
                                  qtyStepper,
                                ],
                              ).paddingTop(8);
                            })
                          ],
                        ),
                      ),
                      Visibility(
                        visible: !collapseRow,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(product.price.toString().toCurrencyFormat(),
                                style: boldTextStyle(
                                    color: appStore.isDarkModeOn
                                        ? sh_gradient_1st
                                        : sh_colorPrimary,
                                    size: 16)),
                            8.height,
                            Icon(Icons.delete_outline, color: sh_red, size: 24)
                                .onTap(() async {
                              showConfirmDialogCustom(
                                context,
                                onAccept: (c) {
                                  if (product.id != null) {
                                    CartService().removeFromCart(product.id!);
                                  }
                                },
                                dialogType: DialogType.DELETE,
                                title:
                                    "Are you sure you want to remove this item?",
                                positiveText: "Remove",
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
        : Container();
  }

  Widget _shippingAddressCardWidget() {
    return _buildCardBox(
      title: "Shipping Address",
      content: addressList.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(addressList[selectedAddressPosition].full_name.validate(),
                    style: primaryTextStyle()),
                Text(
                  "${addressList[selectedAddressPosition].address.validate()}, ${addressList[selectedAddressPosition].city.validate()}",
                  style: secondaryTextStyle(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          : Text("No shipping address found. Tap the edit icon to add one.",
              style: secondaryTextStyle()),
      onEdit: () async {
        if (addressList.isNotEmpty) {
          var pos = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext context) =>
                          AmAddressManagerScreen())) ??
              selectedAddressPosition;
          await _reloadAddresses();
          if (addressList.isNotEmpty) {
            setState(() {
              if (pos is int && pos >= 0 && pos < addressList.length) {
                selectedAddressPosition = pos;
              } else {
                selectedAddressPosition = 0;
              }
            });
          }
        } else {
          var added = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => AmAddNewAddress()),
          );
          if (added == true) {
            await _reloadAddresses();
          }
        }
      },
    );
  }

  Widget _contactInfoCardWidget() {
    return _buildCardBox(
      title: "Contact Information",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 16, color: sh_textColorSecondary),
              4.width,
              Text(contactName, style: primaryTextStyle()),
            ],
          ),
          4.height,
          Row(
            children: [
              Icon(Icons.phone, size: 16, color: sh_textColorSecondary),
              4.width,
              Text(contactPhone, style: primaryTextStyle()),
            ],
          ),
          4.height,
          Row(
            children: [
              Icon(Icons.email, size: 16, color: sh_textColorSecondary),
              4.width,
              Text(contactEmail, style: primaryTextStyle()),
            ],
          ),
        ],
      ),
      onEdit: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final nameController = TextEditingController(text: contactName);
            final phoneController = TextEditingController(text: contactPhone);
            final emailController = TextEditingController(text: contactEmail);

            return AlertDialog(
              title: Text("Edit Contact Information",
                  style: boldTextStyle(size: 18)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    16.height,
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    16.height,
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => finish(context),
                  child: Text("Cancel", style: secondaryTextStyle()),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      contactName = nameController.text.trim();
                      contactPhone = phoneController.text.trim();
                      contactEmail = emailController.text.trim();
                      if (userModel != null) {
                        userModel!.fullName = contactName;
                        userModel!.phone = contactPhone;
                        userModel!.email = contactEmail;
                      }
                    });
                    finish(context);
                  },
                  child: Text("Save",
                      style: boldTextStyle(color: sh_colorPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _shippingOptionSectionWidget() {
    return Container(
      margin: EdgeInsets.fromLTRB(spacing_standard_new, spacing_control_half,
          spacing_standard_new, spacing_control_half),
      padding: EdgeInsets.all(spacing_standard_new),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sh_view_color, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Shipping Option", style: boldTextStyle(size: 18))
              .paddingBottom(spacing_standard),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(shape: BoxShape.circle),
                child: Radio<ShippingOption>(
                  value: ShippingOption.normalFree,
                  groupValue: selectedShipping,
                  onChanged: (ShippingOption? value) {
                    setState(() {
                      selectedShipping = value!;
                      _calculateTotal();
                    });
                  },
                  fillColor: WidgetStateProperty.all(Colors.green),
                ),
              ),
              Expanded(
                child: Text("Normal 3-5 days Free", style: primaryTextStyle())
                    .paddingLeft(8),
              ),
              Text("Free", style: boldTextStyle(color: Colors.green)),
            ],
          ).paddingBottom(spacing_control),
          Row(
            children: [
              Radio<ShippingOption>(
                value: ShippingOption.fastPaid,
                groupValue: selectedShipping,
                onChanged: (ShippingOption? value) {
                  setState(() {
                    selectedShipping = value!;
                    _calculateTotal();
                  });
                },
                fillColor: WidgetStateProperty.all(Colors.green),
              ),
              Expanded(
                child: Text("Express 1-2 days", style: primaryTextStyle())
                    .paddingLeft(8),
              ),
              Text('£50',
                  style: boldTextStyle(
                      color: appStore.isDarkModeOn
                          ? sh_gradient_1st
                          : sh_colorPrimary)),
            ],
          ).paddingBottom(spacing_standard),
          Divider(height: 1, color: sh_view_color),
          10.height,
          Text("Delivered on or before $deliveryDate",
              style: secondaryTextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _paymentSectionWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payment_methods')
          .snapshots()
          .asBroadcastStream(),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> methods = snapshot.hasData
            ? snapshot.data!.docs
                .map((e) => e.data() as Map<String, dynamic>)
                .toList()
            : [];
        final parsed = methods.map((m) => AmPaymentMethod.fromJson(m)).toList();
        final enabled = parsed.where((m) {
          if (m.type == 'stripe') return true; // if configured, show
          return m.enabled == true;
        }).toList();
        // Keep a reference to bank admin config for later save
        final bank = parsed.firstWhere((m) => (m.type ?? '') == 'bank',
            orElse: () => AmPaymentMethod(type: 'bank'));
        _bankAdmin = bank;

        return Container(
          margin: EdgeInsets.fromLTRB(spacing_standard_new,
              spacing_control_half, spacing_standard_new, spacing_control_half),
          padding: EdgeInsets.all(spacing_standard_new),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sh_view_color, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Payment", style: boldTextStyle(size: 18))
                  .paddingBottom(spacing_standard),
              if (!snapshot.hasData)
                Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator()),
              ...enabled.map((m) {
                final label = m.type == 'stripe'
                    ? 'Stripe'
                    : (m.type == 'cod' ? 'Cash on Delivery' : 'Bank Transfer');
                return RadioListTile<String>(
                  title: Text(label, style: primaryTextStyle()),
                  value: label,
                  groupValue: selectedPaymentMethod,
                  onChanged: (String? value) {
                    setState(() {
                      selectedPaymentMethod = value!;
                    });
                  },
                  dense: true,
                  fillColor: WidgetStateProperty.all(sh_colorPrimary),
                );
              }).toList(),
              if (selectedPaymentMethod == 'Bank Transfer') ...[
                8.height,
                Divider(height: 1, color: sh_view_color),
                8.height,
                Text('Bank Details', style: boldTextStyle(size: 16)),
                6.height,
                if (_bankAdmin != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((_bankAdmin!.bankName ?? '').isNotEmpty)
                        Text('Bank: ${_bankAdmin!.bankName}',
                            style: secondaryTextStyle()),
                      if ((_bankAdmin!.accountHolderName ?? '').isNotEmpty)
                        Text('Account Holder: ${_bankAdmin!.accountHolderName}',
                            style: secondaryTextStyle()),
                      if ((_bankAdmin!.iban ?? '').isNotEmpty)
                        Text('IBAN: ${_bankAdmin!.iban}',
                            style: secondaryTextStyle()),
                      if ((_bankAdmin!.bicSwift ?? '').isNotEmpty)
                        Text('BIC/SWIFT: ${_bankAdmin!.bicSwift}',
                            style: secondaryTextStyle()),
                      if ((_bankAdmin!.paymentReference ?? '').isNotEmpty)
                        Text('Reference: ${_bankAdmin!.paymentReference}',
                            style: secondaryTextStyle()),
                      if ((_bankAdmin!.bankAddress ?? '').isNotEmpty)
                        Text('Bank Address: ${_bankAdmin!.bankAddress}',
                            style: secondaryTextStyle()),
                      if ((_bankAdmin!.country ?? '').isNotEmpty)
                        Text('Country: ${_bankAdmin!.country}',
                            style: secondaryTextStyle()),
                    ],
                  ),
                12.height,
                Text('Your Payment', style: boldTextStyle(size: 16)),
                8.height,
                // Payment Date
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _bankPaymentDate ?? now,
                      firstDate: DateTime(now.year - 1),
                      lastDate: DateTime(now.year + 1),
                    );
                    if (picked != null) {
                      setState(() {
                        _bankPaymentDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: spacing_standard, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: sh_view_color),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _bankPaymentDate != null
                              ? '${_bankPaymentDate!.day.toString().padLeft(2, '0')}/${_bankPaymentDate!.month.toString().padLeft(2, '0')}/${_bankPaymentDate!.year}'
                              : 'Payment Date',
                          style: primaryTextStyle(),
                        ),
                        Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                12.height,
                Row(
                  children: [
                    AppButton(
                      text: _bankUploading
                          ? 'Uploading...'
                          : 'Upload Payment Proof',
                      textColor: white,
                      color: sh_colorPrimary,
                      onTap: _bankUploading ? null : _pickAndUploadBankProof,
                    ),
                    12.width,
                    if (_bankProofUrl != null && _bankProofUrl!.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          6.width,
                          Text('Uploaded', style: secondaryTextStyle()),
                        ],
                      )
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _summaryDetailWidget() {
    return Container(
      margin: EdgeInsets.fromLTRB(spacing_standard_new, spacing_control_half,
          spacing_standard_new, spacing_standard_new),
      padding: EdgeInsets.all(spacing_standard_new),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: sh_view_color, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Summary", style: boldTextStyle(size: 18))
              .paddingBottom(spacing_standard),
          Divider(height: 1, color: sh_view_color),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text("Include VAT",
                  textColor:
                      appStore.isDarkModeOn ? white : sh_textColorPrimary),
              Switch(
                value: _includeVat,
                thumbColor: WidgetStateProperty.all(sh_colorPrimary),
                onChanged: (value) {
                  setState(() {
                    _includeVat = value;
                    setValue('include_vat', _includeVat);
                    _calculateTotal();
                  });
                },
              ),
            ],
          ).paddingTop(spacing_middle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text("Subtotal",
                  textColor:
                      appStore.isDarkModeOn ? white : sh_textColorPrimary),
              text(subtotal.toCurrencyFormat(),
                  textColor:
                      appStore.isDarkModeOn ? white : sh_textColorPrimary,
                  fontFamily: fontMedium),
            ],
          ).paddingTop(spacing_middle),
          8.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              text("Shipping",
                  textColor:
                      appStore.isDarkModeOn ? white : sh_textColorPrimary),
              text(shippingCost.toCurrencyFormat(),
                  textColor: shippingCost > 0
                      ? (appStore.isDarkModeOn ? white : sh_textColorPrimary)
                      : Colors.green,
                  fontFamily: fontMedium),
            ],
          ).paddingBottom(spacing_middle),
          if (_includeVat && vatAmount > 0) ...[
            8.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                text("VAT",
                    textColor:
                        appStore.isDarkModeOn ? white : sh_textColorPrimary),
                text(vatAmount.toCurrencyFormat(),
                    textColor:
                        appStore.isDarkModeOn ? white : sh_textColorPrimary,
                    fontFamily: fontMedium),
              ],
            ),
            8.height,
          ],
          Divider(height: 1, color: sh_view_color),
          8.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text("Total", style: boldTextStyle(size: 18)),
              Text(totalAmount.toCurrencyFormat(),
                  style: boldTextStyle(
                      color: appStore.isDarkModeOn
                          ? sh_gradient_1st
                          : sh_colorPrimary,
                      size: 18)),
            ],
          ).paddingBottom(spacing_control),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadBankProof() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        toast('Unable to read file bytes');
        return;
      }
      setState(() {
        _bankUploading = true;
      });
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
      final contentType = file.extension != null
          ? 'application/${file.extension}'
          : 'application/octet-stream';
      final url = await StorageUpload.uploadBytes(
        file.bytes!,
        'payment_proofs/$fileName',
        contentType: contentType,
      );
      setState(() {
        _bankProofUrl = url;
        _bankUploading = false;
      });
      toast('Proof uploaded');
    } catch (e) {
      setState(() {
        _bankUploading = false;
      });
      toast('Upload failed: $e');
    }
  }

  Widget _placeOrderButtonWidget() {
    return Container(
      height: 60,
      width: double.infinity,
      margin: EdgeInsets.only(
          left: spacing_standard_new,
          right: spacing_standard_new,
          bottom: spacing_standard_new),
      child: AppButton(
        width: double.infinity,
        onTap: () async {
          if (list.isEmpty) {
            toast('Your cart is empty.');
            return;
          }
          if (addressList.isEmpty) {
            toast('Please add a shipping address.');
            return;
          }
          final name = contactName.trim();
          final phone = contactPhone.trim();
          final email = contactEmail.trim();
          if (name.isEmpty || phone.isEmpty || email.isEmpty) {
            toast('Please fill all Contact Information fields.');
            return;
          }
          final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
          if (!emailOk) {
            toast('Please add a valid email in Contact Information');
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(child: CircularProgressIndicator()),
          );

          try {
            if (selectedPaymentMethod == 'Stripe') {
              await _ensureGuestAccountIfNeeded();
              finish(context);
              await StripeServices.instance.makePayment(
                amount: totalAmount,
                currency: 'gbp',
                onSuccess: () async {
                  await _finalizeOrderGlobal();
                },
                onError: (error) {
                  toast(error);
                },
              );
            } else if (selectedPaymentMethod == 'Bank Transfer') {
              if (_bankPaymentDate == null) {
                toast('Please select Payment Date');
                Navigator.of(context, rootNavigator: true).pop();
                return;
              }
              await _ensureGuestAccountIfNeeded();
              final details = {
                'method': 'bank_transfer',
                'payment_date': Timestamp.fromDate(_bankPaymentDate!),
                'proof_url': _bankProofUrl ?? '',
                'admin_bank': {
                  'bank_name': _bankAdmin?.bankName ?? '',
                  'account_holder': _bankAdmin?.accountHolderName ?? '',
                  'iban': _bankAdmin?.iban ?? '',
                  'bic_swift': _bankAdmin?.bicSwift ?? '',
                  'payment_reference_instruction':
                      _bankAdmin?.paymentReference ?? '',
                  'bank_address': _bankAdmin?.bankAddress ?? '',
                  'country': _bankAdmin?.country ?? '',
                }
              };
              await _finalizeOrderGlobal(paymentDetails: details);
            } else {
              await _ensureGuestAccountIfNeeded();
              await _finalizeOrderGlobal();
            }
          } catch (e) {
            toast(e.toString());
          }
        },
        text: "Place Order",
        color: sh_colorPrimary,
        textColor: sh_white,
        textStyle: boldTextStyle(color: sh_white, size: 18),
        shapeBorder:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Review Order Summary", style: boldTextStyle(size: 18)),
          centerTitle: true,
          iconTheme: IconThemeData(
              color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
            onPressed: () {
              Navigator.maybePop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: spacing_standard_new),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(spacing_standard_new),
                  child: Text('Items (${list.length})',
                      style: boldTextStyle(size: 18)),
                ),
                if (list.isEmpty) ...[
                  40.height,
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: sh_textColorSecondary),
                        8.height,
                        Text('Items (0)', style: boldTextStyle(size: 16)),
                      ],
                    ),
                  ),
                ] else ...[
                  _cartListWidget(width),
                  _shippingAddressCardWidget(),
                  _contactInfoCardWidget(),
                  _shippingOptionSectionWidget(),
                  _paymentSectionWidget(),
                  _summaryDetailWidget(),
                  16.height,
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: _placeOrderButtonWidget(),
      ),
    );
  }
}
