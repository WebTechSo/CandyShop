import 'package:american_sweets/screens/AmNotificationScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AmNotificationBell extends StatelessWidget {
  final Color iconColor;
  final double iconSize;
  final Color badgeColor;
  final Color badgeTextColor;

  const AmNotificationBell({
    super.key,
    required this.iconColor,
    this.iconSize = 24,
    this.badgeColor = Colors.red,
    this.badgeTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    Widget badge(int count) {
      return Positioned(
        right: 6,
        top: 6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(10),
          ),
          constraints: const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: badgeTextColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: Icon(Icons.notifications, color: iconColor, size: iconSize),
          onPressed: () {
            ShNotificationScreen().launch(context);
          },
        ),
        if (user == null)
          badge(0)
        else
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Notifications')
                .where('userId', isEqualTo: user.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return badge(count);
            },
          ),
      ],
    );
  }
}
