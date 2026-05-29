import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection('Notifications');

  Future<void> createNotification({
    required String userId,
    required String title,
    required String description,
    String type = 'default',
    bool isRead = false,
    String action = '',
    String orderId = '',
    String productId = '',
    String imageUrl = '',
    String priority = 'normal',
    DateTime? expiresAt,
  }) async {
    final expiry = expiresAt ?? DateTime.now().add(const Duration(days: 30));

    await _collection.add({
      'userId': userId,
      'title': title,
      'description': description,
      'type': type,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiry),
      'imageUrl': imageUrl,
      'orderId': orderId,
      'priority': priority,
      'productId': productId,
      'action': action,
    });
  }
}
