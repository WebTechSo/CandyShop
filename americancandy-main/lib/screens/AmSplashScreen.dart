import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:american_sweets/screens/AmWalkThroughScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:google_fonts/google_fonts.dart';

class AmSplashScreen extends StatefulWidget {
  static String tag = '/AmercianSweetSplash';

  @override
  AmSplashScreenState createState() => AmSplashScreenState();
}

class AmSplashScreenState extends State<AmSplashScreen> {
  String _logoFirstName = 'Its Time For North American Confectioneries';

  @override
  void initState() {
    super.initState();
    changeStatusColor(Colors.transparent);
    _loadLogoText();
    startTime();
  }

  Future<void> _loadLogoText() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin_setting')
          .doc('vw0U6xyVtJRKsL2b7F57')
          .get();
      final name = (doc.data()?['first_name_logo'] ??
              'Its Time For North American Confectioneries')
          .toString();
      if (!mounted) return;
      setState(() {
        _logoFirstName = name;
      });
    } catch (_) {}
  }

  startTime() async {
    var _duration = Duration(seconds: 3);
    return Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Get.offAll(() => AmWalkThroughScreen());
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Top-left corner
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                splash_usa,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),

            // Top-right corner
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                splash_brazil,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),

            // Bottom-left corner
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                splash_canada,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),

            // Bottom-right corner
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                splash_japan,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(ic_app_icon,
                      width: width * 0.3,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink()),
                  SizedBox(height: 16), // optional spacing
                  SizedBox(height: 4),

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
