import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';

class AddShipmentScreen extends StatefulWidget {
  const AddShipmentScreen({Key? key}) : super(key: key);
  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  int _currentTab = 2;
  final _poCtrl = TextEditingController();
  final _warehouse = ValueNotifier<String>('WH-A');
  final _status = ValueNotifier<String>('Shipment');
  DateTime? _expected;
  DateTime? _delivery;

  final List<_ShipProduct> _products = [];

  Future<void> _openProductPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              16.height,
              Text('Select Product',
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: sh_colorPrimary)),
              12.height,
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('Products')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error loading products',
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: sh_textColorSecondary)));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = (snapshot.data?.docs ?? []).where((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final status = (data['product_status'] ?? 'active')
                          .toString()
                          .toLowerCase();
                      return status != 'delete';
                    }).toList();
                    if (docs.isEmpty) {
                      return Center(
                          child: Text('No products found',
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: sh_textColorSecondary)));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: spacing_standard_new),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => 8.height,
                      itemBuilder: (_, i) {
                        final d = docs[i];
                        final data = d.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? '').toString();
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _products.add(_ShipProduct(
                                  productId: d.id, name: name, qty: 1));
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(spacing_standard_new),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: defaultBoxShadow(
                                    shadowColor: appShadowColor)),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(name,
                                        style: GoogleFonts.workSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: sh_textColorPrimary))),
                                const Icon(Icons.add_circle_outline,
                                    color: sh_colorPrimary),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              16.height,
            ],
          ),
        );
      },
    );
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
                  Text('Add Shipment',
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Purchase Order Number',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sh_colorPrimary)),
                    8.height,
                    _InputField(controller: _poCtrl, hint: 'PO-5002'),
                    12.height,
                    Text('Expected Delivery Date',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sh_colorPrimary)),
                    8.height,
                    _DateField(
                        label: 'Select date',
                        value: _expected,
                        onPick: (d) => setState(() => _expected = d)),
                    12.height,
                    Text('Warehouse',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sh_colorPrimary)),
                    8.height,
                    _DropdownField(
                        valueNotifier: _warehouse,
                        items: const ['WH-A', 'WH-B', 'WH-C']),
                    12.height,
                    Text('Delivery Date',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sh_colorPrimary)),
                    8.height,
                    _DateField(
                        label: 'Select date',
                        value: _delivery,
                        onPick: (d) => setState(() => _delivery = d)),
                    16.height,
                    Text('Products in Shipment',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sh_colorPrimary)),
                    12.height,
                    Column(
                        children: _products
                            .map((p) => _ProductRow(
                                  p: p,
                                  onIncrease: () => setState(() => p.qty += 1),
                                  onDecrease: () => setState(() {
                                    if (p.qty > 1) p.qty -= 1;
                                  }),
                                  onRemove: () =>
                                      setState(() => _products.remove(p)),
                                ))
                            .toList()),
                    8.height,
                    GestureDetector(
                      onTap: () {
                        _openProductPicker();
                      },
                      child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [sh_gradient_1st, sh_gradient_2nd]),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: defaultBoxShadow(
                                  shadowColor: appShadowColor)),
                          child: Text('+ Add Product',
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sh_white))),
                    ),
                    16.height,
                    Text('Status',
                        style: GoogleFonts.workSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: sh_colorPrimary)),
                    8.height,
                    _DropdownField(
                        valueNotifier: _status,
                        items: const ['Shipment', 'Delivered', 'Processing']),
                    20.height,
                    Row(children: [
                      Expanded(
                          child: _PillButton(
                              label: 'Save',
                              bgColor: sh_colorPrimary,
                              onTap: () async {
                                final po = _poCtrl.text.trim();
                                if (po.isEmpty) {
                                  toast('Enter Purchase Order Number');
                                  return;
                                }
                                if (_expected == null) {
                                  toast('Select Expected Delivery Date');
                                  return;
                                }
                                if (_delivery == null) {
                                  toast('Select Delivery Date');
                                  return;
                                }
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  toast('Please login to save shipment');
                                  return;
                                }
                                final products = _products
                                    .map((p) => {
                                          'product_id': p.productId,
                                          'name': p.name,
                                          'qty': p.qty,
                                        })
                                    .toList();
                                final productsCount = _products.fold<int>(
                                    0, (sum, p) => sum + p.qty);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('Shipments')
                                      .add({
                                    'po': po,
                                    'expected': Timestamp.fromDate(_expected!),
                                    'delivery': Timestamp.fromDate(_delivery!),
                                    'warehouse': _warehouse.value,
                                    'status': _status.value,
                                    'products': products,
                                    'productsCount': productsCount,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'createdBy': user.uid,
                                  });
                                  toast('Shipment saved successfully');
                                  finish(context);
                                } catch (e) {
                                  toast('Error saving shipment: $e');
                                }
                              })),
                      12.width,
                      Expanded(
                          child: _PillButton(
                              label: 'Cancel',
                              gradient: const LinearGradient(
                                  colors: [sh_gradient_1st, sh_gradient_2nd]),
                              onTap: () => finish(context))),
                    ]),
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _InputField({Key? key, required this.controller, required this.hint})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: sh_textColorPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: sh_textColorSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  const _DateField(
      {Key? key,
      required this.label,
      required this.value,
      required this.onPick})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller:
          TextEditingController(text: value == null ? '' : _fmt(value!)),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 2),
            lastDate: DateTime(now.year + 3));
        if (picked != null) onPick(picked);
      },
      style: GoogleFonts.workSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: sh_textColorPrimary),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.workSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: sh_textColorSecondary),
        suffixIcon:
            const Icon(Icons.calendar_today, color: sh_textColorSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
            borderSide: BorderSide(color: sh_view_color)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  String _fmt(DateTime d) => '${_month(d.month)} ${d.day}, ${d.year}';
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

class _DropdownField extends StatelessWidget {
  final ValueNotifier<String> valueNotifier;
  final List<String> items;
  const _DropdownField(
      {Key? key, required this.valueNotifier, required this.items})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: valueNotifier,
      builder: (_, value, __) {
        return DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e,
                      style: GoogleFonts.workSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: sh_textColorPrimary))))
              .toList(),
          onChanged: (v) => valueNotifier.value = v ?? value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: sh_view_color)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.0),
                borderSide: BorderSide(color: sh_view_color)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        );
      },
    );
  }
}

class _ShipProduct {
  final String productId;
  final String name;
  int qty;
  _ShipProduct(
      {required this.productId, required this.name, required this.qty});
}

class _ProductRow extends StatelessWidget {
  final _ShipProduct p;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  const _ProductRow(
      {Key? key,
      required this.p,
      required this.onIncrease,
      required this.onDecrease,
      required this.onRemove})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: spacing_standard_new, vertical: 12),
        child: Row(children: [
          Expanded(
              child: Text(p.name,
                  style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorPrimary))),
          GestureDetector(
            onTap: onDecrease,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('-',
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorPrimary)),
            ),
          ),
          8.width,
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(8)),
            child: Text('${p.qty}',
                style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: sh_textColorPrimary)),
          ),
          8.width,
          GestureDetector(
            onTap: onIncrease,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('+',
                  style: GoogleFonts.workSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorPrimary)),
            ),
          ),
          12.width,
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
          )
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
  const _PillButton(
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
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: bgColor,
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
