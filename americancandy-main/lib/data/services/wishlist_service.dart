import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:math';

class WishlistService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _wishlistCollection => _db.collection('UserWishlist');
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

  // Add to wishlist
  Future<void> addToWishlist(String productId) async {
    final uid = await _ensureUserId();
    final docRef = _wishlistCollection.doc('${uid}_$productId');
    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (snap.exists) return;
      tx.set(docRef, {
        'user_id': uid,
        'product_id': productId,
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  // Remove from wishlist
  Future<void> removeFromWishlist(String productId) async {
    final uid = await _ensureUserId();

    final batch = _db.batch();

    final docRef = _wishlistCollection.doc('${uid}_$productId');
    batch.delete(docRef);

    final query = await _wishlistCollection
        .where('user_id', isEqualTo: uid)
        .where('product_id', isEqualTo: productId)
        .get();

    for (var doc in query.docs) {
      if (doc.reference.path == docRef.path) continue;
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Check if product is in wishlist
  Future<bool> isInWishlist(String productId) async {
    final uid = await _ensureUserId();

    final doc = await _wishlistCollection.doc('${uid}_$productId').get();
    if (doc.exists) return true;

    final query = await _wishlistCollection
        .where('user_id', isEqualTo: uid)
        .where('product_id', isEqualTo: productId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // Get user wishlist products
  Future<List<AmProductModel>> getUserWishlist() async {
    final uid = await _ensureUserId();

    // Get wishlist items
    final wishlistSnapshot =
        await _wishlistCollection.where('user_id', isEqualTo: uid).get();

    if (wishlistSnapshot.docs.isEmpty) return [];

    // Sort in memory
    var docs = wishlistSnapshot.docs.toList();
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      Timestamp? t1 = dataA['created_at'] as Timestamp?;
      Timestamp? t2 = dataB['created_at'] as Timestamp?;
      if (t1 == null && t2 == null) return 0;
      if (t1 == null) return 1;
      if (t2 == null) return -1;
      return t2.compareTo(t1); // Descending
    });

    List<String> productIds =
        docs.map((doc) => (doc['product_id'] ?? '').toString()).toList();
    final seen = <String>{};
    productIds = productIds.where((id) => seen.add(id)).toList();

    Map<String, AmProductModel> productMap = {};

    // Chunking for whereIn limit of 10
    for (var i = 0; i < productIds.length; i += 10) {
      var end = (i + 10 < productIds.length) ? i + 10 : productIds.length;
      var chunk = productIds.sublist(i, end);

      if (chunk.isEmpty) continue;

      var productQuery = await _productsCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (var doc in productQuery.docs) {
        productMap[doc.id] = AmProductModel.fromQuerySnapshot(doc);
      }
    }

    // Reconstruct list in order
    return productIds
        .map((id) => productMap[id])
        .whereType<AmProductModel>()
        .where((p) => p.status == 'active' || p.status == null)
        .toList();
  }

  // Get user wishlist products stream
  Stream<List<AmProductModel>> getWishlistStream() {
    final user = _auth.currentUser;
    final gid = getStringAsync('guest_id');
    final uid = user?.uid ?? gid;
    if (uid.isEmpty) return Stream.value([]);

    return _wishlistCollection
        .where('user_id', isEqualTo: uid)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return [];

      // Sort in memory
      var docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final dataA = a.data() as Map<String, dynamic>;
        final dataB = b.data() as Map<String, dynamic>;
        Timestamp? t1 = dataA['created_at'] as Timestamp?;
        Timestamp? t2 = dataB['created_at'] as Timestamp?;
        if (t1 == null && t2 == null) return 0;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1); // Descending
      });

      List<String> productIds =
          docs.map((doc) => (doc['product_id'] ?? '').toString()).toList();
      final seen = <String>{};
      productIds = productIds.where((id) => seen.add(id)).toList();

      Map<String, AmProductModel> productMap = {};

      // Chunking for whereIn limit of 10
      for (var i = 0; i < productIds.length; i += 10) {
        var end = (i + 10 < productIds.length) ? i + 10 : productIds.length;
        var chunk = productIds.sublist(i, end);

        if (chunk.isEmpty) continue;

        var productQuery = await _productsCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (var doc in productQuery.docs) {
          productMap[doc.id] = AmProductModel.fromQuerySnapshot(doc);
        }
      }

      // Reconstruct list in order
      return productIds
          .map((id) => productMap[id])
          .whereType<AmProductModel>()
          .where((p) => p.status == 'active' || p.status == null)
          .toList();
    });
  }
}
