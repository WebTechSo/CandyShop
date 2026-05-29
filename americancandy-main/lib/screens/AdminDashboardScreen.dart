// lib/screens/AdminDashboardScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/AddProductScreen.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';
import 'package:american_sweets/screens/ShipmentListScreen.dart';
import 'package:american_sweets/screens/CategoryManagementScreen.dart';
import 'package:american_sweets/screens/BrandManagementScreen.dart';
import 'package:american_sweets/screens/PaymentSetupScreen.dart';
import 'package:american_sweets/screens/AdminSettingScreen.dart';
import 'package:american_sweets/screens/AmAdminLoginScreen.dart';
import 'package:american_sweets/data/services/order_service.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/utils/AmNotificationBell.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 1;
  final OrderService _orderService = OrderService();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final tileW = (w - (spacing_standard_new * 3)) / 2;

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
                  Icon(Icons.folder_open, color: sh_colorPrimary),
                  Text('Admin Dashboard',
                      style: GoogleFonts.workSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: sh_colorPrimary)),
                  AmNotificationBell(iconColor: sh_colorPrimary),
                ],
              ),
            ),
            12.height,
            Expanded(
              child: StreamBuilder<List<AmOrder>>(
                stream: _orderService.getAllOrders(),
                builder: (context, snapshot) {
                  // Calculate stats
                  double totalSales = 0.0;
                  int pendingOrders = 0;
                  int shippedOrders = 0;
                  int canceledOrders = 0;

                  // Chart Data
                  List<double> chartData = List.filled(7, 0.0);
                  List<String> dayLabels = List.filled(7, '');
                  final now = DateTime.now();

                  // Initialize labels
                  for (int i = 6; i >= 0; i--) {
                    final d = now.subtract(Duration(days: i));
                    dayLabels[6 - i] = DateFormat('E').format(d).toUpperCase();
                  }

                  if (snapshot.hasData) {
                    final orders = snapshot.data!;
                    final Map<String, int> dailyCounts = {};

                    // Initialize counts for last 7 days
                    for (int i = 6; i >= 0; i--) {
                      final d = now.subtract(Duration(days: i));
                      final key = DateFormat('yyyy-MM-dd').format(d);
                      dailyCounts[key] = 0;
                    }

                    for (var o in orders) {
                      final status = o.deliveryStatus ?? 'Pending';

                      // Count Sales (excluding Cancelled)
                      if (status != 'Cancelled') {
                        totalSales += (o.grandTotal ?? 0.0);
                      }

                      // Count Statuses
                      if (status == 'Pending') {
                        pendingOrders++;
                      } else if (status == 'Shipped') {
                        shippedOrders++;
                      } else if (status == 'Cancelled') {
                        canceledOrders++;
                      }

                      // Count for Chart
                      if (o.orderDate != null) {
                        final d = o.orderDate!.toDate();
                        final key = DateFormat('yyyy-MM-dd').format(d);
                        if (dailyCounts.containsKey(key)) {
                          dailyCounts[key] = dailyCounts[key]! + 1;
                        }
                      }
                    }

                    // Fill chart data
                    for (int i = 0; i < 7; i++) {
                      final d = now.subtract(Duration(days: 6 - i));
                      final key = DateFormat('yyyy-MM-dd').format(d);
                      chartData[i] = (dailyCounts[key] ?? 0).toDouble();
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: spacing_standard_new),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: defaultBoxShadow(
                                  shadowColor: appShadowColor)),
                          child: Padding(
                            padding: const EdgeInsets.all(spacing_standard_new),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Sales',
                                            style: GoogleFonts.workSans(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: sh_textColorSecondary)),
                                        6.height,
                                        Text(
                                            '£${totalSales.toStringAsFixed(2)}',
                                            style: GoogleFonts.workSans(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    const Color(0xFF0A2F1B))),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [
                                          sh_gradient_1st,
                                          sh_gradient_2nd
                                        ]),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                          '+15%', // Placeholder for growth
                                          style: GoogleFonts.workSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: sh_white)),
                                    ),
                                  ],
                                ),
                                16.height,
                                SizedBox(
                                  height: 160,
                                  width: double.infinity,
                                  child: CustomPaint(
                                    painter: _SalesAreaChartPainter(chartData),
                                  ),
                                ),
                                8.height,
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: dayLabels
                                      .map((l) => _DayLabel(l))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        16.height,
                        Wrap(
                          spacing: spacing_standard_new,
                          runSpacing: spacing_standard_new,
                          children: [
                            _KpiTile(
                                width: tileW,
                                title: 'Total Sales',
                                value:
                                    '£${totalSales.toStringAsFixed(0)}', // Rounded for tile
                                subtitle: 'Lifetime',
                                onTap: () {
                                  OrderManagementScreen(initialFilter: 0)
                                      .launch(context);
                                }), // Changed from "This Week" as we are showing total
                            _KpiTile(
                                width: tileW,
                                title: 'Pending Orders',
                                value: '$pendingOrders',
                                onTap: () {
                                  OrderManagementScreen(initialFilter: 1)
                                      .launch(context);
                                }),
                            _KpiTile(
                                width: tileW,
                                title: 'Shipped Orders',
                                value: '$shippedOrders',
                                onTap: () {
                                  OrderManagementScreen(initialFilter: 3)
                                      .launch(context);
                                }),
                            _KpiTile(
                                width: tileW,
                                title: 'Canceled Orders',
                                value: '$canceledOrders',
                                onTap: () {
                                  OrderManagementScreen(initialFilter: 5)
                                      .launch(context);
                                }),
                          ],
                        ),
                        20.height,
                        Row(
                          children: [
                            Expanded(
                              child: _PillButton(
                                label: 'Add Product',
                                bgColor: sh_colorPrimary,
                                onTap: () {
                                  const AddProductScreen().launch(context);
                                },
                              ),
                            ),
                            12.width,
                            Expanded(
                              child: _PillButton(
                                label: 'View Orders',
                                gradient: const LinearGradient(
                                    colors: [sh_gradient_1st, sh_gradient_2nd]),
                                onTap: () {
                                  OrderManagementScreen().launch(context);
                                },
                              ),
                            ),
                          ],
                        ),
                        12.height,
                        _PillButton(
                          label: 'Manage Customers',
                          gradient: const LinearGradient(
                              colors: [sh_gradient_1st, sh_gradient_2nd]),
                          onTap: () {
                            const CustomerManagementScreen().launch(context);
                          },
                          fullWidth: true,
                        ),
                        12.height,
                        _PillButton(
                          label: 'Purchase Shipment',
                          bgColor: sh_colorPrimary,
                          onTap: () {
                            const ShipmentListScreen().launch(context);
                          },
                          fullWidth: true,
                        ),
                        12.height,
                        Row(
                          children: [
                            Expanded(
                              child: _PillButton(
                                label: 'Manage Categories',
                                bgColor: sh_colorPrimary,
                                onTap: () {
                                  const CategoryManagementScreen()
                                      .launch(context);
                                },
                              ),
                            ),
                            12.width,
                            Expanded(
                              child: _PillButton(
                                label: 'Manage Brands',
                                bgColor: sh_colorPrimary,
                                onTap: () {
                                  const BrandManagementScreen().launch(context);
                                },
                              ),
                            ),
                          ],
                        ),
                        12.height,
                        Row(
                          children: [
                            Expanded(
                              child: _PillButton(
                                label: 'Payment Setup',
                                bgColor: sh_colorPrimary,
                                onTap: () {
                                  const PaymentSetupScreen().launch(context);
                                },
                              ),
                            ),
                            12.width,
                            Expanded(
                              child: _PillButton(
                                label: 'Admin Settings',
                                bgColor: sh_colorPrimary,
                                onTap: () {
                                  const AdminSettingScreen().launch(context);
                                },
                              ),
                            ),
                          ],
                        ),
                        24.height,
                        _PillButton(
                          label: 'Logout',
                          bgColor: Colors.redAccent,
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            Get.offAll(() => AmAdminLoginScreen());
                          },
                          fullWidth: true,
                        ),
                        24.height,
                      ],
                    ),
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
}

class _DayLabel extends StatelessWidget {
  final String text;
  const _DayLabel(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.workSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: sh_textColorPrimary));
  }
}

class _KpiTile extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  const _KpiTile(
      {Key? key,
      required this.width,
      required this.title,
      required this.value,
      this.subtitle,
      this.onTap})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(spacing_standard_new),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.workSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: sh_textColorSecondary)),
          8.height,
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
                    colors: [sh_gradient_1st, sh_gradient_2nd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: Text(value,
                style: GoogleFonts.workSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          if (subtitle != null) ...[
            6.height,
            Text(subtitle!,
                style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sh_textColorSecondary)),
          ],
        ]),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color? bgColor;
  final LinearGradient? gradient;
  final VoidCallback onTap;
  final bool fullWidth;
  const _PillButton(
      {Key? key,
      required this.label,
      required this.onTap,
      this.bgColor,
      this.gradient,
      this.fullWidth = false})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final child = Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: defaultBoxShadow(shadowColor: appShadowColor),
      ),
      child: Text(label,
          style: GoogleFonts.workSans(
              fontSize: 16, fontWeight: FontWeight.w700, color: sh_white)),
    );
    return fullWidth
        ? GestureDetector(onTap: onTap, child: child)
        : GestureDetector(onTap: onTap, child: child);
  }
}

class _SalesAreaChartPainter extends CustomPainter {
  final List<double> data;
  _SalesAreaChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final minY = data.reduce((a, b) => a < b ? a : b);
    final dx = size.width / (data.length - 1);
    final padding = 8.0;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final norm = (data[i] - minY) / ((maxY - minY) == 0 ? 1 : (maxY - minY));
      final y = size.height - padding - norm * (size.height - padding * 2);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height - padding)
      ..lineTo(points.first.dx, size.height - padding)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
              colors: [sh_gradient_2nd, sh_gradient_1st],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = sh_colorPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    // Draw values at points
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    for (int i = 0; i < points.length; i++) {
      final value = data[i].toInt().toString();
      textPainter.text = TextSpan(
        text: value,
        style: GoogleFonts.workSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: sh_textColorPrimary,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(points[i].dx - textPainter.width / 2,
            points[i].dy - textPainter.height - 4),
      );
    }

    final borderPaint = Paint()
      ..color = sh_colorPrimary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
