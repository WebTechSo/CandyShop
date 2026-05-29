import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:american_sweets/screens/CustomerOrderHistoryScreen.dart';
import 'package:american_sweets/screens/CustomerEditScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String name;
  final String email;
  final String typeLabel;
  final int totalOrders;
  final List<CustomerOrder> orders;
  const CustomerDetailScreen(
      {Key? key,
      required this.name,
      required this.email,
      required this.typeLabel,
      required this.totalOrders,
      required this.orders})
      : super(key: key);
  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  int _currentTab = 4;
  late String _name;
  late String _email;
  late String _typeLabel;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _typeLabel = widget.typeLabel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: sh_background_color,
      body: SafeArea(
        child: Column(children: [
          8.height,
          ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                      colors: [sh_gradient_1st, sh_gradient_2nd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight)
                  .createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text(sh_app_name,
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white))),
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
                  Text('Customer Detail',
                      style: GoogleFonts.workSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: sh_colorPrimary)),
                  Stack(children: [
                    const Icon(Icons.notifications_none,
                        color: sh_colorPrimary),
                    Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle)))
                  ])
                ]),
          ),
          12.height,
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: spacing_standard_new),
              child: Column(children: [
                Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
                  child: Padding(
                    padding: const EdgeInsets.all(spacing_standard_new),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(_name,
                                    style: GoogleFonts.workSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: sh_textColorPrimary))),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF0A2F1B),
                                    borderRadius: BorderRadius.circular(18)),
                                child: Text(_typeLabel,
                                    style: GoogleFonts.workSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: sh_white)))
                          ]),
                          8.height,
                          Text('Email',
                              style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: sh_textColorSecondary)),
                          4.height,
                          Text(_email,
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sh_textColorPrimary)),
                          16.height,
                          Row(children: [
                            Expanded(
                                child: Text(
                                    'Order History (${widget.totalOrders})',
                                    style: GoogleFonts.workSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: sh_colorPrimary))),
                            GestureDetector(
                                onTap: () {
                                  CustomerOrderHistoryScreen(
                                          customerName: _name,
                                          customerEmail: _email)
                                      .launch(context);
                                },
                                child: Text('View ALL',
                                    style: GoogleFonts.workSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: sh_colorPrimary)))
                          ]),
                          12.height,
                          Column(
                              children: widget.orders
                                  .take(3)
                                  .map((o) => _OrderTile(item: o))
                                  .toList()),
                          16.height,
                          GestureDetector(
                            onTap: () {
                              CustomerOrderHistoryScreen(
                                      customerName: _name,
                                      customerEmail: _email,
                                      autoDownload: true)
                                  .launch(context);
                            },
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF0A2F1B),
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: defaultBoxShadow(
                                      shadowColor: appShadowColor)),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.download,
                                        color: Colors.white),
                                    8.width,
                                    Text('Download History',
                                        style: GoogleFonts.workSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: sh_white)),
                                  ]),
                            ),
                          ),
                        ]),
                  ),
                ),
                20.height,
                _PillButton(
                    label: 'Edit Customer',
                    gradient: const LinearGradient(
                        colors: [sh_gradient_1st, sh_gradient_2nd]),
                    onTap: () async {
                      final res = await CustomerEditScreen(
                              initialName: _name, initialEmail: _email)
                          .launch(context);
                      if (res is Map) {
                        setState(() {
                          _name = (res['name'] ?? _name).toString();
                          _email = (res['email'] ?? _email).toString();
                          final t = (res['user_type'] ?? res['role'] ?? '')
                              .toString();
                          if (t.isNotEmpty) {
                            if (t == 'b2b') _typeLabel = 'B2B';
                            if (t == 'guest') _typeLabel = 'Guest';
                            if (t == 'customer') _typeLabel = 'Customer';
                          }
                        });
                      }
                    }),
                24.height,
              ]),
            ),
          ),
        ]),
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
}

class CustomerOrder {
  final String id;
  final DateTime date;
  final double amount;
  const CustomerOrder(
      {required this.id, required this.date, required this.amount});
}

class _OrderTile extends StatelessWidget {
  final CustomerOrder item;
  const _OrderTile({Key? key, required this.item}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: spacing_standard_new, vertical: 12),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Order #${item.id}',
                    style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: sh_textColorPrimary)),
                4.height,
                Text(_formatDate(item.date),
                    style: GoogleFonts.workSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sh_textColorSecondary)),
              ])),
          ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                      colors: [sh_gradient_1st, sh_gradient_2nd],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight)
                  .createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: Text('£${item.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)))
        ]),
      ),
    );
  }

  String _formatDate(DateTime d) => '${_month(d.month)} ${d.day}/${d.year}';
  String _month(int m) => [
        '01',
        '02',
        '03',
        '04',
        '05',
        '06',
        '07',
        '08',
        '09',
        '10',
        '11',
        '12'
      ][m - 1];
}

class _PillButton extends StatelessWidget {
  final String label;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  const _PillButton(
      {Key? key, required this.label, required this.onTap, this.gradient})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Text(label,
            style: GoogleFonts.workSans(
                fontSize: 16, fontWeight: FontWeight.w700, color: sh_white)),
      ),
    );
  }
}
