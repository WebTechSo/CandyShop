import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/screens/AddShipmentScreen.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/OrderManagementScreen.dart';
import 'package:american_sweets/screens/ProductManagementScreen.dart';
import 'package:american_sweets/screens/CustomerManagementScreen.dart';

class ShipmentListScreen extends StatefulWidget {
  const ShipmentListScreen({Key? key}) : super(key: key);
  @override
  State<ShipmentListScreen> createState() => _ShipmentListScreenState();
}

class _ShipmentListScreenState extends State<ShipmentListScreen> {
  int _currentTab = 2;
  int _filterIndex = 0;

  Future<void> _openStatusEditor(QueryDocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final current = (data['status'] ?? 'Shipment').toString();
    final alreadyApplied = data['stock_applied'] == true;
    final productsRaw = data['products'];
    final List<_StockAdjustItem> adjustItems = [];
    if (productsRaw is List) {
      for (final e in productsRaw) {
        if (e is! Map) continue;
        final pid = (e['product_id'] ?? '').toString().trim();
        final name = (e['name'] ?? '').toString().trim();
        final qty = int.tryParse((e['qty'] ?? 0).toString()) ?? 0;
        if (pid.isEmpty) continue;
        adjustItems.add(_StockAdjustItem(
            productId: pid,
            name: name.isNotEmpty ? name : pid,
            qty: qty <= 0 ? 1 : qty));
      }
    }
    final statuses = const ['Shipment', 'Processing', 'Delivered'];
    String selected = statuses.contains(current) ? current : 'Shipment';
    bool adjustStock = false;
    String adjustMode = 'Add';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Padding(
            padding: EdgeInsets.only(
              left: spacing_standard_new,
              right: spacing_standard_new,
              top: spacing_standard_new,
              bottom: MediaQuery.of(context).viewInsets.bottom +
                  spacing_standard_new,
            ),
            child: StatefulBuilder(builder: (context, setState) {
              final canRemove = alreadyApplied;
              final modes = canRemove ? const ['Add', 'Remove'] : const ['Add'];
              if (!modes.contains(adjustMode)) adjustMode = 'Add';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: sh_view_color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  16.height,
                  Text('Shipment Status',
                      style: GoogleFonts.workSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: sh_colorPrimary)),
                  12.height,
                  DropdownButtonFormField<String>(
                    value: selected,
                    items: statuses
                        .map((e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e,
                                style: GoogleFonts.workSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: sh_textColorPrimary))))
                        .toList(),
                    onChanged: (v) => setState(() => selected = v ?? selected),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                          borderSide: BorderSide(color: sh_view_color)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                  12.height,
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: sh_view_color, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: adjustStock,
                                      activeColor: sh_colorPrimary,
                                      onChanged: (v) => setState(
                                          () => adjustStock = v == true),
                                    ),
                                    Expanded(
                                      child: Text('Adjust Stock',
                                          style: GoogleFonts.workSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: sh_textColorPrimary)),
                                    ),
                                  ],
                                ),
                                if (adjustStock) ...[
                                  8.height,
                                  if (modes.length > 1)
                                    DropdownButtonFormField<String>(
                                      value: adjustMode,
                                      items: modes
                                          .map((e) => DropdownMenuItem<String>(
                                              value: e,
                                              child: Text(e,
                                                  style: GoogleFonts.workSans(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          sh_textColorPrimary))))
                                          .toList(),
                                      onChanged: (v) => setState(
                                          () => adjustMode = v ?? adjustMode),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            borderSide: BorderSide(
                                                color: sh_view_color)),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                            borderSide: BorderSide(
                                                color: sh_view_color)),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                      ),
                                    )
                                  else
                                    Text('Mode: Add',
                                        style: GoogleFonts.workSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: sh_textColorSecondary)),
                                  12.height,
                                  if (adjustItems.isEmpty)
                                    Text('No products in this shipment',
                                        style: GoogleFonts.workSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: sh_textColorSecondary))
                                  else
                                    Column(
                                      children: adjustItems
                                          .map((p) => _StockAdjustRow(
                                                p: p,
                                                onIncrease: () => setState(() {
                                                  p.qty += 1;
                                                }),
                                                onDecrease: () => setState(() {
                                                  if (p.qty > 1) p.qty -= 1;
                                                }),
                                              ))
                                          .toList(),
                                    ),
                                  if (!alreadyApplied &&
                                      selected != 'Delivered')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Tip: stock adjustment is usually done when status is Delivered.',
                                        style: GoogleFonts.workSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: sh_textColorSecondary),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  16.height,
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              await _applyShipmentStatusChange(
                                doc.reference,
                                selected,
                                adjustStock: adjustStock,
                                adjustMode: adjustMode,
                                adjustItems: adjustItems,
                              );
                              if (mounted) Navigator.of(context).pop();
                            } catch (e) {
                              toast(e.toString());
                            }
                          },
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [sh_gradient_1st, sh_gradient_2nd]),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow:
                                  defaultBoxShadow(shadowColor: appShadowColor),
                            ),
                            child: Text('Save',
                                style: GoogleFonts.workSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: sh_white)),
                          ),
                        ),
                      ),
                      12.width,
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              border:
                                  Border.all(color: sh_view_color, width: 1),
                            ),
                            child: Text('Cancel',
                                style: GoogleFonts.workSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: sh_textColorPrimary)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Future<void> _applyShipmentStatusChange(
      DocumentReference shipmentRef, String newStatus,
      {bool adjustStock = false,
      String adjustMode = 'Add',
      List<_StockAdjustItem>? adjustItems}) async {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(shipmentRef);
      if (!snap.exists) throw Exception('Shipment not found');
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final alreadyApplied = data['stock_applied'] == true;
      final productsRaw = data['products'];

      final bool markDelivered = newStatus == 'Delivered' && !alreadyApplied;
      final List<_StockAdjustItem> items = adjustItems ?? <_StockAdjustItem>[];

      if (markDelivered) {
        final List<Map<String, dynamic>> toApply = [];
        if (adjustStock) {
          if (adjustMode == 'Remove') {
            throw Exception('Use Add when marking Delivered');
          }
          for (final p in items) {
            if (p.qty <= 0) continue;
            toApply.add({'product_id': p.productId, 'qty': p.qty});
          }
        } else {
          final products = productsRaw is List ? productsRaw : const [];
          for (final e in products) {
            if (e is! Map) continue;
            final pid = (e['product_id'] ?? '').toString().trim();
            final qty = int.tryParse((e['qty'] ?? 0).toString()) ?? 0;
            if (pid.isEmpty || qty <= 0) continue;
            toApply.add({'product_id': pid, 'qty': qty});
          }
        }

        for (final e in toApply) {
          final pid = (e['product_id'] ?? '').toString().trim();
          final qty = int.tryParse((e['qty'] ?? 0).toString()) ?? 0;
          if (pid.isEmpty || qty <= 0) continue;
          final prodRef =
              FirebaseFirestore.instance.collection('Products').doc(pid);
          tx.update(prodRef, {
            'available_quantity': FieldValue.increment(qty),
          });
        }

        tx.update(shipmentRef, {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
          'stock_applied': true,
          'stock_applied_at': FieldValue.serverTimestamp(),
          if (adjustStock) 'stock_applied_items': toApply,
        });
      } else {
        final Map<String, dynamic> updates = {
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (adjustStock && items.isNotEmpty) {
          final int sign = adjustMode == 'Remove' ? -1 : 1;
          final List<Map<String, dynamic>> adj = [];
          for (final p in items) {
            if (p.qty <= 0) continue;
            adj.add({'product_id': p.productId, 'qty': p.qty});
            final prodRef = FirebaseFirestore.instance
                .collection('Products')
                .doc(p.productId);
            tx.update(prodRef, {
              'available_quantity': FieldValue.increment(sign * p.qty),
            });
          }
          if (adj.isNotEmpty) {
            updates['last_stock_adjustment_at'] = FieldValue.serverTimestamp();
            updates['stock_adjustments'] = FieldValue.arrayUnion([
              {
                'at': Timestamp.now(),
                'mode': adjustMode,
                'items': adj,
              }
            ]);
          }
        }
        tx.update(shipmentRef, updates);
      }
    });
    toast('Shipment updated');
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
                  Text('Purchase Shipment',
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
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: spacing_standard_new),
            child: Row(children: [
              _FilterChip(
                  label: 'All',
                  selected: _filterIndex == 0,
                  onTap: () => setState(() => _filterIndex = 0)),
              8.width,
              _FilterChip(
                  label: 'Shipment',
                  selected: _filterIndex == 1,
                  onTap: () => setState(() => _filterIndex = 1)),
              8.width,
              _FilterChip(
                  label: 'Processing',
                  selected: _filterIndex == 2,
                  onTap: () => setState(() => _filterIndex = 2)),
              8.width,
              _FilterChip(
                  label: 'Delivered',
                  selected: _filterIndex == 3,
                  onTap: () => setState(() => _filterIndex = 3)),
              const Spacer(),
              const Icon(Icons.filter_alt_outlined,
                  color: sh_textColorSecondary),
              6.width,
              Text('Filters',
                  style: GoogleFonts.workSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: sh_textColorSecondary)),
            ]),
          ),
          12.height,
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Shipments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading shipments'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                final entries = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final po = (data['po'] ?? '').toString();
                  final expectedTs = data['expected'];
                  final deliveryTs = data['delivery'];
                  final expected = expectedTs is Timestamp
                      ? expectedTs.toDate()
                      : DateTime.now();
                  final delivery = deliveryTs is Timestamp
                      ? deliveryTs.toDate()
                      : DateTime.now();
                  final warehouse = (data['warehouse'] ?? '').toString();
                  final statusStr = (data['status'] ?? 'Shipment').toString();
                  final status = _statusFromString(statusStr);
                  int productsCount = data['productsCount'] is int
                      ? data['productsCount'] as int
                      : 0;
                  if (productsCount == 0 && data['products'] is List) {
                    final list = data['products'] as List;
                    for (var e in list) {
                      if (e is Map && e['qty'] is int)
                        productsCount += e['qty'] as int;
                    }
                  }
                  return _ShipmentEntry(
                    doc: d as QueryDocumentSnapshot,
                    shipment: _Shipment(
                        po: po,
                        expected: expected,
                        warehouse: warehouse,
                        delivery: delivery,
                        productsCount: productsCount,
                        status: status),
                  );
                }).toList();
                final filtered = entries.where((e) {
                  if (_filterIndex == 0) return true;
                  if (_filterIndex == 1)
                    return e.shipment.status == _ShipStatus.shipment;
                  if (_filterIndex == 2)
                    return e.shipment.status == _ShipStatus.processing;
                  if (_filterIndex == 3)
                    return e.shipment.status == _ShipStatus.delivered;
                  return true;
                }).toList();
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: spacing_standard_new),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => 12.height,
                  itemBuilder: (_, i) {
                    if (i == filtered.length) {
                      return GestureDetector(
                        onTap: () {
                          const AddShipmentScreen().launch(context);
                        },
                        child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [sh_gradient_1st, sh_gradient_2nd]),
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: defaultBoxShadow(
                                    shadowColor: appShadowColor)),
                            child: Text('+ Add Shipment',
                                style: GoogleFonts.workSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: sh_white))),
                      );
                    }
                    final entry = filtered[i];
                    final s = entry.shipment;
                    final st = _statusStyle(s.status);
                    return GestureDetector(
                      onTap: () => _openStatusEditor(entry.doc),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow:
                                defaultBoxShadow(shadowColor: appShadowColor)),
                        child: Padding(
                          padding: const EdgeInsets.all(spacing_standard_new),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: Text('PO: ${s.po}',
                                          style: GoogleFonts.workSans(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: sh_textColorPrimary))),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                          color: st.bg,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text(st.label,
                                          style: GoogleFonts.workSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: st.fg)))
                                ]),
                                8.height,
                                Row(children: [
                                  Expanded(
                                      child: Text(
                                          'Expected: ${_fmt(s.expected)}',
                                          style: GoogleFonts.workSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: sh_textColorSecondary))),
                                  Text('Delivery: ${_fmt(s.delivery)}',
                                      style: GoogleFonts.workSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: sh_textColorSecondary)),
                                ]),
                                6.height,
                                Row(children: [
                                  Text('Warehouse: ${s.warehouse}',
                                      style: GoogleFonts.workSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: sh_textColorPrimary)),
                                  const Spacer(),
                                  Text('Items: ${s.productsCount}',
                                      style: GoogleFonts.workSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: sh_textColorPrimary))
                                ])
                              ]),
                        ),
                      ),
                    );
                  },
                );
              },
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

enum _ShipStatus { shipment, delivered, processing }

_ShipStatus _statusFromString(String s) {
  final v = s.toLowerCase();
  if (v == 'delivered') return _ShipStatus.delivered;
  if (v == 'processing') return _ShipStatus.processing;
  return _ShipStatus.shipment;
}

class _Shipment {
  final String po;
  final DateTime expected;
  final String warehouse;
  final DateTime delivery;
  final int productsCount;
  final _ShipStatus status;
  _Shipment(
      {required this.po,
      required this.expected,
      required this.warehouse,
      required this.delivery,
      required this.productsCount,
      required this.status});
}

class _ShipmentEntry {
  final QueryDocumentSnapshot doc;
  final _Shipment shipment;
  _ShipmentEntry({required this.doc, required this.shipment});
}

class _StockAdjustItem {
  final String productId;
  final String name;
  int qty;
  _StockAdjustItem(
      {required this.productId, required this.name, required this.qty});
}

class _StockAdjustRow extends StatelessWidget {
  final _StockAdjustItem p;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  const _StockAdjustRow(
      {Key? key,
      required this.p,
      required this.onIncrease,
      required this.onDecrease})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sh_view_color, width: 1)),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: spacing_standard_new, vertical: 10),
        child: Row(children: [
          Expanded(
              child: Text(p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.workSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: sh_textColorPrimary))),
          GestureDetector(
            onTap: onDecrease,
            child: Container(
              width: 34,
              height: 34,
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
            width: 40,
            height: 34,
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
              width: 34,
              height: 34,
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
        ]),
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

class _StatusStyle {
  final String label;
  final Color fg;
  final Color bg;
  const _StatusStyle(this.label, this.fg, this.bg);
}

_StatusStyle _statusStyle(_ShipStatus s) {
  if (s == _ShipStatus.delivered)
    return const _StatusStyle(
        'Delivered', Color(0xFF2F8F46), Color(0x332F8F46));
  if (s == _ShipStatus.processing)
    return const _StatusStyle(
        'Processing', Color(0xFF4A90E2), Color(0x334A90E2));
  return const _StatusStyle('Shipment', Color(0xFF956A24), Color(0x33956A24));
}
