import 'dart:async';
import 'dart:convert';
import 'package:american_sweets/screens/AmOrderSummaryScreen.dart';
import 'package:american_sweets/screens/AmViewAllProducts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/models/AmReview.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmProductCard.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/utils/rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:american_sweets/data/services/cart_service.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/painting.dart';

// ignore: must_be_immutable
class AmProductDetail extends StatefulWidget {
  static String tag = '/AmProductDetail';
  final AmProductModel product;

  AmProductDetail({required this.product});

  @override
  AmProductDetailState createState() => AmProductDetailState();
}

class AmProductDetailState extends State<AmProductDetail> {
  var position = 0;
  bool isExpanded = false;
  var selectedColor = -1;
  var selectedSize = -1;
  double fiveStar = 0;
  double fourStar = 0;
  double threeStar = 0;
  double twoStar = 0;
  double oneStar = 0;
  List<AmReview> list = [];
  bool autoValidate = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController controller = TextEditingController();
  double avgRating = 0.0;
  var currencySymbol = '£';

  // Custom State Variables
  int productQuantity = 1;
  // String selectedSizeOption = 'Size'; // Removed
  // String selectedFlavorOption = 'Flavor'; // Removed
  String selectedPackaging = 'Pouch';

  // Mock data for customization - Removed as we use read-only data
  // List<String> sizeOptions = ['Size', 'Small', 'Medium', 'Large'];
  // List<String> flavorOptions = ['Flavor', 'Cherry', 'Lemon', 'Apple'];
  List<String> packagingOptions = ['Pouch', 'Bag', 'Wrapping'];

  // Adjusted mock data for Most Popular section to match the look
  List<AmProductModel> popularProducts = [];
  String categoryName = "";
  bool _inWishlist = false;
  late AmProductModel _currentProduct;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _productSub;

  // String mockBrandName = "Jelly Belly";
  // String mockCountryName = "EU";
  // String mockIngredients = ... // Removed

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _clearAllImageCaches();
    _evictProductImageCaches(_currentProduct);
    _listenToProduct();
    fetchData();
    fetchPopularProducts();
    _initWishlist();
  }

  @override
  void dispose() {
    _productSub?.cancel();
    controller.dispose();
    super.dispose();
  }

  List<String> _imageCandidates(AmProductModel product) {
    final urls = <String>[];
    final thumb = product.thumbnail.validate().trim();
    if (thumb.isNotEmpty) urls.add(thumb);
    if (product.images != null) {
      for (final image in product.images!) {
        final value = image.validate().trim();
        if (value.isNotEmpty && !urls.contains(value)) urls.add(value);
      }
    }
    return urls;
  }

  String _resolvePrimaryImage(AmProductModel product) {
    final urls = _imageCandidates(product);
    return urls.isNotEmpty ? urls.first : '';
  }

  String _assetImagePath(String src) {
    final clean = src.trim();
    if (clean.isEmpty) return "images/sweets/img/products/candy-1.jpg";
    if (clean.startsWith('images/')) return clean;
    return "images/sweets/img/products/$clean";
  }

  void _clearAllImageCaches() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  Future<void> _evictProductImageCaches(AmProductModel product) async {
    for (final url in _imageCandidates(product)) {
      if (url.startsWith('http')) {
        try {
          await CachedNetworkImage.evictFromCache(url);
        } catch (_) {}
      }
    }
  }

  void _listenToProduct() {
    final id = widget.product.id;
    if (id == null || id.isEmpty) return;
    _productSub = FirebaseFirestore.instance
        .collection('Products')
        .doc(id)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final next = AmProductModel.fromSnapshot(doc);
      await _evictProductImageCaches(next);
      _clearAllImageCaches();
      if (!mounted) return;
      setState(() {
        _currentProduct = next;
      });
      fetchCategoryName();
    });
  }

  fetchPopularProducts() async {
    try {
      final productsSnap =
          await FirebaseFirestore.instance.collection('Products').get();
      final all = productsSnap.docs
          .map((doc) => AmProductModel.fromQuerySnapshot(doc))
          .where((p) => p.status == null || p.status == 'active')
          .toList();

      final Map<String, AmProductModel> byId = {
        for (final p in all)
          if (p.id != null && p.id!.isNotEmpty) p.id!: p
      };

      final Map<String, int> qtyByProductId = {};
      try {
        final itemsSnap = await FirebaseFirestore.instance
            .collection('order_items')
            .orderBy('order_date', descending: true)
            .limit(500)
            .get();
        for (final d in itemsSnap.docs) {
          final data = d.data();
          final pid = data['product_id']?.toString();
          if (pid == null || pid.isEmpty) continue;
          final q = data['quantity'];
          final int qty = (q is int)
              ? q
              : (q is num)
              ? q.toInt()
              : int.tryParse(q.toString()) ?? 1;
          qtyByProductId[pid] = (qtyByProductId[pid] ?? 0) + qty;
        }
      } catch (_) {}

      final String? currentId = widget.product.id;
      final picked = <AmProductModel>[];
      final pickedIds = <String>{};

      if (qtyByProductId.isNotEmpty) {
        final entries = qtyByProductId.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        for (final e in entries) {
          if (picked.length >= 2) break;
          final pid = e.key;
          if (pid == currentId) continue;
          final p = byId[pid];
          if (p == null) continue;
          picked.add(p);
          pickedIds.add(pid);
        }
      }

      int? catId = _currentProduct.category;
      String catNameNorm = (categoryName.isNotEmpty
          ? categoryName
          : _currentProduct.categoryName)
          ?.toLowerCase()
          .trim() ??
          '';
      if (picked.length < 2) {
        final sameCategory = all.where((p) {
          if (p.id == null || p.id!.isEmpty) return false;
          if (p.id == currentId) return false;
          if (pickedIds.contains(p.id)) return false;
          final idMatch = catId != null && p.category == catId;
          final nameMatch = catId == null &&
              (p.categoryName ?? '').toLowerCase().trim() == catNameNorm;
          return idMatch || nameMatch;
        }).toList()
          ..sort((a, b) {
            final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bt.compareTo(at);
          });

        final needed = 2 - picked.length;
        picked.addAll(sameCategory.take(needed));
        pickedIds.addAll(sameCategory.take(needed).map((e) => e.id!).toList());
      }

      if (picked.length < 2) {
        final remaining = all
            .where((p) =>
        p.id != null &&
            p.id!.isNotEmpty &&
            p.id != currentId &&
            !pickedIds.contains(p.id))
            .toList()
          ..shuffle();
        picked.addAll(remaining.take(2 - picked.length));
      }

      if (!mounted) return;
      setState(() {
        popularProducts = picked.take(2).toList();
      });
    } catch (e) {
      print("Error loading popular products: $e");
    }
  }

  Future<void> _initWishlist() async {
    try {
      final id = widget.product.id;
      if (id == null || id.isEmpty) return;
      final exists = await WishlistService().isInWishlist(id);
      if (mounted) setState(() => _inWishlist = exists);
    } catch (_) {}
  }

  void _toggleWishlist() async {
    final id = widget.product.id;
    if (id == null || id.isEmpty) return;
    try {
      if (_inWishlist) {
        await WishlistService().removeFromWishlist(id);
        if (mounted) setState(() => _inWishlist = false);
        toast('Removed from wishlist');
      } else {
        await WishlistService().addToWishlist(id);
        if (mounted) setState(() => _inWishlist = true);
        toast('Added to wishlist');
      }
    } catch (e) {
      toast(e.toString());
    }
  }

  void _shareProduct() {
    final p = _currentProduct;
    final name = p.name ?? 'Sweet Stop';
    final price = FirebaseAuth.instance.currentUser != null && p.price != null
        ? '£${p.price!.toStringAsFixed(2)}'
        : '';
    final url = _resolvePrimaryImage(p);
    final text = [name, price, url]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' • ');
    Share.share(text);
  }

  fetchCategoryName() async {
    if (_currentProduct.category != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('Categories')
            .doc(_currentProduct.category.toString())
            .get();
        if (doc.exists) {
          if (!mounted) return;
          setState(() {
            categoryName = doc['name'];
          });
        }
      } catch (e) {
        print("Error loading category name: $e");
      }
    }
  }

  fetchData() async {
    await fetchCategoryName();
    var reviewsList = await loadProducts();
    setState(() {
      list.clear();
      list.addAll(reviewsList);
    });
    setRating();
  }

  Future<List<AmReview>> loadProducts() async {
    try {
      String jsonString =
      await loadContentAsset('assets/sweet_data/reviews.json');
      final jsonResponse = json.decode(jsonString);
      return (jsonResponse as List).map((i) => AmReview.fromJson(i)).toList();
    } catch (e) {
      return [];
    }
  }

  setRating() {
    fiveStar = 0;
    fourStar = 0;
    threeStar = 0;
    twoStar = 0;
    oneStar = 0;
    double totalRatingSum = 0;

    if (list.isEmpty) {
      setState(() {
        avgRating = 0.0;
      });
      return;
    }

    list.forEach((review) {
      int rating = review.rating ?? 0;
      totalRatingSum += rating;

      switch (rating) {
        case 5:
          fiveStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 1:
          oneStar++;
          break;
      }
    });

    int reviewCount = list.length;
    if (reviewCount > 0) {
      fiveStar = (fiveStar * 100) / reviewCount;
      fourStar = (fourStar * 100) / reviewCount;
      threeStar = (threeStar * 100) / reviewCount;
      twoStar = (twoStar * 100) / reviewCount;
      oneStar = (oneStar * 100) / reviewCount;

      setState(() {
        avgRating = totalRatingSum / reviewCount;
      });
    }
  }

  void _updateQuantity(int delta) {
    final max = _currentProduct.availableQuantity ?? 0;
    if (max <= 0) return;
    final next = productQuantity + delta;
    final clamped = next < 1 ? 1 : (next > max ? max : next);
    if (clamped == productQuantity) return;
    setState(() {
      productQuantity = clamped;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    final product = _currentProduct;
    final bool inStock = (product.availableQuantity ?? 0) > 0;

    // Safe-area inset for devices with a 3-button nav bar or gesture indicator.
    final double bottomSafeInset = MediaQuery.of(context).padding.bottom;
    final double bottomStickyBarContentHeight = 70.0;
    // Total on-screen height of the sticky bar, including the safe-area inset.
    final double bottomStickyBarHeight =
        bottomStickyBarContentHeight + bottomSafeInset;
    // Extra breathing room so the last scrollable item isn't flush against the bar.
    final double bottomPaddingForContent = bottomStickyBarHeight + 16.0;

    // --- Safe Image Handling ---
    final displayImageSrc = _resolvePrimaryImage(product);
    bool isNetworkImage = displayImageSrc.startsWith('http');
    final displayImagePath =
    isNetworkImage ? displayImageSrc : _assetImagePath(displayImageSrc);

    // --- Custom Header Content (Image) ---
    var imageSection = SizedBox(
      width: width,
      height: width,
      child: Stack(
        children: [
          Positioned.fill(
            child: isNetworkImage
                ? CachedNetworkImage(
              imageUrl: displayImagePath,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  color: sh_view_color,
                  child: Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(
                  color: sh_view_color,
                  child: Center(
                      child: Icon(Icons.image_not_supported, size: 80))),
            )
                : Image.asset(
              displayImagePath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  color: sh_view_color,
                  child: Center(
                      child: Icon(Icons.image_not_supported, size: 80))),
            ),
          ),
        ],
      ),
    );

    // --- Custom Header (Image & Share) ---
    var customHeader = Stack(
      children: [
        imageSection,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 12, 72, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Text(
              product.name.validate(),
              style: boldTextStyle(size: 18, color: white),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Positioned(
          top: context.statusBarHeight + 8,
          right: 8,
          child: Container(
            padding: EdgeInsets.all(spacing_control),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: white.withOpacity(0.7),
            ),
            child: Icon(Icons.share, color: sh_colorPrimary, size: 24),
          ).onTap(_shareProduct),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _toggleWishlist,
            child: Container(
              padding: EdgeInsets.all(spacing_control),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: white.withOpacity(0.9),
              ),
              child: Icon(
                _inWishlist ? Icons.favorite : Icons.favorite_border,
                color: _inWishlist ? Colors.redAccent : sh_colorPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );

    // --- Price and key details section (moved out of header to avoid overflow) ---
    var priceSection = FirebaseAuth.instance.currentUser != null
        ? Container(
            padding: EdgeInsets.all(spacing_standard_new),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product.price.validate().toCurrencyFormat()}',
                      style: boldTextStyle(size: 24),
                    ),
                    if (product.sku.validate().isNotEmpty)
                      Text(
                        'SKU: ${product.sku.validate()}',
                        style: secondaryTextStyle(size: 14),
                      ),
                  ],
                ),
                if (product.unitPrice != null && product.unitPrice! > 0)
                  Text(
                    'Unit price: ${product.unitPrice!.toCurrencyFormat()}',
                    style: secondaryTextStyle(size: 14),
                  ).paddingTop(4),
                if (product.availableQuantity != null)
                  Text(
                    (product.availableQuantity ?? 0) > 0
                        ? 'Available quantity: ${product.availableQuantity}'
                        : 'Out of Stock',
                    style: secondaryTextStyle(
                        size: 14,
                        color: (product.availableQuantity ?? 0) > 0
                            ? null
                            : (appStore.isDarkModeOn
                            ? Colors.lightGreenAccent.shade400
                            : Colors.redAccent)),
                  ).paddingTop(2),
                if (product.priceDescription.validate().isNotEmpty)
                  Text(
                    product.priceDescription.validate(),
                    style: secondaryTextStyle(size: 14),
                  ).paddingTop(4),
                4.height,
              ],
            ),
          )
        : Container(
            padding: EdgeInsets.all(spacing_standard_new),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.sku.validate().isNotEmpty)
                  Text(
                    'SKU: ${product.sku.validate()}',
                    style: secondaryTextStyle(size: 14),
                  ),
                if (product.availableQuantity != null)
                  Text(
                    (product.availableQuantity ?? 0) > 0
                        ? 'Available quantity: ${product.availableQuantity}'
                        : 'Out of Stock',
                    style: secondaryTextStyle(
                        size: 14,
                        color: (product.availableQuantity ?? 0) > 0
                            ? null
                            : (appStore.isDarkModeOn
                            ? Colors.lightGreenAccent.shade400
                            : Colors.redAccent)),
                  ).paddingTop(2),
                4.height,
              ],
            ),
          );

    // --- Product Description Section ---
    var descriptionSection = Padding(
      padding: EdgeInsets.only(
          left: spacing_standard_new,
          right: spacing_standard_new,
          bottom: spacing_standard_new),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Product Description", style: boldTextStyle(size: 18))
              .paddingBottom(spacing_control),
          Text(
            product.description.validate(),
            maxLines: isExpanded ? null : 3,
            style: secondaryTextStyle(),
          ),
          InkWell(
            child: Padding(
              padding: EdgeInsets.only(top: spacing_control),
              child: Text(isExpanded ? "Read Less" : "Read More",
                  style: primaryTextStyle(
                      color: appStore.isDarkModeOn ? white : sh_colorPrimary)),
            ),
            onTap: () {
              isExpanded = !isExpanded;
              setState(() {});
            },
          ),
        ],
      ),
    );

    // --- Ingredients Section ---
    var ingredientsSection = Padding(
      padding: EdgeInsets.only(
          left: spacing_standard_new,
          right: spacing_standard_new,
          top: spacing_standard_new,
          bottom: spacing_standard_new),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ingredients", style: boldTextStyle(size: 18))
                    .paddingBottom(spacing_control),
                Text(
                    product.ingredients
                        .validate(value: "Ingredients not available"),
                    style: secondaryTextStyle(size: 14)),
              ],
            ),
          ),
          if (categoryName.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sh_green,
                borderRadius: radius(4),
              ),
              child: Text(categoryName,
                  style: boldTextStyle(size: 14, color: white)),
            )
        ],
      ),
    );

    // --- Category and Brand Section ---
    var categoryAndBrandSection = Padding(
      padding: EdgeInsets.symmetric(
          horizontal: spacing_standard_new, vertical: spacing_control),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Category (Left)
          if (product.category != null)
            Row(
              children: [
                Text("Category: ", style: boldTextStyle(size: 16)),
                4.width,
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Categories')
                      .where('id', isEqualTo: product.category)
                      .limit(1)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.docs.isNotEmpty) {
                      var data = snapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
                      return Text(data['name'] ?? product.category.toString(),
                          style: primaryTextStyle(
                              size: 16,
                              color: appStore.isDarkModeOn
                                  ? white
                                  : sh_colorPrimary));
                    }
                    return Text(product.category.toString(),
                        style: primaryTextStyle(
                            size: 16,
                            color: appStore.isDarkModeOn
                                ? white
                                : sh_colorPrimary));
                  },
                ),
              ],
            ),

          // Brand (Right)
          if (product.brand != null && product.brand!.isNotEmpty)
            Row(
              children: [
                Text("Brand: ", style: boldTextStyle(size: 16)),
                4.width,
                FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Brands')
                      .where('id',
                      isEqualTo: int.tryParse(product.brand.validate()))
                      .limit(1)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data != null &&
                        snapshot.data!.docs.isNotEmpty) {
                      var data = snapshot.data!.docs.first.data()
                      as Map<String, dynamic>;
                      return Text(data['name'] ?? product.brand!,
                          style: primaryTextStyle(
                              size: 16,
                              color: appStore.isDarkModeOn
                                  ? white
                                  : sh_colorPrimary));
                    }
                    return Text(product.brand!,
                        style: primaryTextStyle(
                            size: 16,
                            color: appStore.isDarkModeOn
                                ? white
                                : sh_colorPrimary));
                  },
                ),
              ],
            ),
        ],
      ),
    );

    // --- Most Popular Section ---
    var mostPopularSection = Container(
      padding: EdgeInsets.all(spacing_standard_new),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Most Ordered", style: boldTextStyle(size: 18)),
              Row(
                children: [
                  Text("See All",
                      style: primaryTextStyle(
                          color:
                          appStore.isDarkModeOn ? white : sh_colorPrimary)),
                  Icon(Icons.arrow_forward_ios,
                      size: 14,
                      color: appStore.isDarkModeOn ? white : sh_colorPrimary),
                ],
              ).onTap(() {
                final cat = AmCategory(
                    id: product.category,
                    name: categoryName.isNotEmpty
                        ? categoryName
                        : product.categoryName);
                AmViewAllProductscreen(
                    category: cat, title: cat.name ?? "Category")
                    .launch(context);
              })
            ],
          ).paddingBottom(spacing_standard_new),
          Builder(builder: (context) {
            if (popularProducts.isEmpty) {
              return Text('No products found', style: secondaryTextStyle());
            }

            double aspect = 0.75;
            if (width < 320) {
              aspect = 0.62;
            } else if (width < 360) {
              aspect = 0.66;
            } else {
              aspect = 0.72;
            }

            final tileWidth =
                (width - (spacing_standard_new * 2) - spacing_standard_new) / 2;
            final tileHeight = tileWidth / aspect;

            final left = popularProducts.first;
            final right =
            popularProducts.length > 1 ? popularProducts[1] : null;

            return SizedBox(
              height: tileHeight,
              child: Row(
                children: [
                  SizedBox(
                      width: tileWidth, child: AmProductCard(product: left)),
                  SizedBox(width: spacing_standard_new),
                  SizedBox(
                    width: tileWidth,
                    child: right != null
                        ? AmProductCard(product: right)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );

    // --- Final Scrollable Content (Combined Body) ---
    var combinedContent = SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPaddingForContent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          priceSection,
          descriptionSection,
          ingredientsSection,
          categoryAndBrandSection,
          mostPopularSection,
          40.height,
        ],
      ),
    );

    // --- Sticky Quantity and Cart Bar ---
    // NOTE: padding.bottom (bottomSafeInset) is added below the row so the
    // buttons are never covered by a 3-button nav bar or gesture indicator.
    var stickyBottomBar = Container(
      padding: EdgeInsets.only(
        left: spacing_standard_new,
        right: spacing_standard_new,
        top: spacing_control_half,
        bottom: spacing_control_half + bottomSafeInset,
      ),
      decoration: BoxDecoration(
        color: context.cardColor,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          // Quantity Selector
          Container(
            height: 40,
            padding:
            EdgeInsets.symmetric(horizontal: spacing_middle, vertical: 0),
            decoration: BoxDecoration(
              gradient:
              LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sh_colorPrimary,
                  ),
                  child: Icon(Icons.remove, color: white, size: 18)
                      .paddingAll(spacing_control_half),
                ).onTap(() => _updateQuantity(-1)),
                12.width,
                Text(
                  '$productQuantity',
                  style: boldTextStyle(size: 18, color: white),
                ),
                12.width,
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sh_colorPrimary,
                  ),
                  child: Icon(Icons.add, color: white, size: 18)
                      .paddingAll(spacing_control_half),
                ).onTap(() => _updateQuantity(1)),
              ],
            ),
          ),
          8.width,

          // Add to Cart + Buy Now share the remaining width equally, so both
          // buttons always get the same padding/width regardless of their
          // text length ("Add to Cart" vs "Out of Stock" vs "Buy Now").
          Expanded(
            child: Row(
              children: [
                // Add to Cart Button (equal-width)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: !inStock
                        ? null
                        : () async {
                      if (product.id != null) {
                        try {
                          await CartService().addToCart(product,
                              quantity: productQuantity);
                          toast('Added $productQuantity to cart');
                        } catch (e) {
                          toast(e.toString());
                        }
                      }
                    },
                    child: Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(
                          horizontal: spacing_middle, vertical: 0),
                      decoration: BoxDecoration(
                        color: inStock ? sh_colorPrimary : sh_view_color,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: Text(inStock ? "Add to Cart" : "Out of Stock",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: boldTextStyle(
                              color: !inStock && appStore.isDarkModeOn
                                  ? Colors.lightGreenAccent.shade400
                                  : white)),
                    ),
                  ),
                ),
                8.width,
                // Buy Now Button (equal-width, gradient background)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: !inStock
                        ? null
                        : () async {
                      try {
                        await CartService().addToCart(widget.product,
                            quantity: productQuantity);
                      } catch (e) {
                        toast(e.toString());
                        return;
                      }
                      if (!mounted) return;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        Navigator.of(context, rootNavigator: true).push(
                          MaterialPageRoute(
                              builder: (_) => AmOrderSummaryScreen()),
                        );
                      });
                    },
                    child: Container(
                      height: 40,
                      padding: EdgeInsets.symmetric(
                          horizontal: spacing_middle, vertical: 0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: inStock
                            ? LinearGradient(
                          colors: [sh_gradient_1st, sh_gradient_2nd],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                            : LinearGradient(
                          colors: [sh_view_color, sh_view_color],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(inStock ? "Buy Now" : "Out of Stock",
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: boldTextStyle(
                              color: !inStock && appStore.isDarkModeOn
                                  ? Colors.lightGreenAccent.shade400
                                  : white)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      // extendBody lets the scrollable content flow under the transparent
      // area behind the sticky bar; the bar itself reserves the real safe
      // area via its own bottom padding above.
      extendBody: true,
      body: Stack(
        children: <Widget>[
          NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              changeStatusColor(
                  innerBoxIsScrolled ? Colors.white : Colors.transparent);
              return <Widget>[
                SliverAppBar(
                  expandedHeight: width,
                  floating: false,
                  pinned: true,
                  titleSpacing: 0,
                  backgroundColor: context.cardColor,
                  iconTheme: IconThemeData(
                      color: innerBoxIsScrolled ? sh_textColorPrimary : white),
                  actionsIconTheme: IconThemeData(
                      color: innerBoxIsScrolled ? sh_textColorPrimary : white),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back,
                        color:
                        innerBoxIsScrolled ? sh_textColorPrimary : white),
                    onPressed: () => finish(context),
                  ),
                  title: Text(
                      innerBoxIsScrolled
                          ? product.name.validate(value: 'Product Detail')
                          : "",
                      style: boldTextStyle()),
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: customHeader,
                  ),
                ),
                // REMOVED: SliverPersistentHeader (which contained the TabBar)
              ];
            },
            // FIX: Use the combined scrollable content as the body
            body: combinedContent,
          ),

          // Sticky Footer — pinned to the bottom of the screen; its own
          // padding (see stickyBottomBar above) clears the safe area so the
          // buttons never sit behind a 3-button nav bar or gesture pill.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: stickyBottomBar,
          ),
        ],
      ),
    );
  }

  // NOTE: We don't need the get moreInfoTab or get reviewsTab methods anymore
  // since all content is now combined into one scrollable body.

  Widget reviewText(rating,
      {size = 15.0,
        fontSize = textSizeLargeMedium,
        fontFamily = fontMedium,
        textColor = sh_textColorPrimary}) {
    // ... (unchanged)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(rating.toString(), style: primaryTextStyle()),
        4.width,
        Icon(Icons.star, color: Colors.amber, size: size),
      ],
    );
  }

  Widget ratingProgress(value, color) {
    // ... (unchanged)
    return Expanded(
      child: LinearPercentIndicator(
        lineHeight: 10.0,
        percent: value / 100,
        linearStrokeCap: LinearStrokeCap.roundAll,
        backgroundColor: Colors.grey.withOpacity(0.2),
        progressColor: color,
      ),
    );
  }

  void showRatingDialog(BuildContext context) {
    // ... (unchanged)
  }
}

// REMOVED: The unused _SliverAppBarDelegate class is no longer needed