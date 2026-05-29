import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/models/AmAddress.dart';

class AmOrder {
  String? id;
  String? userId;
  AmAddressModel? shippingAddress;
  String? shippingOption;
  double? shippingCost;
  String? deliveryStatus;
  String? paymentType;
  String? paymentStatus;
  double? grandTotal;
  double? itemsSubtotal;
  bool? vatIncluded;
  double? vatAmount;
  String? orderCode;
  Timestamp? orderDate;
  Timestamp? deliveredDate;
  String? contactEmail;
  String? customerType; // guest | customer | b2b

  AmOrder({
    this.id,
    this.userId,
    this.shippingAddress,
    this.shippingOption,
    this.shippingCost,
    this.deliveryStatus,
    this.paymentType,
    this.paymentStatus,
    this.grandTotal,
    this.itemsSubtotal,
    this.vatIncluded,
    this.vatAmount,
    this.orderCode,
    this.orderDate,
    this.deliveredDate,
    this.contactEmail,
    this.customerType,
  });

  factory AmOrder.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AmOrder(
      id: doc.id,
      userId: data['user_id'],
      shippingAddress: data['shipping_address'] != null
          ? AmAddressModel.fromJson(data['shipping_address'])
          : null,
      shippingOption: data['shipping_option'],
      shippingCost: (data['shipping_cost'] is num)
          ? (data['shipping_cost'] as num).toDouble()
          : 0.0,
      deliveryStatus: data['delivery_status'],
      paymentType: data['payment_type'],
      paymentStatus: data['payment_status'],
      grandTotal: (data['grand_total'] is num)
          ? (data['grand_total'] as num).toDouble()
          : 0.0,
      itemsSubtotal: (data['items_subtotal'] is num)
          ? (data['items_subtotal'] as num).toDouble()
          : null,
      vatIncluded: data['vat_included'] is bool ? data['vat_included'] : null,
      vatAmount: (data['vat_amount'] is num)
          ? (data['vat_amount'] as num).toDouble()
          : null,
      orderCode: data['order_code'],
      orderDate: data['order_date'] is Timestamp ? data['order_date'] : null,
      deliveredDate:
          data['delivered_date'] is Timestamp ? data['delivered_date'] : null,
      contactEmail: (data['contact_email'] ?? '').toString(),
      customerType: (data['customer_type'] ?? '').toString(),
    );
  }

  factory AmOrder.fromJson(Map<String, dynamic> json) {
    return AmOrder(
      orderCode: json['order_number'],
      deliveryStatus: json['order_status'],
      // Handle simple date string parsing if needed, or leave null
      // The old JSON had "14 apr 2020"
      orderDate: null,
    );
  }
}

class AmOrderItem {
  String? id;
  String? orderId;
  String? productId;
  String? variation;
  double? price;
  int? quantity;
  Timestamp? orderDate;

  // Extra fields for UI (not in DB directly usually, but helpful if we fetch product details)
  String? productName;
  String? productImage;

  AmOrderItem({
    this.id,
    this.orderId,
    this.productId,
    this.variation,
    this.price,
    this.quantity,
    this.orderDate,
    this.productName,
    this.productImage,
  });

  factory AmOrderItem.fromSnapshot(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AmOrderItem(
      id: doc.id,
      orderId: data['order_id'],
      productId: data['product_id'],
      variation: data['variation'],
      price: (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0,
      quantity: (data['quantity'] is int) ? data['quantity'] : 1,
      orderDate: data['order_date'] is Timestamp ? data['order_date'] : null,
      productName: data['product_name'],
      productImage: data['product_image'],
    );
  }
}
