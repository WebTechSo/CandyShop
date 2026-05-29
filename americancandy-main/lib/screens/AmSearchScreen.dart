import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/utils/flutter_rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';

import 'AmProductDetail.dart';

class AmSearchScreen extends StatefulWidget {
  static String tag = '/AmSearchScreen';

  @override
  AmSearchScreenState createState() => AmSearchScreenState();
}

class AmSearchScreenState extends State<AmSearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<AmProductModel> list = [];
  bool isLoadingMoreData = false;
  bool isEmpty = false;
  var searchText = "";

  @override
  void initState() {
    super.initState();
  }

  fetchData() async {
    // Load Firestore products
    List<AmProductModel> firestoreProducts = [];
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('Products').get();
      firestoreProducts = querySnapshot.docs
          .map((doc) => AmProductModel.fromQuerySnapshot(doc))
          .where((p) => p.status == 'active' || p.status == null)
          .toList();
    } catch (e) {
      print('Error loading Firestore products: $e');
    }

    // Load Local JSON products
    List<AmProductModel> jsonProducts = await loadProducts();

    List<AmProductModel> allProducts = [...firestoreProducts, ...jsonProducts];

    List<AmProductModel> filteredList = [];
    allProducts.forEach((product) {
      if (product.name!.toLowerCase().contains(searchText.toLowerCase())) {
        filteredList.add(product);
      }
    });

    setState(() {
      list.clear();
      list.addAll(filteredList);
      isEmpty = list.isEmpty;
      isLoadingMoreData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var searchList = ListView.builder(
      itemCount: list.length,
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AmProductDetail(product: list[index])));
          },
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                        border: Border.all(color: sh_view_color, width: 1)),
                    child: (list[index].images != null &&
                            list[index].images!.isNotEmpty)
                        ? (list[index].images![0].startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: list[index].images![0],
                                fit: BoxFit.cover,
                                height: width * 0.35,
                                width: width * 0.29,
                                placeholder: (context, url) => Container(
                                    height: width * 0.35,
                                    width: width * 0.29,
                                    color: Colors.grey[200],
                                    child:
                                        Icon(Icons.image, color: Colors.grey)),
                                errorWidget: (context, url, error) => Container(
                                    height: width * 0.35,
                                    width: width * 0.29,
                                    color: Colors.grey[200],
                                    child:
                                        Icon(Icons.error, color: Colors.red)),
                              )
                            : Image.asset(
                                "images/sweets/img/products" +
                                    list[index].images![0],
                                fit: BoxFit.cover,
                                height: width * 0.35,
                                width: width * 0.29,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                        height: width * 0.35,
                                        width: width * 0.29,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.broken_image,
                                            color: Colors.grey)),
                              ))
                        : Container(
                            height: width * 0.35,
                            width: width * 0.29,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported),
                          ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        text(list[index].name, textColor: sh_textColorPrimary),
                        SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            text(
                                list[index].price.toString().toCurrencyFormat(),
                                textColor: sh_colorPrimary,
                                fontFamily: fontMedium,
                                fontSize: textSizeNormal),
                          ],
                        ),
                        SizedBox(
                          height: spacing_standard,
                        ),
                        // Row(children: colorWidget(list[index].attributes!)),
                        SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                /*RatingBar(
                                  initialRating:
                                      double.parse(list[index].average_rating!),
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  tapOnlyMode: true,
                                  itemCount: 5,
                                  itemSize: 16,
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {},
                                ),*/
                                Container(
                                  padding: EdgeInsets.all(spacing_control),
                                  margin:
                                      EdgeInsets.only(right: spacing_standard),
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: sh_white),
                                  child: Icon(
                                    Icons.favorite_border,
                                    color: sh_textColorPrimary,
                                    size: 16,
                                  ),
                                ).onTap(() {
                                  if (FirebaseAuth.instance.currentUser ==
                                      null) {
                                    toast(
                                        "You need to login to add the wishlist");
                                  } else {
                                    if (list[index].id != null) {
                                      WishlistService()
                                          .addToWishlist(list[index].id!);
                                      toast("Added to wishlist");
                                    }
                                  }
                                })
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actionsIconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        title: TextFormField(
          onFieldSubmitted: (value) {
            setState(
              () {
                searchText = value;
                isEmpty = false;
                isLoadingMoreData = true;
              },
            );
            fetchData();
          },
          controller: searchController,
          textInputAction: TextInputAction.search,
          style: primaryTextStyle(),
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Search",
              hintStyle: primaryTextStyle()),
          keyboardType: TextInputType.text,
          textAlign: TextAlign.start,
        ),
        actions: <Widget>[
          searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: appStore.isDarkModeOn ? white : sh_textColorPrimary,
                  ),
                  onPressed: () {
                    setState(
                      () {
                        searchController.clear();
                        list.clear();
                        isEmpty = false;
                        isLoadingMoreData = false;
                      },
                    );
                  },
                )
              : Container()
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: !isEmpty
            ? isLoadingMoreData
                ? Column(
                    children: [searchList, loadingWidgetMaker()],
                  )
                : searchList
            : Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    80.height,
                    Text(
                        "No results found for \"" +
                            searchController.text +
                            "\"",
                        style: boldTextStyle(size: 22)),
                    8.height,
                    Text("Try a diffetent keyword", style: secondaryTextStyle())
                  ],
                ),
              ),
      ),
    );
  }
}
