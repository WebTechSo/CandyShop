import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/screens/AmOrderDetailScreen.dart';
import 'package:american_sweets/models/AmOrder.dart';

class ShNotificationScreen extends StatefulWidget {
  static String tag = '/ShNotificationScreen';

  @override
  _ShNotificationScreenState createState() => _ShNotificationScreenState();
}

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String type;
  final bool isRead;
  final String? orderId;
  final String? action;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.orderId,
    this.action,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'default',
      isRead: data['isRead'] ?? false,
      orderId: data['orderId']?.toString(),
      action: data['action']?.toString(),
    );
  }

  IconData get icon {
    switch (type) {
      case 'welcome':
        return Icons.celebration;
      case 'order':
        return Icons.shopping_bag;
      case 'shipped':
        return Icons.local_shipping;
      case 'security':
        return Icons.security;
      case 'offer':
        return Icons.local_offer;
      case 'payment':
        return Icons.payment;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return "${(diff.inDays / 365).floor()} years ago";
    if (diff.inDays > 30) return "${(diff.inDays / 30).floor()} months ago";
    if (diff.inDays > 0) return "${diff.inDays} days ago";
    if (diff.inHours > 0) return "${diff.inHours} hours ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes} minutes ago";
    return "Just now";
  }
}

class _ShNotificationScreenState extends State<ShNotificationScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Notifications", style: boldTextStyle(size: 22)),
        ),
        body: Center(child: Text("Please sign in to view notifications")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        title: Text("Notifications", style: boldTextStyle(size: 22)),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
            onPressed: () {
              _showClearAllDialog();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('userId', isEqualTo: currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? []).toList();
          docs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final t1 = dataA['createdAt'] as Timestamp?;
            final t2 = dataB['createdAt'] as Timestamp?;
            if (t1 == null && t2 == null) return 0;
            if (t1 == null) return 1;
            if (t2 == null) return -1;
            return t2.compareTo(t1);
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off,
                      size: 80, color: sh_textColorSecondary),
                  SizedBox(height: 16),
                  Text("No Notifications", style: boldTextStyle(size: 20)),
                  SizedBox(height: 8),
                  Text("You're all caught up!", style: secondaryTextStyle()),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final notification = NotificationItem.fromFirestore(docs[index]);
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: sh_colorPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notification.icon, color: sh_colorPrimary),
                  ),
                  title: Text(notification.title, style: boldTextStyle()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(notification.description, style: primaryTextStyle()),
                      SizedBox(height: 4),
                      Text(notification.timeAgo,
                          style: secondaryTextStyle(size: 12)),
                    ],
                  ),
                  trailing: !notification.isRead
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  onTap: () {
                    _handleNotificationTap(notification);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(NotificationItem notification) async {
    try {
      if (!notification.isRead) {
        FirebaseFirestore.instance
            .collection('Notifications')
            .doc(notification.id)
            .update({'isRead': true});
      }
      if ((notification.action == 'order_detail') ||
          (notification.type == 'order')) {
        AmOrder? order;
        // Prefer direct orderId
        if (notification.orderId != null &&
            notification.orderId!.trim().isNotEmpty) {
          final doc = await FirebaseFirestore.instance
              .collection('Orders')
              .doc(notification.orderId!.trim())
              .get();
          if (doc.exists) {
            order = AmOrder.fromSnapshot(doc);
          }
        }
        // Fallback: try to extract order code from description and query
        if (order == null) {
          final codeMatch =
              RegExp(r'(\d{8}-\d{8})').firstMatch(notification.description);
          final code = codeMatch?.group(1);
          if (code != null) {
            final qs = await FirebaseFirestore.instance
                .collection('Orders')
                .where('order_code', isEqualTo: code)
                .limit(1)
                .get();
            if (qs.docs.isNotEmpty) {
              order = AmOrder.fromSnapshot(qs.docs.first);
            }
          }
        }
        if (order != null) {
          AmOrderDetailScreen(order: order).launch(context);
          return;
        }
      }
    } catch (e) {
      print('Notification open error: $e');
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Clear All Notifications", style: boldTextStyle()),
          content: Text("Are you sure you want to clear all notifications?",
              style: primaryTextStyle()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("CANCEL",
                  style: primaryTextStyle(color: sh_colorPrimary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  final collection =
                      FirebaseFirestore.instance.collection('Notifications');
                  final snapshot = await collection
                      .where('userId', isEqualTo: currentUser!.uid)
                      .get();

                  if (snapshot.docs.isEmpty) {
                    toasty(context, "No notifications to clear");
                    return;
                  }

                  // Firestore batch limit is 500
                  int batchSize = 500;
                  for (int i = 0; i < snapshot.docs.length; i += batchSize) {
                    final batch = FirebaseFirestore.instance.batch();
                    var end = (i + batchSize < snapshot.docs.length)
                        ? i + batchSize
                        : snapshot.docs.length;
                    var chunk = snapshot.docs.sublist(i, end);

                    for (var doc in chunk) {
                      batch.delete(doc.reference);
                    }
                    await batch.commit();
                  }

                  toasty(context, "All notifications cleared");
                } catch (e) {
                  print("Error clearing notifications: $e");
                  toasty(context, "Failed to clear notifications");
                }
              },
              child: Text("CLEAR", style: primaryTextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
