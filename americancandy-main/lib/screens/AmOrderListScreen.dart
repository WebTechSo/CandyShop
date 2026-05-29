import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/screens/AmOrderDetailScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/data/services/order_service.dart';
import 'package:intl/intl.dart';
import 'package:american_sweets/screens/AmAccountScreen.dart';

class AmOrderListScreen extends StatefulWidget {
  static String tag = '/AmOrderListScreen';

  @override
  AmOrderListScreenState createState() => AmOrderListScreenState();
}

class AmOrderListScreenState extends State<AmOrderListScreen> {
  // Using StreamBuilder instead of manual list management
  Stream<List<AmOrder>>? orderStream;

  @override
  void initState() {
    super.initState();
    orderStream = OrderService().getUserOrders();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(sh_lbl_my_orders, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
          onPressed: () {
            AmAccountScreen().launch(context, isNewTask: true);
          },
        ),
      ),
      body: Container(
        width: width,
        child: StreamBuilder<List<AmOrder>>(
          stream: orderStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print("Error loading orders: ${snapshot.error}");
              return Center(
                  child: Text('Error loading orders: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(color: Colors.black);
            }

            var orders = snapshot.data!;

            return ListView.builder(
              itemCount: orders.length,
              scrollDirection: Axis.vertical,
              padding: EdgeInsets.only(bottom: 16),
              itemBuilder: (context, index) {
                AmOrder order = orders[index];
                String dateStr = order.orderDate != null
                    ? DateFormat('dd MMM yyyy')
                        .format(order.orderDate!.toDate())
                    : "";

                return Container(
                  padding: EdgeInsets.all(10.0),
                  margin: EdgeInsets.only(
                      bottom: spacing_standard,
                      left: spacing_standard,
                      right: spacing_standard),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: defaultBoxShadow(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Order Code & Date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order #${order.orderCode}",
                              style: boldTextStyle(size: 16)),
                          Text(dateStr, style: secondaryTextStyle()),
                        ],
                      ),
                      Divider(height: 20),
                      // Status & Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        _getStatusColor(order.deliveryStatus)),
                                width: 10,
                                height: 10,
                              ),
                              8.width,
                              Text(order.deliveryStatus ?? "Pending",
                                  style: boldTextStyle(
                                      color: _getStatusColor(
                                          order.deliveryStatus))),
                            ],
                          ),
                          Text(
                            order.grandTotal.toString().toCurrencyFormat(),
                            style:
                                boldTextStyle(color: sh_colorPrimary, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).onTap(() {
                  AmOrderDetailScreen(order: order).launch(context);
                });
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'Delivered') return Colors.green;
    if (status == 'Cancelled') return Colors.red;
    if (status == 'Shipped') return Colors.blue;
    return Colors.orange; // Pending/Processing
  }
}
