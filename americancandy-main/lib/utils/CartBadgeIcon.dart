import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/data/services/cart_service.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CartBadgeIcon extends StatelessWidget {
  final double size;
  final Color? color;
  const CartBadgeIcon({Key? key, this.size = 24, this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: CartService().getCartStream(),
      builder: (context, snapshot) {
        int total = 0;
        if (snapshot.hasData) {
          for (final d in snapshot.data!.docs) {
            final m = d.data() as Map<String, dynamic>;
            total += int.tryParse((m['quantity'] ?? 1).toString()) ?? 1;
          }
        }
        final iconColor =
            color ?? IconTheme.of(context).color ?? sh_textColorPrimary;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            SvgPicture.asset(
              sh_ic_cart_2,
              width: size,
              height: size,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
            if (total > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    total > 9 ? '9+' : '$total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
