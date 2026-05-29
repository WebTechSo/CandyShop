import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/CustomerDetailScreen.dart';
import 'package:american_sweets/screens/CustomerRegisterScreen.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';

class CustomerB2BScreen extends StatefulWidget {
  const CustomerB2BScreen({Key? key}) : super(key: key);
  @override
  State<CustomerB2BScreen> createState() => _CustomerB2BScreenState();
}

class _CustomerB2BScreenState extends State<CustomerB2BScreen> {
  int _currentTab = 4;
  String _sortLabel = 'Sort by Total Orders';
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_Customer> _customers = [
    _Customer(name: "Bob's Candy Shop", email: 'contact@bobscandy.com', type: _CustType.b2b, totalOrders: 56),
    _Customer(name: 'Sweet Tooth Inc.', email: 'purchasing@sweettooth.com', type: _CustType.b2b, totalOrders: 124),
    _Customer(name: 'Diana Prince', email: 'diana.p@email.com', type: _CustType.b2b, totalOrders: 2),
    _Customer(name: 'Alice Johnson', email: 'alice.j@example.com', type: _CustType.b2b, totalOrders: 12),
  ];

  @override
  Widget build(BuildContext context) {
    List<_Customer> list = _customers.where((c) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) || c.email.toLowerCase().contains(q);
    }).toList();
    if (_sortLabel.contains('Total Orders')) {
      list.sort((a, b) => b.totalOrders.compareTo(a.totalOrders));
    } else {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    return Scaffold(
      backgroundColor: sh_background_color,
      body: SafeArea(
        child: Column(children: [
          8.height,
          ShaderMask(shaderCallback: (bounds) => const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd], begin: Alignment.centerLeft, end: Alignment.centerRight).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)), child: Text(sh_app_name, style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white))),
          12.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              InkWell(onTap: () => finish(context), child: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: defaultBoxShadow(shadowColor: appShadowColor)), child: const Icon(Icons.arrow_back))),
              Text('Customer', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w700, color: sh_colorPrimary)),
              Stack(children: [const Icon(Icons.notifications_none, color: sh_colorPrimary), Positioned(right: 0, top: 0, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)))])
            ]),
          ),
          12.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: sh_textColorPrimary),
              decoration: InputDecoration(
                hintText: 'Search customers...',
                hintStyle: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: sh_textColorSecondary),
                prefixIcon: const Icon(Icons.search, color: sh_textColorSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28.0), borderSide: BorderSide(color: sh_view_color)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28.0), borderSide: BorderSide(color: sh_view_color)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          12.height,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: Row(children: [
              _FixedPill(label: 'B2B'),
              8.width,
              _DropdownPill(
                label: _sortLabel,
                onTap: () async {
                  final choice = await showModalBottomSheet<String>(context: context, backgroundColor: Colors.transparent, builder: (_) {
                    return _BottomSheetWrap(children: [
                      _BottomSheetItem('Sort by Total Orders', onTap: () => finish(context, 'Sort by Total Orders')),
                      _BottomSheetItem('Sort by Name', onTap: () => finish(context, 'Sort by Name')),
                    ]);
                  });
                  if (choice != null) setState(() => _sortLabel = choice);
                },
              ),
            ]),
          ),
          12.height,
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: spacing_standard_new),
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => 12.height,
              itemBuilder: (_, i) {
                if (i == list.length) return _AddButton(label: '+ Add Customer', onTap: () { const CustomerRegisterScreen().launch(context); });
                final c = list[i];
                return InkWell(
                  onTap: () {
                    CustomerDetailScreen(
                      name: c.name,
                      email: c.email,
                      typeLabel: 'B2B',
                      totalOrders: c.totalOrders,
                      orders: [
                        CustomerOrder(id: 'AS-1024', date: DateTime(2025, 9, 16), amount: 45.50),
                        CustomerOrder(id: 'AS-1011', date: DateTime(2025, 9, 16), amount: 22.00),
                        CustomerOrder(id: 'AS-987', date: DateTime(2025, 9, 16), amount: 78.90),
                      ],
                    ).launch(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                    child: Padding(
                      padding: const EdgeInsets.all(spacing_standard_new),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: sh_textColorPrimary)),
                        6.height,
                        Text(c.email, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: sh_textColorSecondary)),
                        10.height,
                        Row(children: [
                          _Badge(label: 'B2B', gradient: const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd]), textColor: sh_white),
                          const Spacer(),
                          Text('Total Orders: ${c.totalOrders}', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: sh_textColorPrimary))
                        ])
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Products'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Customers'),
          ],
        ),
      ),
    );
  }
}

enum _CustType { b2b }

class _Customer {
  final String name;
  final String email;
  final _CustType type;
  final int totalOrders;
  _Customer({required this.name, required this.email, required this.type, required this.totalOrders});
}

class _FixedPill extends StatelessWidget {
  final String label;
  const _FixedPill({Key? key, required this.label}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd]), borderRadius: BorderRadius.circular(24), boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: sh_white)),
        6.width,
        const Icon(Icons.keyboard_arrow_down, color: sh_white)
      ]),
    );
  }
}

class _DropdownPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DropdownPill({Key? key, required this.label, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: sh_textColorPrimary)),
          6.width,
          const Icon(Icons.keyboard_arrow_down, color: sh_textColorPrimary)
        ]),
      ),
    );
  }
}

class _BottomSheetWrap extends StatelessWidget {
  final List<Widget> children;
  const _BottomSheetWrap({Key? key, required this.children}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: Padding(padding: const EdgeInsets.all(spacing_standard_new), child: Column(mainAxisSize: MainAxisSize.min, children: children)),
    );
  }
}

class _BottomSheetItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BottomSheetItem(this.label, {Key? key, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(label, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: sh_textColorPrimary)), onTap: onTap);
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color textColor;
  const _Badge({Key? key, required this.label, required this.gradient, required this.textColor}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({Key? key, required this.label, required this.onTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [sh_gradient_1st, sh_gradient_2nd]), borderRadius: BorderRadius.circular(32), boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Text(label, style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w700, color: sh_white)),
      ),
    );
  }
}
