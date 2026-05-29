import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:american_sweets/screens/AmSignIn.dart';
import 'package:american_sweets/screens/AmAdminLoginScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:american_sweets/utils/dots_indicator/src/dots_decorator.dart';
import 'package:american_sweets/utils/dots_indicator/src/dots_indicator.dart';
import 'package:american_sweets/utils/widgets/ShSliderWidget.dart';

import 'AmHomeScreen.dart';

class AmWalkThroughScreen extends StatefulWidget {
  static var tag = "/AmWalkThroughScreen";

  @override
  _AmWalkThroughScreenState createState() => _AmWalkThroughScreenState();
}

class _AmWalkThroughScreenState extends State<AmWalkThroughScreen> {
  var mSliderList = <String>[ic_walk_1, ic_walk_2, ic_walk_3];
  var mHeadingList = <String>[
    "Hi, Welcome",
    "Most Unique Styles!",
    "Shop Till You Drop!"
  ];
  var mSubHeadingList = <String>[
    "We make around your city Affordable,easy and efficient.",
    "Shop the most trending fashion on the biggest shopping website",
    "Grab the best seller pieces at bargain prices."
  ];
  var position = 0;
  String? _whatsAppNumber;
  String _logoFirstName = 'Its Time For North American Confectioneries';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .get();
      final data = doc.data() ?? {};
      final num = data['contact_number']?.toString().trim();
      final firstName = (data['first_name_logo'] ??
              'Its Time For North American Confectioneries')
          .toString();
      if (!mounted) return;
      setState(() {
        _logoFirstName = firstName;
        _whatsAppNumber = (num != null && num.isNotEmpty) ? num : null;
      });
    } catch (e) {
      print('Failed to load admin settings: $e');
    }
  }

  Future<void> _openWhatsApp() async {
    final number = _whatsAppNumber;
    if (number == null || number.isEmpty) return;
    final snap = await FirebaseFirestore.instance
        .collection('admin_setting')
        .limit(1)
        .get();
    final appName = snap.docs.isNotEmpty
        ? (snap.docs.first.data()['app_name'] as String?)?.trim() ??
            'Sweet Stop'
        : 'Sweet Stop';
    final message = "Hi, I want to know product about $appName";
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse("https://wa.me/$number?text=$encodedMessage");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      toast('Could not open WhatsApp');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    width = width - 50;
    return Scaffold(
      body: Stack(
        children: [
          // Top-left corner
          Align(
            alignment: Alignment.topLeft,
            child: Image.asset(
              splash_usa,
              width: width * 0.5,
              height: width * 0.5,
              fit: BoxFit.cover,
            ),
          ),

// Top-right
          Align(
            alignment: Alignment.topRight,
            child: Image.asset(
              splash_brazil,
              width: width * 0.5,
              height: width * 0.5,
              fit: BoxFit.cover,
            ),
          ),

// Bottom-left
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              splash_canada,
              width: width * 0.5,
              height: width * 0.5,
              fit: BoxFit.cover,
            ),
          ),
// Bottom-right
          Align(
            alignment: Alignment.bottomRight,
            child: Image.asset(
              splash_japan,
              width: width * 0.5,
              height: width * 0.5,
              fit: BoxFit.cover,
            ),
          ),

          // Center content
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60), // optional spacing
                Image.asset(ic_app_icon, width: width * 0.3),
                SizedBox(height: 16),
                SizedBox(height: 4),
                32.height,
                Text(
                  _logoFirstName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Calibri',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 3, 3, 3),
                  ),
                ),
                32.height,
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: MaterialButton(
                    padding: EdgeInsets.all(spacing_standard),
                    child: Text(sh_text_start_to_shopping,
                        style: TextStyle(fontSize: 18)),
                    textColor: sh_white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.0)),
                    color: sh_colorPrimary,
                    onPressed: () {
                      Get.to(() => AmHomeScreen());
                    },
                  ),
                ),
                if (FirebaseAuth.instance.currentUser == null) ...[
                  16.height,
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40.0),
                        gradient: LinearGradient(
                          colors: [sh_gradient_1st, sh_gradient_2nd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: MaterialButton(
                        padding: EdgeInsets.all(spacing_standard),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40.0),
                        ),
                        child: Text(
                          sh_lbl_sign_in,
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        onPressed: () {
                          AmSignIn().launch(context);
                        },
                        color: Colors.transparent,
                        elevation: 0,
                      ),
                    ),
                  ),
                  16.height,
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: MaterialButton(
                      padding: EdgeInsets.all(spacing_standard),
                      child:
                          Text("Admin Login", style: TextStyle(fontSize: 18)),
                      textColor: sh_colorPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40.0),
                          side: BorderSide(color: sh_colorPrimary)),
                      color: sh_white,
                      elevation: 0,
                      onPressed: () {
                        AmAdminLoginScreen().launch(context);
                      },
                    ),
                  ),
                  24.height,
                  if (_whatsAppNumber != null && _whatsAppNumber!.isNotEmpty)
                    GestureDetector(
                      onTap: _openWhatsApp,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            8.width,
                            Image.asset(
                              'images/sweets/whatsapp.png',
                              height: 40,
                              width: 40,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                32.height,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class ShSliderWidget extends StatelessWidget {
  var mSliderList = <String>[ic_walk_1, ic_walk_2, ic_walk_3];

  ShSliderWidget(this.mSliderList);

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    width = width - 50;
    final Size cardSize = Size(width, width / 1.8);

    return ShCarouselSlider(
      viewportFraction: 0.9,
      height: cardSize.height,
      enlargeCenterPage: true,
      scrollDirection: Axis.horizontal,
      items: mSliderList.map((slider) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              height: cardSize.height,
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                elevation: 0,
                margin: EdgeInsets.all(0),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                child: CachedNetworkImage(
                    placeholder: placeholderWidgetFn() as Widget Function(
                        BuildContext, String)?,
                    imageUrl: slider,
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width,
                    height: cardSize.height),
              ),
            );
          },
        );
      }).toList(),
      onPageChanged: (index) {},
    );
  }
}
