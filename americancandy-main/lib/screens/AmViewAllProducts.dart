import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmAttribute.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';
import 'package:american_sweets/utils/AmProductCard.dart';
import 'package:american_sweets/utils/CartBadgeIcon.dart';
import 'package:american_sweets/data/services/cart_service.dart';
import 'AmOrderSummaryScreen.dart';

import 'AmProductDetail.dart';
import 'AmHomeScreen.dart';

// ignore: must_be_immutable
class AmViewAllProductscreen extends StatefulWidget {
  static String tag = '/ViewAllProductScreen';

  List<AmProductModel>? prodcuts;
  AmCategory? category;
  String? brandName;
  var title;

  AmViewAllProductscreen(
      {this.prodcuts, this.title, this.category, this.brandName});

  @override
  AmViewAllProductscreenState createState() {
    return AmViewAllProductscreenState();
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  final Color base;
  final Color highlight;
  const _Shimmer(
      {required this.child, required this.base, required this.highlight});
  @override
  _ShimmerState createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1500))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = (1.0 + 2.0) * _controller.value - 1.0;
            return LinearGradient(
              begin: Alignment(-1.0 + dx, 0),
              end: Alignment(1.0 + dx, 0),
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300
              ],
              stops: [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

Widget _CategorySkeletonLoader() {
  final base = Colors.grey.shade300;
  final highlight = Colors.grey.shade100;
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: _Shimmer(
        base: base,
        highlight: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 8,
              itemBuilder: (_, __) {
                return Container(
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}

class AmViewAllProductscreenState extends State<AmViewAllProductscreen> {
  var sortType = -1;
  List<AmProductModel> mProductModel = [];
  List<AmProductModel> _allProducts = [];
  AmAttributes? mProductAttributeModel;

  var isListViewSelected = false;
  var errorMsg = '';
  var scrollController = new ScrollController();
  bool isLoading = false;
  bool isLoadingMoreData = false;
  int page = 1;
  bool isLastPage = false;
  var primaryColor;
  bool includeVat = getBoolAsync('include_vat', defaultValue: true);

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  fetchData() async {
    setState(() {
      isLoading = true;
    });

    List<AmProductModel> products = [];
    AmAttributes? model;

    try {
      model = await loadAttributes();
    } catch (e) {
      print('Error loading attributes: $e');
    }

    try {
      if (widget.prodcuts != null) {
        products.addAll(widget.prodcuts!);
      } else {
        // Load ALL Firestore products and filter in memory to ensure consistency
        // with AmHomeFragment and handle both ID/Name categories.
        try {
          QuerySnapshot querySnapshot =
              await FirebaseFirestore.instance.collection('Products').get();

          products = querySnapshot.docs
              .map((doc) => AmProductModel.fromQuerySnapshot(doc))
              .where((p) => p.status == 'active' || p.status == null)
              .toList()
              ..sort((a, b) =>
              (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));;

          if (widget.category != null) {
            int? catId = widget.category!.id;
            String? catName = widget.category!.name?.toLowerCase().trim();

            products = products.where((p) {
              bool idMatch =
                  p.category != null && catId != null && p.category == catId;
              bool nameMatch = p.categoryName != null &&
                  catName != null &&
                  p.categoryName!.toLowerCase().trim() == catName;
              return idMatch || nameMatch;
            }).toList();
          } else if (widget.brandName != null) {
            products =
                products.where((p) => p.brand == widget.brandName).toList();
          }
        } catch (e) {
          print('Error loading Firestore products: $e');
        }
      }
    } catch (e) {
      print('Error processing products: $e');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
        mProductAttributeModel = model;
        _allProducts = products;
        mProductModel = List.from(products);
      });
    }
  }

  void onListClick(which) {
    setState(() {
      if (which == 1) {
        isListViewSelected = true;
      } else if (which == 2) {
        isListViewSelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    final listView = Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: mProductModel.length,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        separatorBuilder: (_, __) => 16.height,
        itemBuilder: (context, index) {
          final p = mProductModel[index];
          final img = (p.images != null && p.images!.isNotEmpty)
              ? p.images!.first
              : ((p.thumbnail?.isNotEmpty ?? false) ? p.thumbnail! : '');
          return InkWell(
            onTap: () => AmProductDetail(product: p).launch(context),
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: defaultBoxShadow(shadowColor: appShadowColor),
              ),
              child: SizedBox(
                height: 150,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: SizedBox.expand(
                              child: Container(
                                color: Colors.grey[200],
                                child: img.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: img,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) => Container(
                                          color: Colors.grey[200],
                                        ),
                                        errorWidget: (c, u, e) =>
                                            Icon(Icons.broken_image),
                                      )
                                    : (img.isNotEmpty
                                        ? Image.asset(
                                            "images/sweets/img/products$img",
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Icon(Icons.broken_image),
                                          )
                                        : Icon(Icons.image_not_supported)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: () {
                                CartService().addToCart(p);
                                toast('Added to cart');
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: sh_colorPrimary,
                                  shape: BoxShape.circle,
                                  boxShadow: defaultBoxShadow(
                                      shadowColor: appShadowColor),
                                ),
                                child: Icon(Icons.add, color: white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name ?? 'Product',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: boldTextStyle(size: 16)),
                            6.height,
                            Expanded(
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  p.description ??
                                      'Delicious candy straight from the USA.',
                                  style: secondaryTextStyle(size: 12),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            6.height,
                            Builder(builder: (context) {
                              final double base = p.price ?? 0.0;
                              final double rate = (p.vatRate ?? 0.0) / 100.0;
                              final double shown =
                                  includeVat ? base * (1 + rate) : base;
                              return Text(
                                shown.toCurrencyFormat().replaceAll('\$', '£'),
                                style: boldTextStyle(
                                    size: 18, color: sh_colorPrimary),
                              );
                            }),
                            6.height,
                            GestureDetector(
                              onTap: () {
                                if (FirebaseAuth.instance.currentUser == null) {
                                  toast("You need to login to add wishlist");
                                } else if (p.id != null) {
                                  WishlistService().addToWishlist(p.id!);
                                  toast("Added to wishlist");
                                }
                              },
                              child: Icon(Icons.favorite_border,
                                  size: 26, color: sh_textColorPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    final gridView = Container(
      padding: EdgeInsets.all(16),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: (() {
            final w = MediaQuery.of(context).size.width;
            if (w < 320) return 0.62;
            if (w < 360) return 0.66;
            return 0.72;
          })(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: mProductModel.length,
        itemBuilder: (context, index) {
          return AmProductCard(product: mProductModel[index]);
        },
      ),
    );

    final bool isCompact =
        MediaQuery.of(context).size.width < 380; // responsive

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actionsIconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => showMyBottomSheet(context),
                  tooltip: 'Filter',
                ),
                IconButton(
                  icon: Icon(
                      isListViewSelected ? Icons.view_list : Icons.border_all,
                      size: 24),
                  onPressed: () {
                    setState(() {
                      isListViewSelected = !isListViewSelected;
                    });
                  },
                  tooltip: isListViewSelected ? 'List' : 'Grid',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      mProductModel.clear();
                    });
                    fetchData();
                  },
                  tooltip: 'Refresh',
                ),
                if (isCompact)
                  IconButton(
                    icon: Icon(includeVat ? Icons.toggle_on : Icons.toggle_off,
                        color: sh_colorPrimary),
                    onPressed: () {
                      setState(() {
                        includeVat = !includeVat;
                        setValue('include_vat', includeVat);
                      });
                    },
                    tooltip: 'VAT',
                  )
                else
                  Row(
                    children: [
                      Text('VAT', style: primaryTextStyle()),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch(
                          value: includeVat,
                          thumbColor: WidgetStateProperty.all(sh_colorPrimary),
                          onChanged: (v) {
                            setState(() {
                              includeVat = v;
                              setValue('include_vat', includeVat);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? _CategorySkeletonLoader()
          : SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: <Widget>[
                  errorMsg.isEmpty
                      ? Center(
                          child: mProductModel.isNotEmpty
                              ? Column(children: <Widget>[
                                  isListViewSelected ? listView : gridView,
                                  CircularProgressIndicator()
                                      .visible(isLoadingMoreData)
                                ])
                              : Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 48, 16, 80),
                                  child: Text(
                                    'No Product found',
                                    style: secondaryTextStyle(size: 16),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                        )
                      : Center(child: Text(errorMsg)),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Products
        type: BottomNavigationBarType.fixed,
        selectedItemColor: sh_colorPrimary,
        unselectedItemColor: sh_textColorSecondary,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: 'Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(icon: CartBadgeIcon(), label: 'Cart'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Account'),
        ],
        onTap: (i) async {
          if (i == 3) {
            try {
              final snap = await CartService().getCartStream().first;
              if (snap.docs.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (_) => AmOrderSummaryScreen()),
                  );
                });
                return;
              }
            } catch (_) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => AmOrderSummaryScreen()),
                );
              });
              return;
            }
          }
          AmHomeScreen(initialTab: i).launch(context, isNewTask: true);
        },
      ),
    );
  }

  void showMyBottomSheet(context) {
    if (mProductModel.isEmpty) return;
    void onSave(List<int> category, List<String> size, List<String> color,
        List<String> brand) {
      // Apply size/flavor filters to current category's products
      final Set<String> selectedSizes =
          size.map((e) => e.trim().toLowerCase()).toSet();
      final Set<String> selectedFlavors =
          brand.map((e) => e.trim().toLowerCase()).toSet(); // flavors param
      setState(() {
        List<AmProductModel> base = List.from(_allProducts);
        if (selectedSizes.isNotEmpty) {
          base = base
              .where((p) =>
                  (p.variants?.size ?? '').trim().isNotEmpty &&
                  selectedSizes
                      .contains((p.variants!.size ?? '').trim().toLowerCase()))
              .toList();
        }
        if (selectedFlavors.isNotEmpty) {
          base = base
              .where((p) =>
                  (p.variants?.flavor ?? '').trim().isNotEmpty &&
                  selectedFlavors.contains(
                      (p.variants!.flavor ?? '').trim().toLowerCase()))
              .toList();
        }
        mProductModel = base;
      });
    }

    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return FilterBottomSheetLayout(
              mProductAttributeModel: mProductAttributeModel, onSave: onSave);
        },
        fullscreenDialog: true));
  }

  List<Widget> sizeWidget(List<String> size) {
    var maxWidget = 5;
    var currentIndex = 0;
    List<Widget> list = [];
    var totalSize = size.length;
    var flag = false;

    size.forEach((size) {
      if (currentIndex < maxWidget) {
        list.add(Container(
          margin: EdgeInsets.only(right: spacing_middle),
          child: Center(
              child: text(size.trim(),
                  fontSize: textSizeMedium,
                  textColor: sh_textColorPrimary,
                  fontFamily: fontMedium)),
        ));
        currentIndex++;
      } else {
        if (!flag) list.add(Text('+ ${totalSize - maxWidget} more'));
        flag = true;
        return;
      }
    });
    return list;
  }
}

// ignore: must_be_immutable
class FilterBottomSheetLayout extends StatefulWidget {
  AmAttributes? mProductAttributeModel;
  var onSave;

  FilterBottomSheetLayout({Key? key, this.mProductAttributeModel, this.onSave})
      : super(key: key);

  @override
  FilterBottomSheetLayoutState createState() {
    return FilterBottomSheetLayoutState();
  }
}

class FilterBottomSheetLayoutState extends State<FilterBottomSheetLayout> {
  List<int> selectedCategories = [];
  List<String> selectedColors = [];
  List<String> selectedSizes = [];
  List<String> selectedBrands = [];

  @override
  void initState() {
    super.initState();
    _fetchDynamicAttributes();
  }

  Future<void> _fetchDynamicAttributes() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .get();
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final List<String> sizes =
          (data['variant_sizes'] as List?)?.map((e) => e.toString()).toList() ??
              [];
      final List<String> flavors = (data['variant_flavors'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      setState(() {
        if (widget.mProductAttributeModel == null) {
          widget.mProductAttributeModel = AmAttributes(size: [], flavor: []);
        }
        widget.mProductAttributeModel!.size =
            sizes.map((s) => AmSize(name: s, slug: s.toLowerCase())).toList();
        widget.mProductAttributeModel!.flavor = flavors
            .map((f) => AmFlavor(name: f, slug: f.toLowerCase()))
            .toList();
      });
    } catch (e) {
      print('Error fetching admin attributes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var sizesList = widget.mProductAttributeModel?.size ?? [];
    var flavorsList = widget.mProductAttributeModel?.flavor ?? [];
    final productSizeListView = ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: sizesList.length,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChoiceChip(
              label: Text(
                sizesList[index].name ?? '',
                style: TextStyle(
                  color: sizesList[index].isSelected
                      ? sh_white
                      : sh_textColorPrimary,
                ),
              ),
              selected: sizesList[index].isSelected,
              showCheckmark: true,
              checkmarkColor: sh_white,
              onSelected: (selected) {
                setState(() {
                  sizesList[index].isSelected = !sizesList[index].isSelected;
                });
              },
              elevation: 2,
              backgroundColor: Colors.white10,
              selectedColor: sh_colorPrimary,
            ),
          );
        });

    final productFlavorListView = ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: flavorsList.length,
        itemBuilder: (_, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChoiceChip(
              label: Text(
                flavorsList[index].name ?? '',
                style: TextStyle(
                  color: flavorsList[index].isSelected
                      ? sh_white
                      : sh_textColorPrimary,
                ),
              ),
              selected: flavorsList[index].isSelected,
              showCheckmark: true,
              checkmarkColor: sh_white,
              onSelected: (selected) {
                setState(() {
                  flavorsList[index].isSelected =
                      !flavorsList[index].isSelected;
                });
              },
              elevation: 2,
              backgroundColor: Colors.white10,
              selectedColor: sh_colorPrimary,
            ),
          );
        });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: sh_colorPrimary,
        title: text(sh_lbl_filter,
            textColor: sh_white,
            fontSize: textSizeNormal,
            fontFamily: fontMedium),
        iconTheme: IconThemeData(color: sh_white),
        actions: <Widget>[
          InkWell(
              child: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: spacing_middle),
                  child: Text(sh_lbl_apply,
                      style: TextStyle(
                          color: sh_white,
                          fontFamily: fontMedium,
                          fontSize: textSizeLargeMedium))),
              onTap: () {
                // Collect selected filters
                List<String> selectedSizes = [];
                List<String> selectedFlavors = [];

                for (var size in sizesList) {
                  if (size.isSelected) {
                    selectedSizes.add(size.name ?? '');
                  }
                }

                for (var flavor in flavorsList) {
                  if (flavor.isSelected) {
                    selectedFlavors.add(flavor.name ?? '');
                  }
                }

                // Call the onSave callback with the selected filters
                if (widget.onSave != null) {
                  widget.onSave(const <int>[], selectedSizes, const <String>[],
                      selectedFlavors);
                }

                Navigator.of(context).pop();
              })
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Size Section
            Padding(
              padding: EdgeInsets.only(
                  left: spacing_standard_new, top: spacing_standard_new),
              child: Text(sh_lbl_size,
                  style: TextStyle(
                      color:
                          appStore.isDarkModeOn ? white : sh_textColorPrimary,
                      fontFamily: fontMedium,
                      fontSize: textSizeLargeMedium)),
            ),
            8.height,
            Container(child: productSizeListView, height: 50),

            // Flavor Section
            Padding(
              padding: EdgeInsets.only(
                  left: spacing_standard_new, top: spacing_standard_new),
              child: Text('Flavor',
                  style: TextStyle(
                      color:
                          appStore.isDarkModeOn ? white : sh_textColorPrimary,
                      fontFamily: fontMedium,
                      fontSize: textSizeLargeMedium)),
            ),
            8.height,
            Container(child: productFlavorListView, height: 50),
          ],
        ),
      ),
    );
  }
}
