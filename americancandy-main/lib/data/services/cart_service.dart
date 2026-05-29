import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:math';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _cartCollection => _db.collection('cart_product');
  CollectionReference get _productsCollection => _db.collection('Products');

  Future<String> _ensureUserId() async {
    final user = _auth.currentUser;
    if (user != null) return user.uid;
    var gid = getStringAsync('guest_id');
    if (gid.isEmpty) {
      gid =
          'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      await setValue('guest_id', gid);
    }
    return gid;
  }

  // Add to cart
  Future<void> addToCart(AmProductModel product, {int quantity = 1}) async {
    final uid = await _ensureUserId();
    if (product.id == null) throw Exception("Product ID is null");
    if (quantity < 1) return;

    final stock = await _fetchProductStock(product.id!);
    if (stock.status != 'active') throw Exception('Product unavailable');
    if (stock.available <= 0) throw Exception('Out of Stock');

    final size = (product.variants?.size ?? '').toString();
    final flavor = (product.variants?.flavor ?? '').toString();
    final packaging = (product.variants?.packaging ?? '').toString();
    final country = (product.variants?.country ?? '').toString();

    // Check if already in cart
    final query = await _cartCollection
        .where('user_id', isEqualTo: uid)
        .where('product_id', isEqualTo: product.id)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Update quantity
      final doc = query.docs.first;
      final currentQuantity =
          (doc.data() as Map<String, dynamic>)['quantity'] ?? 0;
      final int next = (currentQuantity as num).toInt() + quantity;
      if (next > stock.available) {
        throw Exception('Only ${stock.available} left');
      }
      final update = <String, dynamic>{
        'quantity': next,
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (size.trim().isNotEmpty) update['size'] = size.trim();
      if (flavor.trim().isNotEmpty) update['flavor'] = flavor.trim();
      if (packaging.trim().isNotEmpty) update['packaging'] = packaging.trim();
      if (country.trim().isNotEmpty) update['country'] = country.trim();
      await doc.reference.update(update);
    } else {
      if (quantity > stock.available) {
        throw Exception('Only ${stock.available} left');
      }
      // Add new item
      // Construct image url
      String imageUrl = "";
      if (product.images != null && product.images!.isNotEmpty) {
        imageUrl = product.images![0];
      } else if (product.thumbnail != null) {
        imageUrl = product.thumbnail!;
      }

      await _cartCollection.add({
        'user_id': uid,
        'product_id': product.id,
        'name': product.name,
        'price': product.price ?? 0.0,
        'vat_rate': product.vatRate ?? 0.0,
        'quantity': quantity,
        'image': imageUrl,
        'sku': product.sku ?? "",
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'size': size.trim(),
        'flavor': flavor.trim(),
        'packaging': packaging.trim(),
        'country': country.trim(),
        // Adding fields from cart_products.json as reference, though some might be redundant or not fully applicable without product fetch
        'status': 'active',
      });
    }
  }

  // Remove from cart
  Future<void> removeFromCart(String productId) async {
    final uid = await _ensureUserId();

    final query = await _cartCollection
        .where('user_id', isEqualTo: uid)
        .where('product_id', isEqualTo: productId)
        .get();

    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // Update quantity
  Future<void> updateQuantity(String productId, int newQuantity) async {
    final uid = await _ensureUserId();
    if (newQuantity < 1) return;

    final stock = await _fetchProductStock(productId);

    final query = await _cartCollection
        .where('user_id', isEqualTo: uid)
        .where('product_id', isEqualTo: productId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      if (stock.available <= 0 || stock.status != 'active') {
        await query.docs.first.reference.delete();
        return;
      }
      final int clamped =
          newQuantity > stock.available ? stock.available : newQuantity;
      await query.docs.first.reference.update({
        'quantity': clamped,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get user cart items
  Stream<QuerySnapshot> getCartStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _cartCollection.where('user_id', isEqualTo: user.uid).snapshots();
    }
    var gid = getStringAsync('guest_id');
    if (gid.isEmpty) {
      gid =
          'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      setValue('guest_id', gid);
    }
    return _cartCollection.where('user_id', isEqualTo: gid).snapshots();
  }

  // Clear cart
  Future<void> clearCart() async {
    final user = _auth.currentUser;
    String id;
    if (user != null) {
      id = user.uid;
    } else {
      var gid = getStringAsync('guest_id');
      if (gid.isEmpty) return;
      id = gid;
    }
    final query = await _cartCollection.where('user_id', isEqualTo: id).get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  Future<_ProductStock> _fetchProductStock(String productId) async {
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) return const _ProductStock(0, 'inactive');
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final available =
        int.tryParse((data['available_quantity'] ?? 0).toString()) ?? 0;
    final status = (data['product_status'] ?? 'active').toString();
    return _ProductStock(available, status);
  }
}

class _ProductStock {
  final int available;
  final String status;
  const _ProductStock(this.available, this.status);
}
