import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';

import 'AmProductDetail.dart';

class AmOffersScreen extends StatefulWidget {
  static String tag = '/AmOffersScreen';

  @override
  AmOffersScreenState createState() => AmOffersScreenState();
}

class AmOffersScreenState extends State<AmOffersScreen> {
  List<AmProductModel> mProductModel = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  fetchData() async {
    var products = await loadProducts();
    List<AmProductModel> offers = [];
    products.forEach((product) {
      // if (product.on_sale!) {
      offers.add(product);
      // }
    });
    setState(() {
      mProductModel.clear();
      mProductModel.addAll(offers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gridView = Container(
      child: GridView.builder(
          itemCount: mProductModel.length,
          shrinkWrap: true,
          padding: EdgeInsets.all(spacing_middle),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 9 / 13,
              crossAxisSpacing: spacing_middle,
              mainAxisSpacing: spacing_standard_new),
          itemBuilder: (_, index) {
            return InkWell(
              onTap: () {
                AmProductDetail(product: mProductModel[index]).launch(context);
              },
              child: Container(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 9 / 11,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: sh_view_color, width: 0.5)),
                            child: Image.asset(
                              "images/sweets/img/products" +
                                  mProductModel[index].images![0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(spacing_control),
                            margin: EdgeInsets.all(spacing_standard),
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: context.cardColor),
                            child: Icon(
                              Icons.favorite_border,
                              color: appStore.isDarkModeOn
                                  ? white
                                  : sh_textColorPrimary,
                              size: 16,
                            ),
                          ).onTap(() {
                            if (FirebaseAuth.instance.currentUser == null) {
                              toast("You need to login to add the wishlist");
                            } else {
                              if (mProductModel[index].id != null) {
                                WishlistService()
                                    .addToWishlist(mProductModel[index].id!);
                                toast("Added to wishlist");
                              }
                            }
                          })
                        ],
                      ),
                    ),
                    2.height,
                    Row(
                      children: <Widget>[
                        text(
                            mProductModel[index]
                                .price
                                .toString()
                                .toCurrencyFormat(),
                            textColor: sh_colorPrimary,
                            fontFamily: fontMedium,
                            fontSize: textSizeNormal),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(sh_lbl_my_offers, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actionsIconTheme: IconThemeData(color: sh_colorPrimary),
        actions: [
          cartIcon(context, 3),
        ],
      ),
      body: gridView,
    );
  }
}
