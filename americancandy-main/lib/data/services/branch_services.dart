import 'dart:async';
import 'dart:ui';

import 'package:american_sweets/utils/constants/keys.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:get/get.dart';

import 'package:american_sweets/models/AmProduct.dart';

class BranchServices extends GetxController {
  static BranchServices get instance => Get.find();

  /// Function to initialize branch
  Future<void> initBranch() async {
    await FlutterBranchSdk.init(
        enableLogging: true,
        branchAttributionLevel: BranchAttributionLevel.FULL);
  }

  /// Function to create link
  Future<void> createLink(AmProductModel product) async {
    try {
      // create universal object
      BranchUniversalObject buo = BranchUniversalObject(
          canonicalIdentifier: 'product/${product.id ?? ''}',
          title: product.name ?? '',
          imageUrl: product.thumbnail ?? '',
          contentDescription: product.description ?? '',
          publiclyIndex: true,
          locallyIndex: true,
          contentMetadata: BranchContentMetaData()
            ..addCustomMetadata(UKeys.productId, product.id?.toString() ?? ''));

      // create link properties
      BranchLinkProperties lp = BranchLinkProperties(
        channel: 'app',
        feature: 'share_product',
      );

      // share product
      await FlutterBranchSdk.showShareSheet(
          buo: buo, linkProperties: lp, messageText: 'Share Product');
    } catch (e) {
      throw 'Product cannot be shared';
    }
  }

  /// Function to track the link
  StreamSubscription<Map> trackLink(Function(Map<dynamic, dynamic>) onListen,
      {VoidCallback? onError}) {
    StreamSubscription<Map> streamSubscription =
        FlutterBranchSdk.listSession().listen((data) {
      if (data.containsKey("+clicked_branch_link") &&
          data["+clicked_branch_link"] == true) {
        onListen(data);
      }
    }, onError: (error) {
      if (onError != null) onError();
    });

    return streamSubscription;
  }
}
