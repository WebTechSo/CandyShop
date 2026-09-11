import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/screens/AmProductDetail.dart';
import 'package:american_sweets/screens/AmViewAllProducts.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/utils/CategoryHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AmCategoriesFragment extends StatefulWidget {
  @override
  State<AmCategoriesFragment> createState() => _AmCategoriesFragmentState();
}

class _AmCategoriesFragmentState extends State<AmCategoriesFragment> {
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  late final Stream<QuerySnapshot> _categoriesStream;
  List<AmProductModel> _allProducts = [];
  List<AmProductModel> _productSuggestions = [];
  bool _productsLoaded = false;
  bool _loadingProducts = false;
  List<CategoryNode> _categoryTree = [];
  final Map<String, bool> _expandedState = {};
  List<AmCategory> _cachedCategories = [];
  bool _isCategoriesLoading = true;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      setState(() {
        _query = value.trim();
        _productSuggestions = _buildSuggestions(_query);
      });
    });
  }

  List<AmProductModel> _buildSuggestions(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    if (!_productsLoaded) return [];
    final list = _allProducts.where((p) {
      final name = (p.name ?? '').trim().toLowerCase();
      if (name.isEmpty) return false;
      return name.startsWith(q) || name.contains(q);
    }).toList();
    list.sort((a, b) {
      final an = (a.name ?? '').toLowerCase();
      final bn = (b.name ?? '').toLowerCase();
      final aStarts = an.startsWith(q);
      final bStarts = bn.startsWith(q);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return an.compareTo(bn);
    });
    return list.take(5).toList();
  }

  Future<void> _ensureProductsLoaded() async {
    if (_productsLoaded || _loadingProducts) return;
    _loadingProducts = true;
    try {
      final snap =
          await FirebaseFirestore.instance.collection('Products').get();
      final products = snap.docs
          .map((doc) => AmProductModel.fromQuerySnapshot(doc))
          .where((p) => p.status == null || p.status == 'active')
          .toList();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _productsLoaded = true;
        _productSuggestions = _buildSuggestions(_query);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _productsLoaded = true;
        _allProducts = [];
        _productSuggestions = [];
      });
    } finally {
      _loadingProducts = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupCategoriesListener();
    _ensureProductsLoaded();
  }

  void _setupCategoriesListener() {
    setState(() => _isCategoriesLoading = true);
    _categoriesStream = FirebaseFirestore.instance
        .collection('Categories')
        .orderBy('menu_order', descending: false)
        .snapshots();

    _categoriesStream.listen((snapshot) {
      final categories =
          snapshot.docs.map((e) => AmCategory.fromQuerySnapshot(e)).toList();

      if (mounted) {
        setState(() {
          _cachedCategories = categories;
          _categoryTree = CategoryHelper.organizeCategories(categories);
          _syncExpansionStates(_categoryTree);
          _isCategoriesLoading = false;
        });
      }
    }, onError: (e) {
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _updateExpansionState(
      List<CategoryNode> tree, String docId, bool isExpanded) {
    for (var node in tree) {
      if (node.category.docId == docId) {
        node.isExpanded = isExpanded;
        return;
      }
      _updateExpansionState(node.children, docId, isExpanded);
    }
  }

  void _syncExpansionStates(List<CategoryNode> tree) {
    for (var node in tree) {
      if (node.category.docId != null) {
        node.isExpanded = _expandedState[node.category.docId!] ?? false;
      }
      _syncExpansionStates(node.children);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCategoriesLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: _CategoriesSkeleton(),
      );
    }

    // Use cached categories tree for display
    // Flatten the tree for display (only expanded nodes)
    final flattenedNodes =
        CategoryHelper.flattenTree(_categoryTree, expandedOnly: true);

    final bool showPromo = _query.isEmpty;
    final bool showOnlyProductSearch = _query.isNotEmpty;
    final int offset = 1 + (showPromo ? 1 : 0);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 72), // avoid bottom bar
      itemCount: showOnlyProductSearch ? 1 : (flattenedNodes.length + offset),
      separatorBuilder: (_, i) => i == 0 ? 12.height : 12.height,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sh_view_color, width: 1),
                ),
                child: Row(
                  children: [
                    12.width,
                    Icon(Icons.search, color: sh_textColorSecondary),
                    8.width,
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search products',
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close, color: sh_textColorSecondary),
                        splashRadius: 18,
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _query = '';
                            _productSuggestions = [];
                          });
                        },
                      ),
                    12.width,
                  ],
                ),
              ),
              if (_query.isNotEmpty && _loadingProducts)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sh_view_color, width: 1),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      12.width,
                      Text('Searching...', style: secondaryTextStyle()),
                    ],
                  ),
                ),
              if (_productSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sh_view_color, width: 1),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _productSuggestions.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: sh_view_color),
                    itemBuilder: (context, i) {
                      final p = _productSuggestions[i];
                      return InkWell(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _productSuggestions = [];
                          });
                          AmProductDetail(product: p).launch(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Builder(builder: (context) {
                                final imgs = p.images ?? [];
                                final first =
                                    imgs.isNotEmpty ? imgs.first.trim() : '';
                                final thumb = (p.thumbnail ?? '').trim();
                                final src = first.isNotEmpty ? first : thumb;
                                final fallback =
                                    'images/sweets/img/products/candy-1.jpg';
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    color: sh_view_color,
                                    child: src.startsWith('http')
                                        ? Image.network(
                                            src,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(fallback,
                                                    fit: BoxFit.cover),
                                          )
                                        : Image.asset(
                                            src.isNotEmpty ? src : fallback,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Image.asset(fallback,
                                                    fit: BoxFit.cover),
                                          ),
                                  ),
                                );
                              }),
                              12.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (p.name ?? '').trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: primaryTextStyle(),
                                    ),
                                    4.height,
                                    if (FirebaseAuth.instance.currentUser !=
                                        null)
                                      Text(
                                        (p.price ?? 0)
                                            .toString()
                                            .toCurrencyFormat(),
                                        style: secondaryTextStyle(size: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (showOnlyProductSearch &&
                  !_loadingProducts &&
                  _productsLoaded &&
                  _productSuggestions.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sh_view_color, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_off, color: sh_textColorSecondary),
                      12.width,
                      Expanded(
                          child: Text('No products found',
                              style: secondaryTextStyle())),
                    ],
                  ),
                ),
            ],
          );
        }

        if (showPromo && index == 1) {
          return _PromoCard();
        }

        final node = flattenedNodes[index - offset];
        final cat = node.category;
        final hasChildren = CategoryHelper.hasSubcategories(node);
        final isExpanded = _expandedState[cat.docId] ?? false;
        final bool even = (index - offset) % 2 == 0;
        
        print('Rendering category: ${cat.name}, hasChildren: $hasChildren, isExpanded: $isExpanded, docId: ${cat.docId}');
        
        final Gradient bg = LinearGradient(
          colors: even ? [sh_cat_2, sh_cat_1] : [sh_cat_4, sh_cat_3],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );

        final isSubcategory = node.level > 0;
        
        return Container(
          margin: EdgeInsets.only(
            left: isSubcategory ? 32.0 : 0.0, // More prominent indentation for subcategories
          ),
          child: InkWell(
            onTap: () {
              // Always navigate to products when clicking the category card
              AmViewAllProductscreen(category: cat, title: cat.name)
                  .launch(context);
            },
            child: Container(
              constraints: BoxConstraints(
                minHeight: isSubcategory ? 80 : 110, // Smaller height for subcategories
              ),
              decoration: BoxDecoration(
                gradient: isSubcategory 
                    ? LinearGradient(
                        colors: [Colors.grey[400]!, Colors.grey[500]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : bg,
                borderRadius: BorderRadius.circular(16),
                border: isSubcategory 
                    ? Border.all(color: Colors.grey[600]!, width: 1) 
                    : null,
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    16.width,
                    // Visual indicator for subcategories
                    if (isSubcategory && !hasChildren)
                      Container(
                        width: 4,
                        height: 24,
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    // Expand/collapse button for categories with subcategories
                    if (hasChildren)
                      GestureDetector(
                        onTap: () {
                          print('Toggling category: ${cat.name}, current state: $isExpanded');
                          setState(() {
                            _expandedState[cat.docId!] = !isExpanded;
                            _updateExpansionState(_categoryTree, cat.docId!, !isExpanded);
                            print('New expansion state: ${_expandedState[cat.docId]}');
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: white,
                            size: 20,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: hasChildren ? 12 : (isSubcategory ? 8 : 0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              cat.name ?? '',
                              style: boldTextStyle(
                                  color: white, 
                                  size: isSubcategory ? 14 : 18,
                                  weight: isSubcategory ? FontWeight.w500 : FontWeight.w700),
                              softWrap: true,
                            ),
                            if (hasChildren)
                              Text(
                                '${node.children.length} subcategories • Tap ↓ to expand',
                                style: secondaryTextStyle(
                                    color: white.withValues(alpha: 0.8),
                                    size: 11),
                              ),
                            if (isSubcategory)
                              Text(
                                '↳ Subcategory',
                                style: secondaryTextStyle(
                                    color: white.withValues(alpha: 0.6),
                                    size: 10),
                              ),
                          ],
                        ),
                      ),
                    ),
                    8.width,
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: Container(
                        width: isSubcategory ? 120 : 160, // Smaller image for subcategories
                        height: double.infinity,
                        color: Colors.white.withValues(alpha: isSubcategory ? 0.1 : 0.15),
                        child: _CategoryImage(src: cat.image),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PromoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final bg = (data['offer_background'] ?? '').toString();
        final firstName = (data['first_name_logo'] ??
                'Its Time For North American Confectioneries')
            .toString();
        // final lastName = (data['last_name_logo'] ?? 'Sweets').toString();
        final title =
            (data['offer_title'] ?? 'Spend £39.99 & Get\nFree UK Shipping')
                .toString();
        final subtitle =
            (data['offer_subtitle'] ?? 'Perfect Time to Stock Up').toString();
        final details = (data['offer_details'] ??
                'Most customers add 2–3 favourites to unlock free delivery.')
            .toString();
        final buttonText =
            (data['offer_button'] ?? 'Unlock Free Shipping').toString();
        final route = (data['offer_route'] ?? 'categories').toString();

        Widget bgWidget;
        if (bg.startsWith('http')) {
          bgWidget = Image.network(bg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: sh_view_color));
        } else if (bg.isNotEmpty) {
          bgWidget = Image.asset(bg,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: sh_view_color));
        } else {
          bgWidget = Image.asset(
            'images/candies-sweets-colored-background.jpg',
            fit: BoxFit.cover,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(child: bgWidget),
              Positioned.fill(
                child:
                    Container(color: sh_colorPrimary.withValues(alpha: 0.15)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(ic_app_icon, width: width * 0.3),
                    Text(
                      firstName,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Calibri',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 3, 3, 3),
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: sh_colorPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: boldTextStyle(color: white, size: 18),
                          ),
                          6.height,
                          Text(
                            subtitle,
                            style: boldTextStyle(color: white, size: 14),
                          ),
                          4.height,
                          Text(
                            details,
                            textAlign: TextAlign.center,
                            style: secondaryTextStyle(
                                color: white.withValues(alpha: 0.9)),
                          ),
                        ],
                      ),
                    ),
                    12.height,
                    AppButton(
                      text: buttonText,
                      textColor: sh_colorPrimary,
                      color: white,
                      onTap: () {
                        if (route == 'products') {
                          AmHomeScreen(initialTab: 1)
                              .launch(context, isNewTask: true);
                        }
                        /*else {
                          AmHomeScreen(initialTab: 0)
                              .launch(context, isNewTask: true);
                        }*/
                      },
                      shapeBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryImage extends StatelessWidget {
  final String? src;
  const _CategoryImage({this.src});

  @override
  Widget build(BuildContext context) {
    final String s = (src ?? '').trim();
    if (s.isEmpty) {
      return Icon(Icons.category, color: white);
    }
    if (s.startsWith('http')) {
      return Image.network(s,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: white));
    }
    return Image.asset(s,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: white));
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    return Column(
      children: List.generate(
        6,
        (_) => Container(
          height: 110, // height for skeleton
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
