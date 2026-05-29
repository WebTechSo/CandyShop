import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmProduct.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmExtension.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';
import 'package:american_sweets/data/services/cart_service.dart';

// Assuming the Home page route is defined somewhere, e.g., in a main app file
// or using a named route. For this example, we'll assume a direct pop or push.
// Placeholder for the Home page widget.
// If you are using a navigation system (like a BottomNavigationBar),
// the left arrow should likely just pop the current route.

class AmWishlistFragment extends StatefulWidget {
  static String tag = '/AmProfileFragment';

  @override
  AmWishlistFragmentState createState() => AmWishlistFragmentState();
}

class AmWishlistFragmentState extends State<AmWishlistFragment> {
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<AmProductModel>>(
        stream: WishlistService().getWishlistStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final list = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(spacing_standard_new),
                child: Text(
                  'Items(${list.length})',
                  style: boldTextStyle(size: 18),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: list.length,
                  padding: EdgeInsets.only(bottom: 70),
                  itemBuilder: (context, index) {
                    bool isLastItem = index == list.length - 1;
                    return Column(
                      children: [
                        Container(
                          color:
                              appStore.isDarkModeOn ? scaffoldDarkColor : white,
                          margin: EdgeInsets.symmetric(
                              horizontal: spacing_standard_new),
                          padding:
                              EdgeInsets.symmetric(vertical: spacing_standard),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Builder(builder: (context) {
                                  final dim = context.width() * 0.25;
                                  return SizedBox(
                                    width: dim,
                                    height: dim,
                                    child: ClipOval(
                                      child: Builder(builder: (context) {
                                        final p = list[index];
                                        final String firstImg =
                                            (p.images != null &&
                                                    p.images!.isNotEmpty)
                                                ? (p.images!.first).trim()
                                                : '';
                                        final String thumb =
                                            (p.thumbnail ?? '').trim();
                                        final String src =
                                            firstImg.isNotEmpty ? firstImg : thumb;

                                        if (src.startsWith('http')) {
                                          return CachedNetworkImage(
                                            imageUrl: src,
                                            fit: BoxFit.cover,
                                            placeholder: (c, u) => Container(
                                                color: Colors.grey[200],
                                                alignment: Alignment.center,
                                                child: const CircularProgressIndicator()),
                                            errorWidget: (c, u, e) => Image.asset(
                                              "images/sweets/img/products/candy-1.jpg",
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        }
                                        if (src.isNotEmpty) {
                                          final assetPath = src.startsWith('images/')
                                              ? src
                                              : "images/sweets/img/products/$src";
                                          return Image.asset(
                                            assetPath,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Image.asset(
                                              "images/sweets/img/products/candy-1.jpg",
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        }
                                        return Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_not_supported),
                                        );
                                      }),
                                    ),
                                  );
                                }),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(list[index].name!,
                                            style: boldTextStyle())
                                        .paddingOnly(left: 16.0),
                                    if ((list[index].description ?? '')
                                        .isNotEmpty)
                                      Text(
                                        list[index].description!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: secondaryTextStyle(size: 12),
                                      ).paddingOnly(left: 16.0, top: 4),
                                    Row(
                                      children: <Widget>[
                                        TextButton.icon(
                                          icon: Icon(Icons.add_shopping_cart,
                                              color: appStore.isDarkModeOn
                                                  ? white
                                                  : sh_textColorPrimary,
                                              size: 16),
                                          label: Text(sh_lbl_move_to_cart,
                                              style:
                                                  primaryTextStyle(size: 14)),
                                          onPressed: () {
                                            if (list[index].id != null) {
                                              CartService().addToCart(list[index]);
                                              WishlistService()
                                                  .removeFromWishlist(list[index].id!)
                                                  .then((_) => toast("Moved to cart"))
                                                  .catchError((e) => toast(e.toString()));
                                            }
                                          },
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          icon: Icon(Icons.delete_outline,
                                              color: appStore.isDarkModeOn
                                                  ? white
                                                  : sh_textColorPrimary,
                                              size: 16),
                                          label: Text(sh_lbl_remove,
                                              style:
                                                  primaryTextStyle(size: 14)),
                                          onPressed: () async {
                                            if (list[index].id != null) {
                                              try {
                                                await WishlistService()
                                                    .removeFromWishlist(list[index].id!);
                                                toast("Removed from wishlist");
                                              } catch (e) {
                                                toast(e.toString());
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ).paddingOnly(top: 8)
                                  ],
                                ).expand(),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Text(
                                    (list[index].price ?? 0)
                                        .toString()
                                        .toCurrencyFormat(),
                                    style: boldTextStyle(
                                        color: appStore.isDarkModeOn
                                            ? sh_gradient_1st
                                            : sh_colorPrimary,
                                        size: 18),
                                  ).paddingOnly(left: 8, top: 8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLastItem)
                          Divider(
                            color: grey.withValues(alpha: 0.3),
                            height: 1,
                            thickness: 1,
                            indent: spacing_standard_new,
                            endIndent: spacing_standard_new,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
