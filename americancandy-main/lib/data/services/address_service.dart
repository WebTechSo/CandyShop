import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/models/AmAddress.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:math';

class AddressService {
  final CollectionReference _addressCollection =
      FirebaseFirestore.instance.collection('Addresses');
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // Add new address
  Future<void> addAddress(AmAddressModel address) async {
    final uid = await _ensureUserId();

    int newId = DateTime.now().millisecondsSinceEpoch;
    address.id = newId;
    address.user_id = uid;

    await _addressCollection.doc(newId.toString()).set(address.toJson());
  }

  // Get user addresses
  Stream<List<AmAddressModel>> getUserAddresses() {
    final user = _auth.currentUser;
    String id;
    if (user != null) {
      id = user.uid;
    } else {
      var gid = getStringAsync('guest_id');
      if (gid.isEmpty) {
        gid =
            'guest_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
        setValue('guest_id', gid);
      }
      id = gid;
    }
    return _addressCollection
        .where('user_id', isEqualTo: id)
        .snapshots()
        .map((snapshot) {
      List<AmAddressModel> list = snapshot.docs.map((doc) {
        return AmAddressModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
      list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      return list;
    });
  }

  // Delete address
  Future<void> deleteAddress(int id) async {
    await _addressCollection.doc(id.toString()).delete();
  }

  // Update address
  Future<void> updateAddress(AmAddressModel address) async {
    if (address.id != null) {
      await _addressCollection
          .doc(address.id.toString())
          .update(address.toJson());
    }
  }

  Future<void> migrateGuestAddresses(String oldUserId, String newUserId) async {
    if (oldUserId == newUserId) return;
    final query =
        await _addressCollection.where('user_id', isEqualTo: oldUserId).get();
    for (var doc in query.docs) {
      await doc.reference.update({'user_id': newUserId});
    }
  }

  // Set default address
  Future<void> setDefaultAddress(int addressId) async {
    final uid = await _ensureUserId();
    final batch = FirebaseFirestore.instance.batch();

    // Get all addresses for this user
    final query =
        await _addressCollection.where('user_id', isEqualTo: uid).get();

    for (var doc in query.docs) {
      int docId = int.tryParse(doc.id) ?? 0;
      if (docId == addressId) {
        batch.update(doc.reference, {'default_address': true});
      } else {
        batch.update(doc.reference, {'default_address': false});
      }
    }

    await batch.commit();
  }
}
