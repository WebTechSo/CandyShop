import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';
import 'package:american_sweets/data/services/cart_service.dart';
import 'package:american_sweets/screens/AmProductDetail.dart';
import 'package:american_sweets/main.dart';

class AmProductCard extends StatefulWidget {
  final AmProductModel product;

  const AmProductCard({super.key, required this.product});

  @override
  State<AmProductCard> createState() => _AmProductCardState();
}

class _AmProductCardState extends State<AmProductCard> {
  late List<String> _urlCandidates;
  int _attemptIndex = 0;
  String? _currentUrl;
  bool _refreshing = false;
  bool _inWishlist = false;
  bool _wishlistBusy = false;

  @override
  void initState() {
    super.initState();
    _syncImageCandidates();
    _initWishlist();
  }

  @override
  void didUpdateWidget(covariant AmProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.product.thumbnail != widget.product.thumbnail ||
        oldWidget.product.images != widget.product.images) {
      _syncImageCandidates();
    }
  }

  void _syncImageCandidates() {
    final p = widget.product;
    final candidates = <String>[];
    final thumb = p.thumbnail.validate().trim();
    if (thumb.startsWith('http')) candidates.add(thumb);
    if (p.images != null) {
      for (final img in p.images!) {
        final value = img.validate().trim();
        if (value.startsWith('http') && !candidates.contains(value)) {
          candidates.add(value);
        }
      }
    }
    _urlCandidates = candidates;
    _attemptIndex = 0;
    _currentUrl = _urlCandidates.isNotEmpty ? _urlCandidates.first : null;
  }

  Future<void> _initWishlist() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;
      final id = widget.product.id;
      if (id == null || id.isEmpty) return;
      final exists = await WishlistService().isInWishlist(id);
      if (!mounted) return;
      setState(() => _inWishlist = exists);
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    if (_wishlistBusy) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      toast("You need to login to add the wishlist");
      return;
    }
    final id = widget.product.id;
    if (id == null || id.isEmpty) return;
    setState(() => _wishlistBusy = true);
    try {
      if (_inWishlist) {
        await WishlistService().removeFromWishlist(id);
        if (!mounted) return;
        setState(() => _inWishlist = false);
        toast("Removed from wishlist");
      } else {
        await WishlistService().addToWishlist(id);
        if (!mounted) return;
        setState(() => _inWishlist = true);
        toast("Added to wishlist");
      }
    } finally {
      if (mounted) setState(() => _wishlistBusy = false);
    }
  }

  void _tryNextOrRefresh(String failingUrl) {
    if (_refreshing) return;
    final isFirebaseUrl =
        failingUrl.contains('firebasestorage.googleapis.com') ||
            failingUrl.contains('storage.googleapis.com');
    if (isFirebaseUrl) {
      _refreshing = true;
      FirebaseStorage.instance
          .refFromURL(failingUrl)
          .getDownloadURL()
          .then((fresh) {
        if (!mounted) return;
        if (fresh.isNotEmpty && fresh != failingUrl) {
          setState(() {
            _currentUrl = fresh;
          });
        } else {
          setState(() {
            if (_attemptIndex + 1 < _urlCandidates.length) {
              _attemptIndex += 1;
              _currentUrl = _urlCandidates[_attemptIndex];
            } else {
              _currentUrl = null;
            }
          });
        }
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          if (_attemptIndex + 1 < _urlCandidates.length) {
            _attemptIndex += 1;
            _currentUrl = _urlCandidates[_attemptIndex];
          } else {
            _currentUrl = null;
          }
        });
      }).whenComplete(() {
        _refreshing = false;
      });
      return;
    }
    setState(() {
      if (_attemptIndex + 1 < _urlCandidates.length) {
        _attemptIndex += 1;
        _currentUrl = _urlCandidates[_attemptIndex];
      } else {
        _currentUrl = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final double cardWidth = (MediaQuery.of(context).size.width - 48) / 2;
    final bool veryCompact = cardWidth < 220;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Builder(builder: (context) {
                      if (_currentUrl != null && _currentUrl!.isNotEmpty) {
                        return CachedNetworkImage(
                          imageUrl: _currentUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) =>
                              Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) _tryNextOrRefresh(url);
                            });
                            return Container(
                              color: sh_view_color,
                              alignment: Alignment.center,
                              child: Icon(Icons.broken_image,
                                  color: sh_textColorSecondary),
                            );
                          },
                        );
                      }
                      if (product.thumbnail != null &&
                          product.thumbnail!.isNotEmpty &&
                          !product.thumbnail!.startsWith('http')) {
                        final thumb = product.thumbnail!.trim();
                        final thumbPath = thumb.startsWith('images/')
                            ? thumb
                            : "images/sweets/img/products/$thumb";
                        return Image.asset(
                          thumbPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            if (product.images != null &&
                                product.images!.isNotEmpty &&
                                !product.images!.first!.startsWith('http')) {
                              final img = product.images!.first!.trim();
                              final imgPath = img.startsWith('images/')
                                  ? img
                                  : "images/sweets/img/products/$img";
                              return Image.asset(
                                imgPath,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              );
                            }
                            return Container(
                              color: sh_view_color,
                              child: Icon(Icons.shopping_bag,
                                  color: sh_textColorSecondary, size: 40),
                            );
                          },
                        );
                      }
                      if (product.images != null &&
                          product.images!.isNotEmpty &&
                          !product.images!.first!.startsWith('http')) {
                        final img = product.images!.first!.trim();
                        final imgPath = img.startsWith('images/')
                            ? img
                            : "images/sweets/img/products/$img";
                        return Image.asset(
                          imgPath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      }
                      return Container(
                        color: sh_view_color,
                        child: Icon(Icons.shopping_bag,
                            color: sh_textColorSecondary, size: 40),
                      );
                    }),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: appStore.isDarkModeOn
                            ? Colors.white.withValues(alpha: 0.08)
                            : context.cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _inWishlist ? Icons.favorite : Icons.favorite_border,
                        color: _inWishlist
                            ? Colors.redAccent
                            : (appStore.isDarkModeOn
                                ? white
                                : sh_textColorPrimary),
                        size: 16,
                      ),
                    ).onTap(_toggleWishlist),
                  ),
                  // Stock Action - Bottom Right
                  if ((product.availableQuantity ?? 0) <= 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appStore.isDarkModeOn
                              ? Colors.black87
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: primaryTextStyle(
                            color: appStore.isDarkModeOn
                                ? Colors.lightGreenAccent.shade400
                                : white,
                            size: 10,
                          ),
                        ),
                      ),
                    )
                  else
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: sh_colorPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: sh_colorPrimary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: white,
                          size: 16,
                        ),
                      ).onTap(() async {
                        if (product.id != null) {
                          try {
                            await CartService().addToCart(product);
                            toast("Added to cart");
                          } catch (e) {
                            toast(e.toString());
                          }
                        }
                      }),
                    ),
                ],
              ),
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, veryCompact ? 14 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name ?? 'Product Name',
                    style: boldTextStyle(size: veryCompact ? 13 : 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    product.description ?? 'Product description',
                    style: secondaryTextStyle(size: veryCompact ? 11 : 12),
                    maxLines: veryCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Builder(builder: (context) {
                    final bool includeVat =
                        getBoolAsync('include_vat', defaultValue: true);
                    final double base = product.price ?? 0.0;
                    final double rate = (product.vatRate ?? 0.0) / 100.0;
                    final double shown = includeVat ? base * (1 + rate) : base;
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        shown.toCurrencyFormat(),
                        maxLines: 1,
                        style: boldTextStyle(
                            size: veryCompact ? 14 : 16,
                            color: appStore.isDarkModeOn
                                ? sh_gradient_1st
                                : sh_colorPrimary),
                      ),
                    );
                  }),
                  SizedBox(height: veryCompact ? 2 : 4),
                ],
              ),
            ),
          ),
        ],
      ),
    ).onTap(() {
      AmProductDetail(product: widget.product).launch(context);
    });
  }
}
