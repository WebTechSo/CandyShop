// lib/screens/OrderManagementScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/OrderDetailsScreen.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/data/services/order_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/utils/AmNotificationBell.dart';

class OrderManagementScreen extends StatefulWidget {
  final int initialFilter;
  const OrderManagementScreen({Key? key, this.initialFilter = 0})
      : super(key: key);
  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  int _currentTab = 2;
  int _filterIndex = 0;
  final OrderService _orderService = OrderService();
  RangeValues _priceRange = const RangeValues(0, 1000);
  String _sortOrder = 'latest'; // 'latest' or 'oldest'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _orderMinPrice = 0.0;
  double _orderMaxPrice = 1000.0;

  @override
  void initState() {
    super.initState();
    _filterIndex = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      body: SafeArea(
        child: Column(
          children: [
            8.height,
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [sh_gradient_1st, sh_gradient_2nd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(sh_app_name,
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            12.height,
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: spacing_standard_new),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      onTap: () => finish(context),
                      child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: defaultBoxShadow(
                                  shadowColor: appShadowColor)),
                          child: const Icon(Icons.arrow_back))),
                  Text('Order Management',
                      style: GoogleFonts.workSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: sh_colorPrimary)),
                  AmNotificationBell(iconColor: sh_colorPrimary),
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sh_view_color, width: 1),
                      ),
                      child: TextFormField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: "Search Order ID...",
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
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                  12.width,
                  Container(
                    decoration: BoxDecoration(
                      color: sh_colorPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: sh_colorPrimary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.filter_list, color: white, size: 24),
                      onPressed: _openFilterDrawer,
                      tooltip: 'Filter Orders',
                    ),
                  ),
                ],
              ),
            ),
            12.height,
            Expanded(
              child: StreamBuilder<List<AmOrder>>(
                stream: _orderService.getAllOrders(),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? <AmOrder>[];

                  final q =
                      _searchQuery.trim().toLowerCase().replaceAll('#', '');

                  bool matchesSearch(AmOrder o) {
                    if (q.isEmpty) return true;
                    final raw = ((o.orderCode ?? o.id ?? '').toString())
                        .toLowerCase()
                        .replaceAll('#', '');
                    return raw.contains(q);
                  }

                  bool matchesPrice(AmOrder o) {
                    final price = o.grandTotal ?? 0.0;
                    return price >= _priceRange.start &&
                        price <= _priceRange.end;
                  }

                  // Update dynamic min/max for order totals
                  double minPrice = double.infinity;
                  double maxPrice = 0.0;
                  for (final o in orders) {
                    final v = (o.grandTotal ?? 0.0);
                    if (v < minPrice) minPrice = v;
                    if (v > maxPrice) maxPrice = v;
                  }
                  if (minPrice == double.infinity) minPrice = 0.0;
                  if (maxPrice < minPrice) maxPrice = minPrice;
                  _orderMinPrice = minPrice.floorToDouble();
                  _orderMaxPrice = maxPrice.ceilToDouble();
                  if (_priceRange.start < _orderMinPrice ||
                      _priceRange.end > _orderMaxPrice) {
                    _priceRange = RangeValues(_orderMinPrice, _orderMaxPrice);
                  }

                  final baseForCounts = orders
                      .where((o) => matchesSearch(o) && matchesPrice(o))
                      .toList();

                  int allCount = baseForCounts.length;
                  int pendingCount = 0;
                  int processingCount = 0;
                  int shippedCount = 0;
                  int completedCount = 0;
                  int cancelledCount = 0;

                  for (final o in baseForCounts) {
                    final status = (o.deliveryStatus ?? 'Pending').toString();
                    if (status == 'Pending') pendingCount++;
                    if (status == 'Processing') processingCount++;
                    if (status == 'Shipped') shippedCount++;
                    if (status == 'Cancelled') cancelledCount++;
                    if (status == 'Completed' || status == 'Delivered') {
                      completedCount++;
                    }
                  }

                  final chipsRow = Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: spacing_standard_new),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                    label: 'All $allCount',
                                    selected: _filterIndex == 0,
                                    onTap: () =>
                                        setState(() => _filterIndex = 0)),
                                8.width,
                                _FilterChip(
                                    label: 'Pending $pendingCount',
                                    selected: _filterIndex == 1,
                                    onTap: () =>
                                        setState(() => _filterIndex = 1)),
                                8.width,
                                _FilterChip(
                                    label: 'Processing $processingCount',
                                    selected: _filterIndex == 2,
                                    onTap: () =>
                                        setState(() => _filterIndex = 2)),
                                8.width,
                                _FilterChip(
                                    label: 'Shipped $shippedCount',
                                    selected: _filterIndex == 3,
                                    onTap: () =>
                                        setState(() => _filterIndex = 3)),
                                8.width,
                                _FilterChip(
                                    label: 'Completed $completedCount',
                                    selected: _filterIndex == 4,
                                    onTap: () =>
                                        setState(() => _filterIndex = 4)),
                                8.width,
                                _FilterChip(
                                    label: 'Cancelled $cancelledCount',
                                    selected: _filterIndex == 5,
                                    onTap: () =>
                                        setState(() => _filterIndex = 5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (snapshot.hasError) {
                    return Column(
                      children: [
                        chipsRow,
                        12.height,
                        Expanded(
                            child: Center(
                                child: Text('Error: ${snapshot.error}'))),
                      ],
                    );
                  }

                  if (!snapshot.hasData) {
                    return Column(
                      children: [
                        chipsRow,
                        12.height,
                        const Expanded(
                            child: Center(child: CircularProgressIndicator())),
                      ],
                    );
                  }

                  final filtered = orders.where((o) {
                    final status = o.deliveryStatus ?? 'Pending';

                    bool matchesStatus = true;
                    if (_filterIndex == 1) matchesStatus = status == 'Pending';
                    if (_filterIndex == 2)
                      matchesStatus = status == 'Processing';
                    if (_filterIndex == 3) matchesStatus = status == 'Shipped';
                    if (_filterIndex == 4) {
                      matchesStatus =
                          status == 'Completed' || status == 'Delivered';
                    }
                    if (_filterIndex == 5)
                      matchesStatus = status == 'Cancelled';

                    return matchesStatus && matchesPrice(o) && matchesSearch(o);
                  }).toList();

                  filtered.sort((a, b) {
                    final dateA = a.orderDate?.toDate() ?? DateTime.now();
                    final dateB = b.orderDate?.toDate() ?? DateTime.now();
                    return _sortOrder == 'latest'
                        ? dateB.compareTo(dateA)
                        : dateA.compareTo(dateB);
                  });

                  return Column(
                    children: [
                      chipsRow,
                      12.height,
                      if (filtered.isEmpty)
                        Expanded(
                          child: Center(
                              child: Text('No orders found',
                                  style: GoogleFonts.workSans(
                                      color: sh_textColorSecondary))),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: spacing_standard_new),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => 12.height,
                            itemBuilder: (_, i) =>
                                _OrderCard(item: filtered[i]),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
                child: _OrderFilterDrawer(
                  price: _priceRange,
                  minPrice: _orderMinPrice,
                  maxPrice: _orderMaxPrice,
                  sortOrder: _sortOrder,
                  onPriceChanged: (v) {
                    setInnerState(() => _priceRange = v);
                    this.setState(() => _priceRange = v);
                  },
                  onSortChanged: (v) {
                    setInnerState(() => _sortOrder = v);
                    this.setState(() => _sortOrder = v);
                  },
                  onApply: () => Navigator.of(context).maybePop(),
                  onClear: () {
                    this.setState(() {
                      _priceRange = const RangeValues(0, 1000);
                      _sortOrder = 'latest';
                      _filterIndex = 0;
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
}

class _OrderCard extends StatelessWidget {
  final AmOrder item;
  const _OrderCard({Key? key, required this.item}) : super(key: key);

  Widget _typeBadge(String type) {
    final t = type.toLowerCase().trim();
    if (t == 'b2b') {
      return _Badge(
        label: 'B2B',
        bgColor: null,
        gradient:
            const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd]),
        textColor: sh_white,
      );
    }
    if (t == 'customer') {
      return _Badge(
        label: 'Customer',
        bgColor: sh_view_color,
        gradient: null,
        textColor: sh_textColorPrimary,
      );
    }
    return _Badge(
      label: 'Guest',
      bgColor: sh_colorPrimary,
      gradient: null,
      textColor: sh_white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(item.deliveryStatus ?? 'Pending');
    final userId = (item.userId ?? '').toString();
    final isGuestId = userId.startsWith('guest_') || userId.trim().isEmpty;
    final existingType = (item.customerType ?? '').toString().trim();
    final contactEmail =
        (item.contactEmail ?? '').toString().trim().toLowerCase();

    return InkWell(
      onTap: () {
        OrderDetailsScreen(order: item).launch(context);
      },
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Padding(
          padding: const EdgeInsets.all(spacing_standard_new),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('#${item.orderCode ?? item.id}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.workSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0A2F1B)))),
                    ],
                  ),
                ),
                12.width,
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                          colors: [sh_gradient_1st, sh_gradient_2nd],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight)
                      .createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: Text('£${(item.grandTotal ?? 0.0).toStringAsFixed(2)}',
                      style: GoogleFonts.workSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ],
            ),
            6.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                      item.shippingAddress?.full_name ?? 'Unknown Customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: sh_textColorSecondary)),
                ),
                8.width,
                if (existingType.isNotEmpty)
                  _typeBadge(existingType)
                else if (isGuestId && contactEmail.isNotEmpty)
                  FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .where('email', isEqualTo: contactEmail)
                        .limit(1)
                        .get(),
                    builder: (context, snap) {
                      if (snap.hasData &&
                          (snap.data?.docs.isNotEmpty ?? false)) {
                        final data = snap.data!.docs.first.data();
                        final businessName =
                            (data['business_name'] ?? '').toString().trim();
                        return _typeBadge(
                            businessName.isNotEmpty ? 'b2b' : 'customer');
                      }
                      return _typeBadge('guest');
                    },
                  )
                else if (isGuestId)
                  _typeBadge('guest')
                else
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('Users')
                        .doc(userId)
                        .get(),
                    builder: (context, snap) {
                      if (snap.hasData &&
                          snap.data != null &&
                          snap.data!.exists) {
                        final data = snap.data!.data() ?? {};
                        final businessName =
                            (data['business_name'] ?? '').toString().trim();
                        return _typeBadge(
                            businessName.isNotEmpty ? 'b2b' : 'customer');
                      }
                      return _typeBadge('customer');
                    },
                  ),
              ],
            ),
            8.height,
            Row(
              children: [
                Text(_formatDate(item.orderDate?.toDate() ?? DateTime.now()),
                    style: GoogleFonts.workSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: sh_textColorSecondary)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: statusStyle.bg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(statusStyle.label,
                      style: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusStyle.fg)),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    if (status == 'Completed' || status == 'Delivered')
      return _StatusStyle(
          'Completed', const Color(0xFF2F8F46), const Color(0x332F8F46));
    if (status == 'Shipped')
      return _StatusStyle(
          'Shipped', const Color(0xFF7B68EE), const Color(0x337B68EE));
    if (status == 'Processing')
      return _StatusStyle(
          'Processing', const Color(0xFF4A90E2), const Color(0x334A90E2));
    if (status == 'Cancelled')
      return _StatusStyle(
          'Cancelled', Colors.red, Colors.red.withValues(alpha: 0.2));
    return _StatusStyle(
        status, const Color(0xFF956A24), const Color(0x33956A24));
  }

  String _formatDate(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';
  String _month(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final LinearGradient? gradient;
  final Color textColor;
  const _Badge(
      {Key? key,
      required this.label,
      this.bgColor,
      this.gradient,
      required this.textColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: bgColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.workSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _StatusStyle {
  final String label;
  final Color fg;
  final Color bg;
  _StatusStyle(this.label, this.fg, this.bg);
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: selected ? null : Colors.white,
          gradient: selected
              ? const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd])
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? defaultBoxShadow(shadowColor: appShadowColor)
              : defaultBoxShadow(shadowColor: appShadowColor)),
      child: Text(label,
          style: GoogleFonts.workSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? sh_white : sh_textColorPrimary)),
    );
    return GestureDetector(onTap: onTap, child: base);
  }
}

class _OrderFilterDrawer extends StatelessWidget {
  final RangeValues price;
  final double minPrice;
  final double maxPrice;
  final String sortOrder;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  const _OrderFilterDrawer(
      {Key? key,
      required this.price,
      required this.minPrice,
      required this.maxPrice,
      required this.sortOrder,
      required this.onPriceChanged,
      required this.onSortChanged,
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
                  child: Text('Filter Orders',
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
            Text('Price Range',
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
                min: minPrice,
                max: maxPrice <= minPrice ? minPrice + 1 : maxPrice,
                activeColor: sh_colorPrimary,
                inactiveColor: sh_view_color,
                onChanged: onPriceChanged),
            16.height,
            Text('Sort By Date',
                style: GoogleFonts.workSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: sh_colorPrimary)),
            12.height,
            Row(children: [
              Expanded(
                child: _FilterChip(
                    label: 'Latest (ASC)',
                    selected: sortOrder == 'latest',
                    onTap: () => onSortChanged('latest')),
              ),
              8.width,
              Expanded(
                child: _FilterChip(
                    label: 'Oldest (DESC)',
                    selected: sortOrder == 'oldest',
                    onTap: () => onSortChanged('oldest')),
              ),
            ]),
            24.height,
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
