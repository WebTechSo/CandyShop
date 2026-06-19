import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/AddProductScreen.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:american_sweets/screens/ProductDetailsScreen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:american_sweets/utils/AmNotificationBell.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({Key? key}) : super(key: key);
  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  int _currentTab = 3;
  int _filterIndex = 0;
  RangeValues _price = const RangeValues(0, 10000);
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedFilter = 0; // 0: All, 1: Active, 2: Hold, 3: Delete
  String? _sortColumn;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      appBar: AppBar(
        backgroundColor: sh_background_color,
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
                  colors: [sh_gradient_1st, sh_gradient_2nd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight)
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(sh_app_name,
              style: GoogleFonts.workSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ),
        actions: [
          AmNotificationBell(
            iconColor: appStore.isDarkModeOn ? white : sh_textColorPrimary,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: context.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sh_view_color, width: 1),
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search products...",
                        hintStyle: secondaryTextStyle(),
                        border: InputBorder.none,
                        prefixIcon:
                            Icon(Icons.search, color: sh_textColorSecondary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: sh_textColorSecondary),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: sh_colorPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: sh_colorPrimary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.filter_list, color: white, size: 24),
                    onPressed: _openFilterDrawer,
                    tooltip: 'Filter Products',
                  ),
                ),
              ],
            ),
          ),
          12.height,
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                            label: 'All',
                            selected: _selectedFilter == 0,
                            onTap: () => setState(() => _selectedFilter = 0)),
                        8.width,
                        _FilterChip(
                            label: 'Active',
                            selected: _selectedFilter == 1,
                            onTap: () => setState(() => _selectedFilter = 1)),
                        8.width,
                        _FilterChip(
                            label: 'Hold',
                            selected: _selectedFilter == 2,
                            onTap: () => setState(() => _selectedFilter = 2)),
                        8.width,
/*                        _FilterChip(
                            label: 'Delete',
                            selected: _selectedFilter == 3,
                            onTap: () => setState(() => _selectedFilter = 3)),*/
                      ],
                    ),
                  ),
                ),
                10.width,
                _AddIconButton(
                  onTap: () => const AddProductScreen().launch(context),
                ),
              ],
            ),
          ),
          12.height,
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: Container(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [sh_gradient_1st, sh_gradient_2nd]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: spacing_standard_new, vertical: 14),
                child: Row(children: [
                  SizedBox(
                      width: 52,
                      child: Text('Image',
                          style: GoogleFonts.workSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sh_white))),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        if (_sortColumn == 'name') {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortColumn = 'name';
                          _sortAscending = true;
                        }
                      }),
                      child: Row(
                        children: [
                          Text('Name',
                              style: GoogleFonts.workSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: sh_white)),
                          if (_sortColumn == 'name')
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: sh_white,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: InkWell(
                      onTap: () => setState(() {
                        if (_sortColumn == 'price') {
                          _sortAscending = !_sortAscending;
                        } else {
                          _sortColumn = 'price';
                          _sortAscending = true;
                        }
                      }),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Price',
                              textAlign: TextAlign.right,
                              style: GoogleFonts.workSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: sh_white)),
                          if (_sortColumn == 'price')
                            Icon(
                              _sortAscending
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: sh_white,
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                      width: 72,
                      child: Text('Action',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.workSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: sh_white))),
                ]),
              ),
            ),
          ),
          8.height,
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Products').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final products = snapshot.data!.docs
                    .map((doc) => AmProductModel.fromQuerySnapshot(doc))
                    .toList();

                // Apply local filtering
                final filtered = products.where((p) {
                  final matchesPrice = (p.price ?? 0) >= _price.start &&
                      (p.price ?? 0) <= _price.end;
                  final matchesSearch = _searchQuery.isEmpty ||
                      (p.name != null &&
                          p.name!
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()));

                  bool matchesStatus = true;
                  if (_selectedFilter == 1)
                    matchesStatus = p.status == 'active';
                  else if (_selectedFilter == 2)
                    matchesStatus = p.status == 'hold';
                  else if (_selectedFilter == 0)
                    matchesStatus = p.status != 'delete'; //ignore deleted

                  return matchesPrice && matchesSearch && matchesStatus;
                }).toList();

                if (_sortColumn == 'name') {
                  filtered.sort((a, b) {
                    final nameA = a.name ?? '';
                    final nameB = b.name ?? '';
                    return _sortAscending
                        ? nameA.compareTo(nameB)
                        : nameB.compareTo(nameA);
                  });
                } else if (_sortColumn == 'price') {
                  filtered.sort((a, b) {
                    final priceA = a.price ?? 0;
                    final priceB = b.price ?? 0;
                    return _sortAscending
                        ? priceA.compareTo(priceB)
                        : priceB.compareTo(priceA);
                  });
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: spacing_standard_new),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => 12.height,
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return InkWell(
                      onTap: () {
                        ProductDetailsScreen(product: p).launch(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow:
                                defaultBoxShadow(shadowColor: appShadowColor)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: spacing_standard_new, vertical: 12),
                          child: Row(children: [
                            _GlowImage(
                                path: (p.images != null && p.images!.isNotEmpty)
                                    ? p.images!.first
                                    : ''),
                            12.width,
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name ?? 'No Name',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.workSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: sh_textColorPrimary),
                                ),
                                if (p.brand != null && p.brand!.isNotEmpty)
                                  Text(p.brand!,
                                      style: GoogleFonts.workSans(
                                          fontSize: 12,
                                          color: sh_textColorSecondary)),
                                6.height,
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: _getStatusColor(p.status)
                                              .withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Text(
                                          (p.status ?? 'active').toUpperCase(),
                                          style: GoogleFonts.workSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _getStatusColor(p.status))),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                            SizedBox(
                              width: 90,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('£${(p.price ?? 0).toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.workSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: sh_textColorPrimary)),
                                  4.height,
                                  Text(
                                      'Stock - ${(p.availableQuantity ?? 0).toString()}',
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.workSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: sh_textColorSecondary)),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            SizedBox(
                                width: 72,
                                child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            if (p.id == null) return;
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('Products')
                                                  .doc(p.id)
                                                  .update({
                                                'product_status': 'delete'
                                              });
                                              toast('Moved to Delete');
                                            } catch (e) {
                                              toast('Delete failed: $e');
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(Icons.delete_outline,
                                                size: 18,
                                                color: Colors.redAccent),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            ProductDetailsScreen(product: p)
                                                .launch(context);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Icon(Icons.edit,
                                                size: 18,
                                                color: sh_textColorSecondary),
                                          ),
                                        ),
                                        4.width,
                                        Icon(Icons.arrow_forward_ios,
                                            size: 16,
                                            color: sh_textColorSecondary),
                                      ],
                                    )))
                          ]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) {
            if (i == _currentTab) return;
            setState(() => _currentTab = i);
            if (i == 0) AmHomeScreen().launch(context);
            if (i == 1) const AdminDashboardScreen().launch(context);
            if (i == 2) OrderManagementScreen().launch(context);
            if (i == 3) ProductManagementScreen().launch(context);
            if (i == 4) CustomerManagementScreen().launch(context);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: sh_colorPrimary,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_outlined), label: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined), label: 'Products'),
            BottomNavigationBarItem(
                icon: Icon(Icons.group_outlined), label: 'Customers'),
          ],
        ),
      ),
    );
  }

  void _openFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, __, ___) {
        return StatefulBuilder(builder: (context, setInnerState) {
          return Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 320,
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                decoration: BoxDecoration(
                    color: sh_background_color,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        bottomLeft: Radius.circular(24)),
                    boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                child: _FilterDrawer(
                  price: _price,
                  onPriceChanged: (v) {
                    setInnerState(() {
                      _price = v;
                    });
                    this.setState(() {
                      _price = v;
                    });
                  },
                  onApply: () {
                    Navigator.of(context).maybePop();
                  },
                  onClear: () {
                    this.setState(() {
                      _filterIndex = 0;
                      _price = const RangeValues(0, 10000);
                    });
                    Navigator.of(context).maybePop();
                  },
                ),
              ),
            ),
          );
        });
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(anim),
            child: child);
      },
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'active') return const Color(0xFF2F8F46);
    if (status == 'inactive') return Colors.red;
    if (status == 'hold') return const Color(0xFF956A24);
    if (status == 'delete') return Colors.redAccent;
    return const Color(0xFF2F8F46);
  }
}

class _GlowImage extends StatelessWidget {
  final String path;
  const _GlowImage({Key? key, required this.path}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
        BoxShadow(
            color: const Color(0x33FFC107), blurRadius: 12, spreadRadius: 2)
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: path.startsWith('http')
            ? CachedNetworkImage(
                imageUrl: path,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 20),
                ),
              )
            : Image.asset(
                path.isEmpty ? 'images/sweets/img/products/candy-1.jpg' : path,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 20),
                ),
              ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({Key? key, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [sh_gradient_1st, sh_gradient_2nd]),
            borderRadius: BorderRadius.circular(32),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Text('+ Add Product',
            style: GoogleFonts.workSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: sh_white)),
      ),
    );
  }
}

class _AddIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddIconButton({Key? key, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [sh_gradient_1st, sh_gradient_2nd]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: const Icon(Icons.add, color: sh_white, size: 22),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {Key? key,
      required this.label,
      required this.selected,
      required this.onTap})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final base = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: selected ? null : Colors.white,
          gradient: selected
              ? const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd])
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
      child: Text(label,
          style: GoogleFonts.workSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? sh_white : sh_textColorPrimary)),
    );
    return GestureDetector(onTap: onTap, child: base);
  }
}

class _FilterDrawer extends StatelessWidget {
  final RangeValues price;
  final ValueChanged<RangeValues> onPriceChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  const _FilterDrawer(
      {Key? key,
      required this.price,
      required this.onPriceChanged,
      required this.onApply,
      required this.onClear})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: sh_background_color,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(spacing_standard_new),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                          colors: [sh_gradient_1st, sh_gradient_2nd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight)
                      .createShader(Rect.fromLTWH(0, 0, b.width, b.height)),
                  child: Text('Filter',
                      style: GoogleFonts.workSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white))),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: sh_textColorPrimary))
            ]),
            16.height,
            Text('Price',
                style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: sh_colorPrimary)),
            8.height,
            Row(children: [
              Text('£${price.start.toStringAsFixed(0)}',
                  style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sh_textColorSecondary)),
              const Spacer(),
              Text('£${price.end.toStringAsFixed(0)}',
                  style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: sh_textColorSecondary)),
            ]),
            RangeSlider(
                values: price,
                min: 0,
                max: 10000,
                activeColor: sh_colorPrimary,
                inactiveColor: sh_view_color,
                onChanged: onPriceChanged),
            16.height,
            Row(children: [
              Expanded(
                  child: _PillAction(
                      label: 'Apply Filter',
                      bgColor: sh_colorPrimary,
                      onTap: onApply)),
              12.width,
              Expanded(
                  child: _PillAction(
                      label: 'Clear',
                      gradient: const LinearGradient(
                          colors: [sh_gradient_1st, sh_gradient_2nd]),
                      onTap: onClear)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  const _PillAction(
      {Key? key,
      required this.label,
      required this.onTap,
      this.bgColor,
      this.gradient})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: bgColor,
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Text(label,
            style: GoogleFonts.workSans(
                fontSize: 14, fontWeight: FontWeight.w700, color: sh_white)),
      ),
    );
  }
}
