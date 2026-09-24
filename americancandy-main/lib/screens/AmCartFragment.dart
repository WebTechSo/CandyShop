import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/screens/AmOrderSummaryScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';

import 'package:american_sweets/data/services/cart_service.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/data/repositories/authentication_repository.dart';

class CartProduct {
  AmProductModel product;
  int quantity;

  CartProduct({required this.product, required this.quantity});
}

class AmCartFragment extends StatefulWidget {
  static String tag = '/AmProfileFragment';

  @override
  AmCartFragmentState createState() => AmCartFragmentState();
}

class AmCartFragmentState extends State<AmCartFragment> {
  bool includeVat = getBoolAsync('include_vat', defaultValue: true);
  bool _navigating = false;
  final Map<String, bool> _isHovered = {}; // Track hover state for each item

  @override
  void initState() {
    super.initState();
    // No fetch needed, StreamBuilder handles it
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity < 1) return;
    CartService().updateQuantity(productId, newQuantity);
  }

  void removeItem(String productId) {
    CartService().removeFromCart(productId);
    toast("Item removed from cart");
    
    // Vibrate on remove - try multiple methods for better compatibility
    HapticFeedback.vibrate();
    HapticFeedback.heavyImpact();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    // Calculate the height of bottom navigation bar (typical height is 56-70)
    double bottomNavBarHeight = kBottomNavigationBarHeight;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: CartService().getCartStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          var docs = snapshot.data?.docs.toList() ?? [];
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

          final cartList = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Assuming product data is stored in cart doc or referenced.
            // Based on CartService, basic product info is stored.
            // Ideally we should fetch full product details, but for now using stored data.
            final size = (data['size'] ?? '').toString();
            final flavor = (data['flavor'] ?? '').toString();
            final packaging = (data['packaging'] ?? '').toString();
            final country = (data['country'] ?? '').toString();
            return CartProduct(
              product: AmProductModel(
                id: data['product_id'],
                name: data['name'],
                price: (data['price'] is int)
                    ? (data['price'] as int).toDouble()
                    : data['price'],
                thumbnail: data['image'],
                sku: data['sku'],
                variants: AmVariant(
                  size: size.isNotEmpty ? size : null,
                  flavor: flavor.isNotEmpty ? flavor : null,
                  packaging: packaging.isNotEmpty ? packaging : null,
                  country: country.isNotEmpty ? country : null,
                ),
                vatRate: (data['vat_rate'] is num)
                    ? (data['vat_rate'] as num).toDouble()
                    : double.tryParse(data['vat_rate']?.toString() ?? '') ??
                        0.0,
              ),
              quantity: data['quantity'] ?? 1,
            );
          }).toList();

          double subtotal = 0.0;
          double vatAmount = 0.0;
          for (var cartProduct in cartList) {
            double price = cartProduct.product.price ?? 0.0;
            subtotal += price * cartProduct.quantity;
            double rate = (cartProduct.product.vatRate ?? 0.0) / 100.0;
            vatAmount += price * cartProduct.quantity * rate;
          }
          double shipping = 0.0;
          double total = subtotal + shipping + (includeVat ? vatAmount : 0.0);

          if (cartList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: gray),
                  16.height,
                  Text("Items (0)", style: boldTextStyle(size: 20)),
                ],
              ),
            );
          }

          var cartItemsList = ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: cartList.length,
            shrinkWrap: true,
            padding: EdgeInsets.only(bottom: spacing_standard_new),
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final cartProduct = cartList[index];
              final product = cartProduct.product;

              return MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _isHovered[product.id ?? ''] = true;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _isHovered[product.id ?? ''] = false;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    left: spacing_standard_new,
                    right: spacing_standard_new,
                    top: spacing_standard_new,
                  ),
                  decoration: BoxDecoration(
                    color: _isHovered[product.id ?? ''] == true 
                        ? context.cardColor.withValues(alpha: 0.9)
                        : context.cardColor,
                    border: Border.all(
                      color: _isHovered[product.id ?? ''] == true 
                          ? sh_colorPrimary.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: width * 0.25,
                        height: width * 0.25,
                        margin: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12), // rectangle with rounded corners
                          border: Border.all(color: sh_view_color, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12), // must match the Container's radius
                          child: (product.thumbnail != null && product.thumbnail!.isNotEmpty)
                              ? (product.thumbnail!.startsWith('http')
                              ? Image.network(
                            product.thumbnail!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: sh_view_color,
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported),
                            ),
                          )
                              : Image.asset(
                            "images/sweets/img/products" + product.thumbnail!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: sh_view_color,
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported),
                            ),
                          ))
                              : Container(
                            color: sh_view_color,
                            alignment: Alignment.center,
                            child: Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                8.height,
                                Text(product.name.toString(),
                                        style: boldTextStyle())
                                    .paddingOnly(left: 8),
                                8.height,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Size: ${product.variants?.size ?? "N/A"} | Flavor: ${product.variants?.flavor ?? "N/A"}",
                                      style: boldTextStyle(size: 14),
                                    ),
                                    8.height,
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: sh_view_color, width: 1),
                                        borderRadius: BorderRadius.circular(8),
                                        color: _isHovered[product.id ?? ''] == true 
                                            ? sh_colorPrimary.withValues(alpha: 0.1)
                                            : Colors.transparent,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.remove,
                                                size: 16,
                                                color: appStore.isDarkModeOn
                                                    ? white
                                                    : sh_textColorPrimary),
                                            onPressed: () {
                                              updateQuantity(product.id!,
                                                  cartProduct.quantity - 1);
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(
                                                minWidth: 32, minHeight: 32),
                                          ),
                                          Text("${cartProduct.quantity}",
                                              style: primaryTextStyle()),
                                          IconButton(
                                            icon: Icon(Icons.add,
                                                size: 16,
                                                color: appStore.isDarkModeOn
                                                    ? white
                                                    : sh_textColorPrimary),
                                            onPressed: () {
                                              updateQuantity(product.id!,
                                                  cartProduct.quantity + 1);
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(
                                                minWidth: 32, minHeight: 32),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ).paddingOnly(left: 8.0, top: spacing_control),
                                12.height,
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 16),
                                    child: Text(
                                      _calculateProductPrice(
                                          product, cartProduct.quantity),
                                      style:
                                          boldTextStyle(
                                              color: appStore.isDarkModeOn
                                                  ? sh_gradient_1st
                                                  : sh_colorPrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 1),
                            SizedBox(
                              height: 40,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (AuthenticationRepository
                                          .instance.currentUser !=
                                      null) ...[
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.bookmark_border,
                                            color: appStore.isDarkModeOn
                                                ? gray
                                                : sh_textColorPrimary,
                                            size: 16,
                                          ),
                                          4.width,
                                          Flexible(
                                            child: Text(
                                              "Save for later",
                                              style: secondaryTextStyle(),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ).onTap(() async {
                                        if (product.id != null) {
                                          try {
                                            await WishlistService()
                                                .addToWishlist(product.id!);
                                            await CartService()
                                                .removeFromCart(product.id!);
                                            toast("Item saved for later");
                                            // Vibrate - try multiple methods for better compatibility
                                            HapticFeedback.vibrate();
                                            HapticFeedback.heavyImpact();
                                          } catch (e) {
                                            toast("Failed to save item");
                                          }
                                        }
                                      }),
                                    ),
                                    Container(
                                        width: 1,
                                        color: sh_view_color,
                                        height: 35),
                                  ],
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: appStore.isDarkModeOn
                                              ? gray
                                              : sh_textColorPrimary,
                                          size: 16,
                                        ),
                                        4.width,
                                        Text(
                                          sh_lbl_remove,
                                          style: secondaryTextStyle(),
                                        ),
                                      ],
                                    ).onTap(() {
                                      if (product.id != null) {
                                        removeItem(product.id!);
                                      }
                                    }),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );

          var summarySection = Container(
            margin: EdgeInsets.fromLTRB(
                spacing_standard_new,
                spacing_standard_new,
                spacing_standard_new,
                spacing_standard_new),
            decoration: BoxDecoration(
              color: context.cardColor,
              border: Border.all(color: sh_view_color, width: 1.0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(spacing_standard_new,
                      spacing_middle, spacing_standard_new, spacing_middle),
                  child: Text("Summary", style: boldTextStyle()),
                ),
                Divider(height: 1, color: sh_view_color),
                Padding(
                  padding: EdgeInsets.fromLTRB(spacing_standard_new,
                      spacing_middle, spacing_standard_new, spacing_middle),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Include VAT", style: primaryTextStyle()),
                          Switch(
                            value: includeVat,
                            thumbColor:
                                WidgetStateProperty.all(sh_colorPrimary),
                            onChanged: (value) {
                              setState(() {
                                includeVat = value;
                                setValue('include_vat', includeVat);
                              });
                            },
                          ),
                        ],
                      ),
                      12.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Subtotal", style: primaryTextStyle()),
                          Text(subtotal.toStringAsFixed(2).toCurrencyFormat(),
                              style: primaryTextStyle()),
                        ],
                      ),
                      12.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Shipping", style: primaryTextStyle()),
                          Text(shipping.toStringAsFixed(2).toCurrencyFormat(),
                              style: primaryTextStyle()),
                        ],
                      ),
                      12.height,
                      if (includeVat && vatAmount > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("VAT", style: primaryTextStyle()),
                            Text(
                                vatAmount.toStringAsFixed(2).toCurrencyFormat(),
                                style: primaryTextStyle()),
                          ],
                        ),
                      12.height,
                      Divider(height: 1, color: sh_view_color),
                      12.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total", style: boldTextStyle()),
                          Text(total.toStringAsFixed(2).toCurrencyFormat(),
                              style: boldTextStyle(
                                  color: appStore.isDarkModeOn
                                      ? sh_gradient_1st
                                      : sh_colorPrimary)),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          );

          // Calculate responsive bottom padding
          double responsiveBottomPadding = bottomNavBarHeight + 60; // Adjusted space for button

          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(
                    bottom: responsiveBottomPadding), // keep content above button
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Items heading with count
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          spacing_standard_new,
                          spacing_standard_new,
                          spacing_standard_new,
                          spacing_control),
                      child: Row(
                        children: [
                          Text("Items", style: boldTextStyle()),
                          8.width,
                          Text("(${cartList.length})", style: secondaryTextStyle()),
                        ],
                      ),
                    ),
                    cartItemsList,
                    summarySection,
                    SizedBox(height: 8),
                  ],
                ),
              ),
              // Sticky Place Order Button
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StreamBuilder<QuerySnapshot>(
                  stream: CartService().getCartStream(),
                  builder: (context, snapshot) {
                    final hasItems = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
                    return Container(
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.only(
                        left: spacing_standard_new,
                        right: spacing_standard_new,
                        top: 12,
                        bottom: bottomNavBarHeight + 8,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: width < 360 ? 45 : 50, // Responsive height for smaller screens
                        child: ElevatedButton(
                          onPressed: (hasItems && !_navigating)
                              ? () {
                                  if (!mounted) return;
                                  setState(() => _navigating = true);
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) async {
                                    if (!mounted) return;
                                    await Navigator.of(context, rootNavigator: true)
                                        .push(
                                      MaterialPageRoute(
                                          builder: (_) => AmOrderSummaryScreen()),
                                    );
                                    if (mounted) setState(() => _navigating = false);
                                  });
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: sh_colorPrimary,
                            disabledBackgroundColor:
                                sh_colorPrimary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(width < 360 ? 20 : 25), // Responsive radius
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            "Place Order",
                            style: boldTextStyle(
                              color: sh_white, 
                              size: width < 360 ? 14 : 16, // Responsive font size
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _calculateProductPrice(AmProductModel product, int quantity) {
    double price = double.tryParse(product.price.toString()) ?? 0.0;

    double totalPrice = price * quantity;
    return totalPrice.toStringAsFixed(2).toCurrencyFormat();
  }
}
