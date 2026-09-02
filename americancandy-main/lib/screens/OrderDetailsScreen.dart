import 'package:flutter/material.dart';
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
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/data/services/order_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final AmOrder order;
  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);
  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  int _currentTab = 2;
  String _selectedStatus = 'Pending';
  final OrderService _orderService = OrderService();
  Future<List<AmOrderItem>>? _orderItemsFuture;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.deliveryStatus ?? 'Pending';
    // Ensure we have a valid status from the list
    if (!['Pending', 'Processing', 'Shipped', 'Completed', 'Cancelled']
        .contains(_selectedStatus)) {
      _selectedStatus = 'Pending';
    }
    _orderItemsFuture = _orderService.getOrderItems(widget.order.id!);
  }

  Future<void> _updateStatus() async {
    try {
      await _orderService.updateOrderStatus(widget.order.id!, _selectedStatus);
      toast('Order status updated to $_selectedStatus');
      finish(context);
    } catch (e) {
      toast('Failed to update status: $e');
    }
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
                      end: Alignment.centerRight)
                  .createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
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
                  Text('Order Details',
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
                ],
              ),
            ),
            12.height,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: spacing_standard_new),
                child: Column(
                  children: [
                    _CardSection(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                  'Order #${widget.order.orderCode ?? widget.order.id}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.workSans(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: sh_colorPrimary)),
                            ),
                          ]),
                          8.height,
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                    _formatDateTime(
                                        widget.order.orderDate?.toDate() ??
                                            DateTime.now()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.workSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: sh_textColorSecondary)),
                              ),
                              8.width,
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        sh_gradient_1st,
                                        sh_gradient_2nd
                                      ]),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                      widget.order.deliveryStatus ?? 'Pending',
                                      style: GoogleFonts.workSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: sh_white)))
                            ],
                          )
                        ])),
                    12.height,
                    _CardSection(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Customer Information',
                              style: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: sh_colorPrimary)),
                          8.height,
                          Text(
                              widget.order.shippingAddress?.full_name ??
                                  'Unknown',
                              style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sh_textColorPrimary)),
                          6.height,
                          Text(widget.order.shippingAddress?.phone ?? '',
                              style: GoogleFonts.workSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sh_textColorSecondary)),
                          4.height,
                          Text(
                              '${widget.order.shippingAddress?.address ?? ''}, ${widget.order.shippingAddress?.city ?? ''}, ${widget.order.shippingAddress?.state ?? ''} ${widget.order.shippingAddress?.zip_code ?? ''}',
                              style: GoogleFonts.workSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sh_textColorSecondary))
                        ])),
                    12.height,
                    _CardSection(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Ordered Products',
                              style: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: sh_colorPrimary)),
                          12.height,
                          FutureBuilder<List<AmOrderItem>>(
                            future: _orderItemsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Text('Error loading items');
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Text('No items found');
                              }
                              return Column(
                                children: snapshot.data!.map((item) {
                                  return Column(
                                    children: [
                                      _ProductRow(
                                        name: item.productName ?? 'Product',
                                        price: item.price ?? 0.0,
                                        qtyText:
                                            'Qty: ${item.quantity} x £${(item.price ?? 0).toStringAsFixed(2)}',
                                        imagePath: item.productImage ?? '',
                                      ),
                                      12.height,
                                    ],
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ])),
                    12.height,
                    _CardSection(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Payment & Totals',
                              style: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: sh_colorPrimary)),
                          12.height,
                          RichText(
                              text: TextSpan(children: [
                            TextSpan(
                                text: 'Payment Method: ',
                                style: GoogleFonts.workSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: sh_textColorSecondary)),
                            TextSpan(
                                text: widget.order.paymentType ?? 'Unknown',
                                style: GoogleFonts.workSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: sh_colorPrimary))
                          ])),
                          10.height,
                          FutureBuilder<List<AmOrderItem>>(
                            future: _orderItemsFuture,
                            builder: (context, snapshot) {
                              final shippingCost =
                                  (widget.order.shippingCost ?? 0.0);
                              final shippingMethod =
                                  (widget.order.shippingOption ?? '').trim();
                              final grandTotal =
                                  (widget.order.grandTotal ?? 0.0);

                              double itemsTotal = 0.0;
                              if (snapshot.hasData) {
                                for (final it in snapshot.data!) {
                                  final price = it.price ?? 0.0;
                                  final qty = it.quantity ?? 1;
                                  itemsTotal += (price * qty);
                                }
                              }

                              final storedItemsSubtotal =
                                  widget.order.itemsSubtotal;
                              final storedVatIncluded =
                                  widget.order.vatIncluded;
                              final storedVatAmount = widget.order.vatAmount;

                              final itemsSubtotal = storedItemsSubtotal != null
                                  ? storedItemsSubtotal
                                  : (snapshot.hasData ? itemsTotal : 0.0);

                              double vat = 0.0;
                              if (storedVatIncluded == true &&
                                  storedVatAmount != null) {
                                vat = storedVatAmount;
                              } else if (snapshot.hasData) {
                                final vatComputed =
                                    grandTotal - shippingCost - itemsTotal;
                                vat = vatComputed > 0 ? vatComputed : 0.0;
                              }

                              return Column(
                                children: [
                                  _KVRow(
                                      label: 'Items Subtotal:',
                                      value: snapshot.hasData
                                          ? '£${itemsSubtotal.toStringAsFixed(2)}'
                                          : '—'),
                                  6.height,
                                  _KVRow(
                                      label: 'VAT:',
                                      value: snapshot.hasData
                                          ? '£${vat.toStringAsFixed(2)}'
                                          : '—'),
                                  6.height,
                                  _KVRow(
                                      label: 'Shipping Method:',
                                      value: shippingMethod.isEmpty
                                          ? '—'
                                          : shippingMethod),
                                  6.height,
                                  _KVRow(
                                      label: 'Shipping Charges:',
                                      value:
                                          '£${shippingCost.toStringAsFixed(2)}'),
                                  16.height,
                                  Divider(height: 1, color: sh_view_color),
                                  12.height,
                                  Row(children: [
                                    Text('Total Amount:',
                                        style: GoogleFonts.workSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: sh_colorPrimary)),
                                    const Spacer(),
                                    ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                                    colors: [
                                                  sh_gradient_1st,
                                                  sh_gradient_2nd
                                                ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight)
                                                .createShader(Rect.fromLTWH(
                                                    0,
                                                    0,
                                                    bounds.width,
                                                    bounds.height)),
                                        child: Text(
                                            '£${grandTotal.toStringAsFixed(2)}',
                                            style: GoogleFonts.workSans(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white)))
                                  ])
                                ],
                              );
                            },
                          )
                        ])),
                    12.height,
                    _CardSection(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Update Status',
                              style: GoogleFonts.workSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: sh_colorPrimary)),
                          12.height,
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            items: [
                              'Pending',
                              'Processing',
                              'Shipped',
                              'Completed',
                              'Cancelled'
                            ]
                                .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e,
                                        style: GoogleFonts.workSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: sh_textColorPrimary))))
                                .toList(),
                            onChanged: (v) => setState(
                                () => _selectedStatus = v ?? _selectedStatus),
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
                          )
                        ])),
                    20.height,
                    Row(children: [
                      Expanded(
                          child: _PillButton(
                              label: 'Save',
                              bgColor: sh_colorPrimary,
                              onTap: _updateStatus)),
                      12.width,
                      Expanded(
                          child: _PillButton(
                              label: 'Cancel',
                              gradient: const LinearGradient(
                                  colors: [sh_gradient_1st, sh_gradient_2nd]),
                              onTap: () => finish(context))),
                    ]),
                    24.height,
                  ],
                ),
              ),
            )
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

  String _formatDateTime(DateTime d) {
    final months = [
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
    ];
    final m = months[d.month - 1];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '$m ${d.day}, ${d.year} at $hour:$min $ampm';
  }
}

class _CardSection extends StatelessWidget {
  final Widget child;
  const _CardSection({Key? key, required this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: defaultBoxShadow(shadowColor: appShadowColor)),
      child: Padding(
          padding: const EdgeInsets.all(spacing_standard_new), child: child),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String name;
  final double price;
  final String qtyText;
  final String imagePath;
  const _ProductRow(
      {Key? key,
        required this.name,
        required this.price,
        required this.qtyText,
        required this.imagePath})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8), // rectangle, not circle
        child: Container(
          width: 48,
          height: 48,
          color: Colors.grey[200], // letterbox background for uncropped images
          child: imagePath.startsWith('http')
              ? Image.network(imagePath,
              fit: BoxFit.contain, // shows whole image, no cropping
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey[300]))
              : Image.asset(imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey[300])),
        ),
      ),
      12.width,
      Expanded(
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: GoogleFonts.workSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: sh_colorPrimary)),
            6.height,
            Text(qtyText,
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
              .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text('£${price.toStringAsFixed(2)}',
              style: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)))
    ]);
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  const _KVRow({Key? key, required this.label, required this.value})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label,
          style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: sh_textColorSecondary)),
      const Spacer(),
      Text(value,
          style: GoogleFonts.workSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: sh_textColorPrimary))
    ]);
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
