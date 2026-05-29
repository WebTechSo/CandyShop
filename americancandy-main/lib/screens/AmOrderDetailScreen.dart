import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmOrder.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/data/services/order_service.dart';
import 'package:intl/intl.dart';

// ignore: must_be_immutable
class AmOrderDetailScreen extends StatefulWidget {
  static String tag = '/AmOrderDetailScreen';
  AmOrder? order;

  AmOrderDetailScreen({this.order});

  @override
  AmOrderDetailScreenState createState() => AmOrderDetailScreenState();
}

class AmOrderDetailScreenState extends State<AmOrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;

    String orderDate = widget.order!.orderDate != null
        ? DateFormat('dd MMM yyyy, hh:mm a')
            .format(widget.order!.orderDate!.toDate())
        : "";

    // Items Section
    var itemsSection = FutureBuilder<List<AmOrderItem>>(
      future: OrderService().getOrderItems(widget.order!.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator()).paddingAll(16);
        }
        if (snapshot.hasError) {
          return Text("Error loading items").paddingAll(16);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("No items found").paddingAll(16);
        }

        return Column(
          children: snapshot.data!.map((item) {
            return Container(
              color: context.cardColor,
              margin: EdgeInsets.only(
                  left: spacing_standard_new,
                  right: spacing_standard_new,
                  top: spacing_standard_new),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    item.productImage != null && item.productImage!.isNotEmpty
                        ? Image.network(
                            item.productImage!,
                            width: width * 0.25,
                            height: width * 0.25,
                            fit: BoxFit.cover,
                          ).cornerRadiusWithClipRRect(8)
                        : Container(
                            width: width * 0.25,
                            height: width * 0.25,
                            color: Colors.grey[300],
                            child: Icon(Icons.image_not_supported),
                          ).cornerRadiusWithClipRRect(8),
                    10.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(item.productName ?? "Product Name",
                              style: boldTextStyle()),
                          4.height,
                          Text("Qty: ${item.quantity}",
                              style: secondaryTextStyle()),
                          4.height,
                          if (item.variation != null &&
                              item.variation!.isNotEmpty)
                            Text("Size: ${item.variation}",
                                style: secondaryTextStyle(size: 12)),
                          8.height,
                          Text(
                            item.price.toString().toCurrencyFormat(),
                            style: boldTextStyle(color: sh_colorPrimary),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );

    // Order Status Tracking
    var orderStatus = Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          border: Border.all(color: sh_view_color, width: 1.0),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Order Status", style: boldTextStyle(size: 16)),
          16.height,
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              8.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order Placed", style: boldTextStyle()),
                    Text(orderDate, style: secondaryTextStyle()),
                  ],
                ),
              ),
            ],
          ),
          20.height,
          Row(
            children: [
              Icon(
                  widget.order!.deliveryStatus == 'Delivered'
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: widget.order!.deliveryStatus == 'Delivered'
                      ? Colors.green
                      : Colors.grey),
              8.width,
              Text("Delivered",
                  style: primaryTextStyle(
                      color: widget.order!.deliveryStatus == 'Delivered'
                          ? black
                          : Colors.grey)),
            ],
          ),
        ],
      ),
    );

    // Shipping Details
    var shippingDetail = Container(
      margin: EdgeInsets.symmetric(horizontal: spacing_standard_new),
      decoration: BoxDecoration(
          border: Border.all(color: sh_view_color, width: 1.0),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(spacing_standard_new),
            child: Text(sh_lbl_shipping_details, style: boldTextStyle()),
          ),
          Divider(height: 1, color: sh_view_color),
          Padding(
            padding: EdgeInsets.all(spacing_standard_new),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    text(sh_lbl_order_id),
                    Text(widget.order!.orderCode ?? "",
                        style: primaryTextStyle()),
                  ],
                ),
                8.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    text(sh_lbl_order_date),
                    Text(orderDate, style: primaryTextStyle()),
                  ],
                ),
                8.height,
                if (widget.order!.shippingAddress != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Shipping Address:", style: secondaryTextStyle()),
                      4.height,
                      Text(
                        "${widget.order!.shippingAddress!.address}\n${widget.order!.shippingAddress!.city}, ${widget.order!.shippingAddress!.state} ${widget.order!.shippingAddress!.zip_code}\n${widget.order!.shippingAddress!.country}",
                        style: primaryTextStyle(),
                      ),
                    ],
                  ).paddingTop(8),
              ],
            ),
          )
        ],
      ),
    );

    // Payment Details
    var paymentDetail = Container(
      margin: EdgeInsets.all(spacing_standard_new),
      decoration: BoxDecoration(
          border: Border.all(color: sh_view_color, width: 1.0),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(sh_lbl_payment_details, style: boldTextStyle())
              .paddingSymmetric(horizontal: 16, vertical: 12),
          Divider(height: 1, color: sh_view_color),
          Padding(
            padding: EdgeInsets.all(spacing_standard_new),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    text("Payment Type"),
                    Text(widget.order!.paymentType ?? "N/A",
                        style: primaryTextStyle()),
                  ],
                ),
                8.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    text(sh_lbl_shipping_charge),
                    Text(
                        widget.order!.shippingCost
                            .toString()
                            .toCurrencyFormat()!,
                        style: primaryTextStyle()),
                  ],
                ),
                8.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    text(sh_lbl_total_amount),
                    Text(
                        widget.order!.grandTotal.toString().toCurrencyFormat()!,
                        style: boldTextStyle(
                            color: sh_colorPrimary,
                            size: textSizeLargeMedium.toInt())),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Order Details", style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            itemsSection,
            orderStatus,
            shippingDetail,
            paymentDetail,
            20.height,
          ],
        ),
      ),
    );
  }
}
