import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/models/AmCategory.dart';
import 'package:american_sweets/screens/AmAccountScreen.dart';
import 'package:american_sweets/screens/AmCartFragment.dart';
import 'package:american_sweets/screens/AmContactUsScreen.dart';
import 'package:american_sweets/screens/AmFAQScreen.dart';
import 'package:american_sweets/screens/AmHomeFragment.dart';
import 'package:american_sweets/screens/AmCategoriesFragment.dart';
import 'package:american_sweets/screens/AmOrderSummaryScreen.dart';
import 'package:american_sweets/screens/AmNotificationScreen.dart'; // Add this import
import 'package:american_sweets/screens/AmSettingsScreen.dart';
import 'package:american_sweets/screens/AdminDashboardScreen.dart';
import 'package:american_sweets/screens/AmWishlistFragment.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';

import 'package:american_sweets/screens/AmViewAllProducts.dart';
import 'package:american_sweets/screens/AmSignIn.dart';
import 'package:american_sweets/data/services/wishlist_service.dart';
import 'package:american_sweets/data/services/order_service.dart';
import 'package:american_sweets/data/services/cart_service.dart';
import 'package:american_sweets/screens/AmWalkThroughScreen.dart';

class AmHomeScreen extends StatefulWidget {
  static String tag = '/AmHomeScreen';
  final int initialTab;
  const AmHomeScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  AmHomeScreenState createState() => AmHomeScreenState();
}

class AmHomeScreenState extends State<AmHomeScreen> {
  List<AmCategory> list = [];
  var homeFragment = AmCategoriesFragment();
  var productsFragment = AmHomeFragment();
  var cartFragment = AmCartFragment();
  var wishlistFragment = AmWishlistFragment();
  var accountScreen = AmAccountScreen();
  late var fragments;
  var selectedTab = 0;
  String? _userName;
  String? _profilePicture;
  int wishlistCount = 0;
  int orderCount = 0;

  @override
  void initState() {
    super.initState();
    fragments = [
      homeFragment,
      productsFragment,
      wishlistFragment,
      cartFragment,
      accountScreen
    ];
    selectedTab = widget.initialTab;
    fetchData();
    _loadUserData();
  }

  fetchData() async {
    loadCategory().then((categories) {
      setState(() {
        list.clear();
        list.addAll(categories);
      });
    }).catchError((error) {
      toasty(context, error);
    });

    try {
      var products = await WishlistService().getUserWishlist();
      setState(() {
        wishlistCount = products.length;
      });
    } catch (e) {
      print("Error loading wishlist count: $e");
    }

    try {
      final orders = await OrderService().getUserOrders().first;
      if (mounted) {
        setState(() {
          orderCount = orders.length;
        });
      }
    } catch (e) {
      print("Error loading orders count: $e");
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      final name = data?['full_name'] ??
          data?['fullName'] ??
          data?['name'] ??
          user.email;
      final pic = data?['profile_picture'];

      setState(() {
        if (name != null && name.toString().trim().isNotEmpty) {
          _userName = name.toString();
        }
        final picStr = (pic ?? '').toString().trim();
        _profilePicture = picStr.isNotEmpty ? picStr : null;
      });
    } catch (_) {}
  }

  Future<List<AmCategory>> loadCategory() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Categories')
          .orderBy('menu_order')
          .get();
      return querySnapshot.docs
          .map((doc) => AmCategory.fromQuerySnapshot(doc))
          .toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    final String title = () {
      switch (selectedTab) {
        case 0:
          return "Home";
        case 1:
          return "Products";
        case 2:
          return "All Wishlist";
        case 3:
          return "Review Order";
        case 4:
          return "Account";
        default:
          return "Home";
      }
    }();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 96,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                } else {
                  navigator.pushReplacement(
                    MaterialPageRoute(builder: (_) => AmWalkThroughScreen()),
                  );
                }
              },
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
            ),
          ],
        ),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actions: [
          // Replaced search icon with notification icon
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications,
                    color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
                onPressed: () {
                  ShNotificationScreen().launch(context);
                },
              ),
              // Notification badge
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseAuth.instance.currentUser != null
                    ? FirebaseFirestore.instance
                        .collection('Notifications')
                        .where('userId',
                            isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                        .where('isRead', isEqualTo: false)
                        .snapshots()
                        .asBroadcastStream()
                    : null,
                builder: (context, snapshot) {
                  int count = 0;
                  if (snapshot.hasData) {
                    count = snapshot.data!.docs.length;
                  }

                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          )
        ],
        title: Text(title, style: boldTextStyle(size: 22)),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          fragments[selectedTab],
          Container(
            color: context.cardColor,
            child: SafeArea(
              top: false,
              child: Container(
                height: 58,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: <Widget>[
                    Container(
                      width: width,
                      height: double.infinity,
                      color: context.cardColor,
                      child: Column(
                        children: [
                          Container(
                              height: 1, color: Colors.grey.withOpacity(0.2)),
                          Expanded(child: Container()),
                        ],
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          tabItem(0, sh_ic_home),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.withOpacity(0.3)),
                          tabItem(1, Icons.grid_view_rounded),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.withOpacity(0.3)),
                          tabItem(2, sh_ic_heart),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.withOpacity(0.3)),
                          tabItem(3, sh_ic_cart_2),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.withOpacity(0.3)),
                          tabItem(4, sh_user),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height,
        child: Drawer(
          elevation: 8,
          child: SingleChildScrollView(
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: appStore.isDarkModeOn ? scaffoldDarkColor : white,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  Stack(
                    children: <Widget>[
                      Center(
                        child: Padding(
                            padding:
                                EdgeInsets.only(top: 60, right: spacing_large),
                            child: Column(
                              children: <Widget>[
                                Card(
                                  semanticContainer: true,
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  elevation: spacing_standard,
                                  margin: EdgeInsets.all(spacing_control),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(100.0)),
                                  child: Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: CircleAvatar(
                                        backgroundImage:
                                            (_profilePicture != null &&
                                                    _profilePicture!.isNotEmpty)
                                                ? NetworkImage(_profilePicture!)
                                                : AssetImage(ic_user)
                                                    as ImageProvider,
                                        radius: 55),
                                  ),
                                ),
                                SizedBox(height: spacing_middle),
                                Text(
                                  (_userName != null &&
                                          _userName!.trim().isNotEmpty)
                                      ? _userName!
                                      : "Guest User",
                                  style: boldTextStyle(
                                      color: appStore.isDarkModeOn
                                          ? white
                                          : sh_textColorPrimary,
                                      size: 18),
                                )
                              ],
                            )),
                      ),
                      Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                              padding: EdgeInsets.only(
                                  left: spacing_standard_new, top: 30),
                              child: IconButton(
                                icon: Icon(Icons.clear,
                                    color: appStore.isDarkModeOn
                                        ? white
                                        : sh_textColorPrimary),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ))),
                      if (FirebaseAuth.instance.currentUser != null)
                        Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                                padding: EdgeInsets.only(
                                    right: spacing_standard_new, top: 30),
                                child: IconButton(
                                  icon: Icon(Icons.logout,
                                      color: appStore.isDarkModeOn
                                          ? white
                                          : sh_textColorPrimary),
                                  onPressed: () {
                                    FirebaseAuth.instance.signOut();
                                    AmSignIn().launch(context, isNewTask: true);
                                  },
                                )))
                    ],
                  ),
                  SizedBox(height: 30),
                  Container(
                    color: context.cardColor,
                    padding: EdgeInsets.fromLTRB(
                        0, spacing_standard, 0, spacing_standard),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                      builder: (_) => AmOrderSummaryScreen()),
                                );
                              });
                            },
                            child: Column(
                              children: <Widget>[
                                text(
                                    ((orderCount <= 0 ? 1 : orderCount))
                                        .toString()
                                        .padLeft(2, '0'),
                                    textColor: sh_colorPrimary,
                                    fontFamily: fontMedium),
                                SizedBox(height: spacing_control),
                                text("My Order",
                                    textColor: appStore.isDarkModeOn
                                        ? white
                                        : sh_textColorPrimary,
                                    fontFamily: fontMedium),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              AmWishlistFragment().launch(context);
                            },
                            child: Column(
                              children: <Widget>[
                                text(wishlistCount.toString(),
                                    textColor: sh_colorPrimary,
                                    fontFamily: fontMedium),
                                SizedBox(height: spacing_control),
                                text("Wishlist",
                                    textColor: appStore.isDarkModeOn
                                        ? white
                                        : sh_textColorPrimary,
                                    fontFamily: fontMedium),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  list.isEmpty
                      ? _DrawerCategoriesSkeleton()
                      : ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: list.length,
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          itemBuilder: (context, index) {
                            return getDrawerItem(
                              list[index].image,
                              list[index].name,
                              callback: () {
                                AmViewAllProductscreen(
                                        category: list[index],
                                        title: list[index].name)
                                    .launch(context);
                              },
                            );
                          },
                        ),
                  SizedBox(height: 30),
                  Divider(color: sh_view_color, height: 1),
                  SizedBox(height: 20),
                  getDrawerItem(sh_user_placeholder, sh_lbl_account,
                      callback: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      AmSignIn().launch(context);
                    } else {
                      AmAccountScreen().launch(context);
                    }
                  }),
                  getDrawerItem(sh_settings, sh_lbl_settings, callback: () {
                    AmSettingsScreen().launch(context);
                  }),
                  getDrawerItem(sh_faq, sh_lbl_faq, callback: () {
                    AmFAQScreen().launch(context);
                  }),
                  getDrawerItem(sh_contact_us, sh_lbl_contact_us, callback: () {
                    AmContactUsScreen().launch(context);
                  }),
                  SizedBox(height: 30),
                  Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: sh_colorPrimary.withOpacity(0.2)),
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: <Widget>[
                        Image.asset(ic_app_icon, width: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            text("American",
                                textColor: sh_textColorPrimary,
                                fontSize: textSizeMedium,
                                fontFamily: fontBold),
                            text("Sweets",
                                textColor: sh_colorPrimary,
                                fontSize: textSizeMedium,
                                fontFamily: fontBold),
                          ],
                        ),
                        4.height,
                        Text("v 1.0",
                            style: primaryTextStyle(
                                color: appStore.isDarkModeOn
                                    ? white
                                    : sh_textColorPrimary,
                                size: 14))
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget getDrawerItem(String? icon, String? name, {VoidCallback? callback}) {
    final String trimmedIcon = icon?.trim() ?? '';
    final bool hasIcon = trimmedIcon.isNotEmpty;
    final bool isNetworkIcon = hasIcon && trimmedIcon.startsWith('http');

    Widget leading;
    if (hasIcon) {
      leading = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: context.cardColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: isNetworkIcon
            ? Image.network(
                trimmedIcon,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 20,
                  color: sh_textColorSecondary,
                ),
              )
            : Image.asset(
                trimmedIcon,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 20,
                  color: sh_textColorSecondary,
                ),
              ),
      );
    } else {
      leading = SizedBox(width: 40);
    }

    return InkWell(
      onTap: callback,
      child: Container(
        color: context.cardColor,
        padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Row(
          children: <Widget>[
            leading,
            SizedBox(width: 16),
            Text(
              name ?? '',
              style: primaryTextStyle(
                  color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget tabItem(var pos, var icon) {
    return GestureDetector(
      onTap: () async {
        if (pos == 4) {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            await AmSignIn().launch(context);
            if (!mounted) return;
            if (FirebaseAuth.instance.currentUser != null) {
              setState(() {
                selectedTab = pos;
              });
            }
            return;
          }

          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .get();
            final data = userDoc.data() as Map<String, dynamic>?;
            final userType =
                (data?['user_type'] ?? '').toString().toLowerCase();
            final role = (data?['role'] ?? '').toString().toLowerCase();

            if (userType == 'admin' || role == 'admin') {
              AdminDashboardScreen().launch(context);
              return;
            }
          } catch (_) {}
        }
        setState(() {
          selectedTab = pos;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: selectedTab == pos
            ? BoxDecoration(
                shape: BoxShape.circle, color: sh_colorPrimary.withOpacity(0.2))
            : BoxDecoration(),
        child: pos == 3
            ? StreamBuilder<QuerySnapshot>(
                stream: CartService().getCartStream(),
                builder: (context, snapshot) {
                  int total = 0;
                  if (snapshot.hasData) {
                    for (final d in snapshot.data!.docs) {
                      final m = d.data() as Map<String, dynamic>;
                      total += (m['quantity'] ?? 1) as int;
                    }
                  }
                  final badge = total > 0
                      ? Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              total > 9 ? '9+' : '$total',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SizedBox.shrink();
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildTabIcon(icon, selectedTab == pos),
                      badge,
                    ],
                  );
                })
            : _buildTabIcon(icon, selectedTab == pos),
      ),
    );
  }

  Widget _buildTabIcon(dynamic icon, bool active) {
    final Color c = active ? sh_colorPrimary : sh_textColorSecondary;
    if (icon is String) {
      return SvgPicture.asset(icon, width: 24, height: 24, color: c);
    } else if (icon is IconData) {
      return Icon(icon, size: 24, color: c);
    }
    return Icon(Icons.circle, size: 6, color: c);
  }

  Widget _DrawerCategoriesSkeleton() {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;
    return _Shimmer(
      base: base,
      highlight: highlight,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: 8,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (_, __) {
          return Container(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;
  final Color base;
  final Color highlight;
  const _Shimmer(
      {required this.child, required this.base, required this.highlight});
  @override
  _ShimmerState createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1500))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = (1.0 + 2.0) * _controller.value - 1.0;
            return LinearGradient(
              begin: Alignment(-1.0 + dx, 0),
              end: Alignment(1.0 + dx, 0),
              colors: [widget.base, widget.highlight, widget.base],
              stops: [0.2, 0.5, 0.8],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
