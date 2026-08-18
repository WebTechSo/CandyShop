import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/data/services/notification_service.dart';
import 'package:nb_utils/nb_utils.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<OrderPlacementResult> placeOrder({
    required List<AmProductModel> products,
    required AmAddressModel shippingAddress,
    required String shippingOption, // "Normal" or "Express"
    required double shippingCost,
    required String paymentType, // "Cash on Delivery" or "Stripe"
    required double grandTotal,
    bool vatIncluded = false,
    double vatAmount = 0.0,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    Map<String, dynamic>? paymentDetails,
  }) async {
    var user = _auth.currentUser;
    String uid;
    if (user != null) {
      uid = user.uid;
    } else {
      var gid = getStringAsync('guest_id');
      if (gid.isEmpty) {
        gid =
            'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        await setValue('guest_id', gid);
      }
      uid = gid;
    }

    final String orderId = _firestore.collection('Orders').doc().id;
    final String orderCode = _generateOrderCode();
    final DateTime now = DateTime.now();

    double itemsSubtotal = 0.0;
    for (final p in products) {
      final qty = p.quantity ?? 1;
      final price = p.price ?? 0.0;
      itemsSubtotal += (price * qty);
    }

    String customerType = 'guest';
    try {
      if (user != null) {
        customerType = 'customer';
        final userDoc =
            await _firestore.collection('Users').doc(user.uid).get();
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        final businessName = (data['business_name'] ?? '').toString().trim();
        if (businessName.isNotEmpty) customerType = 'b2b';
      } else {
        final email = (contactEmail ?? '').toString().trim().toLowerCase();
        if (email.isNotEmpty) {
          final snap = await _firestore
              .collection('Users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            final data = snap.docs.first.data();
            final businessName =
                (data['business_name'] ?? '').toString().trim();
            customerType = businessName.isNotEmpty ? 'b2b' : 'customer';
          } else {
            customerType = 'guest';
          }
        }
      }
    } catch (_) {}

    // 1. Prepare Order Data
    final orderData = {
      'id': orderId,
      'user_id': uid,
      'shipping_address': shippingAddress.toJson(),
      'shipping_option': shippingOption,
      'shipping_cost': shippingCost,
      'delivery_status': 'Pending',
      'payment_type': paymentType,
      'payment_status': 'Pending',
      'payment_details': paymentDetails ?? {},
      'grand_total': grandTotal,
      'items_subtotal': itemsSubtotal,
      'vat_included': vatIncluded,
      'vat_amount': vatIncluded ? vatAmount : 0.0,
      'order_code': orderCode,
      'tracking_code': '',
      'order_date': Timestamp.fromDate(now),
      'delivered_date': null,
      'contact_name': contactName ?? '',
      'contact_phone': contactPhone ?? '',
      'contact_email': contactEmail ?? '',
      'customer_type': customerType,
    };

    final orderRef = _firestore.collection('Orders').doc(orderId);

    await _firestore.runTransaction((tx) async {
      for (final product in products) {
        final pid = product.id;
        if (pid == null) throw Exception('Product ID is null');
        final qty = product.quantity ?? 1;
        if (qty < 1) throw Exception('Invalid quantity');

        final prodRef = _firestore.collection('Products').doc(pid);
        final prodSnap = await tx.get(prodRef);
        if (!prodSnap.exists) {
          throw Exception('Product not found');
        }
        final data = prodSnap.data() as Map<String, dynamic>? ?? {};
        final status = (data['product_status'] ?? 'active').toString();
        final available =
            int.tryParse((data['available_quantity'] ?? 0).toString()) ?? 0;
        if (status != 'active') throw Exception('Product unavailable');
        if (available < qty) throw Exception('Out of Stock');

        tx.update(prodRef, {
          'available_quantity': FieldValue.increment(-qty),
        });
      }

      tx.set(orderRef, orderData);

      for (final product in products) {
        final String itemId = _firestore.collection('order_items').doc().id;
        final itemRef = _firestore.collection('order_items').doc(itemId);

        String imgUrl = '';
        if (product.images != null && product.images!.isNotEmpty) {
          imgUrl = product.images![0];
        } else if (product.thumbnail != null) {
          imgUrl = product.thumbnail!;
        }

        final itemData = {
          'id': itemId,
          'order_id': orderId,
          'product_id': product.id,
          'product_name': product.name ?? 'Unknown Product',
          'product_image': imgUrl,
          'variation': product.variants?.size ?? '',
          'size': product.variants?.size ?? '',
          'flavor': product.variants?.flavor ?? '',
          'packaging': product.variants?.packaging ?? '',
          'country': product.variants?.country ?? '',
          'price': product.price,
          'tax': 0.0,
          'quantity': product.quantity ?? 1,
          'order_date': Timestamp.fromDate(now),
        };

        tx.set(itemRef, itemData);
      }
    });

    await NotificationService().createNotification(
      userId: uid,
      title: 'Order Placed',
      description: 'Your order $orderCode has been placed successfully.',
      type: 'order',
      isRead: false,
      orderId: orderId,
      action: 'order_detail',
      priority: 'normal',
    );

    return OrderPlacementResult(orderId: orderId, orderCode: orderCode);
  }

  String _generateOrderCode() {
    final now = DateTime.now();
    final dateStr =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final random = Random();
    final uniqueId = List.generate(8, (index) => random.nextInt(10)).join();
    return "$dateStr-$uniqueId";
  }

  // Get User Orders
  Stream<List<AmOrder>> getUserOrders() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('Orders')
        .where('user_id', isEqualTo: user.uid)
        .snapshots()
        .asBroadcastStream()
        .map((snapshot) {
      var orders =
          snapshot.docs.map((doc) => AmOrder.fromSnapshot(doc)).toList();
      // Sort client-side to avoid needing a composite index
      orders.sort((a, b) {
        if (a.orderDate == null) return 1;
        if (b.orderDate == null) return -1;
        return b.orderDate!.compareTo(a.orderDate!);
      });
      return orders;
    });
  }

  // Get All Orders (Admin)
  Stream<List<AmOrder>> getAllOrders() {
    return _firestore.collection('Orders').snapshots().map((snapshot) {
      var orders =
          snapshot.docs.map((doc) => AmOrder.fromSnapshot(doc)).toList();
      // Sort client-side
      orders.sort((a, b) {
        if (a.orderDate == null) return 1;
        if (b.orderDate == null) return -1;
        return b.orderDate!.compareTo(a.orderDate!);
      });
      return orders;
    });
  }

  // Update Order Status -- if new status is cancelled then restocked
  Future<void> updateOrderStatus(String orderId, String status) async {
    final orderRef = _firestore.collection('Orders').doc(orderId);

    await _firestore.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        throw Exception('Order not found');
      }
      final currentStatus = orderSnap.data()?['delivery_status'] ?? '';
      if (currentStatus == 'Cancelled') {
        throw Exception('Order is already cancelled');
      }
      tx.update(orderRef, {'delivery_status': status});

      if (status == 'Cancelled') {
        final itemsSnap = await _firestore
            .collection('order_items')
            .where('order_id', isEqualTo: orderId)
            .get();

        for (final itemDoc in itemsSnap.docs) {
          final data = itemDoc.data();
          final String? productId = data['product_id'];
          final int quantity = (data['quantity'] ?? 1) as int;

          if (productId != null && productId.isNotEmpty) {
            final prodRef = _firestore.collection('Products').doc(productId);

            tx.update(prodRef, {
              'available_quantity': FieldValue.increment(quantity),
            });
          }
        }
      }
    });
  }

  // Get Order Items for a specific Order
  Future<List<AmOrderItem>> getOrderItems(String orderId) async {
    final query = await _firestore
        .collection('order_items')
        .where('order_id', isEqualTo: orderId)
        .get();

    List<AmOrderItem> items =
        query.docs.map((doc) => AmOrderItem.fromSnapshot(doc)).toList();

    // Fetch product details for each item to get name and image
    for (var item in items) {
      // Only fetch if name/image are missing (backward compatibility)
      if (item.productId != null &&
          (item.productName == null || item.productName!.isEmpty)) {
        try {
          // Assuming 'products' collection. If it fails, name/image will be null, handled in UI.
          final prodDoc =
              await _firestore.collection('products').doc(item.productId).get();
          if (prodDoc.exists) {
            final data = prodDoc.data();
            if (data != null) {
              item.productName = data['name'];
              // Handle image (could be string or list)
              if (data['images'] != null &&
                  (data['images'] as List).isNotEmpty) {
                var img = (data['images'] as List)[0];
                if (img is String) {
                  item.productImage = img.replaceAll('"', '').trim();
                } else if (img is Map && img.containsKey('src')) {
                  item.productImage =
                      img['src'].toString().replaceAll('"', '').trim();
                }
              } else if (data['thumbnail'] != null) {
                item.productImage =
                    data['thumbnail'].toString().replaceAll('"', '').trim();
              }
            }
          }
        } catch (e) {
          print("Error fetching product details for item ${item.id}: $e");
        }
      }
    }
    return items;
  }
}

class OrderPlacementResult {
  final String orderId;
  final String orderCode;
  const OrderPlacementResult({required this.orderId, required this.orderCode});
}
