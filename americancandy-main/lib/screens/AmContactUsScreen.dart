import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/screens/AmEmailScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:url_launcher/url_launcher.dart';

class AmContactUsScreen extends StatefulWidget {
  static String tag = '/AmContactUsScreen';

  @override
  AmContactUsScreenState createState() => AmContactUsScreenState();
}

class AmContactUsScreenState extends State<AmContactUsScreen> {
  String? _whatsAppNumber;

  @override
  void initState() {
    super.initState();
    _loadContactNumber();
  }

  Future<void> _loadContactNumber() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_setting')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final num = data['contact_number']?.toString().trim();
        if (num != null && num.isNotEmpty) {
          setState(() {
            _whatsAppNumber = num;
          });
        }
      }
    } catch (e) {
      print('Failed to load contact_number: $e');
    }
  }

  Future<void> _openWhatsApp() async {
    final number = _whatsAppNumber;
    if (number == null || number.isEmpty) return;
    final message = "Hi, I want to know product about Sweet Stop";
    final encodedMessage = Uri.encodeComponent(message);
    final url = "https://wa.me/$number?text=$encodedMessage";
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      toast('Could not open WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sh_lbl_contact_us, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actionsIconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_colorPrimary),
        actions: <Widget>[cartIcon(context, 3)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () {
                _openWhatsApp();
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(sh_lbl_whatsapp_quick_chat_call, style: primaryTextStyle()),
                      Icon(Icons.keyboard_arrow_right,
                          color: appStore.isDarkModeOn
                              ? white
                              : sh_textColorPrimary),
                    ],
                  ),
                  Text(_whatsAppNumber ?? sh_contact_phone,
                      style: secondaryTextStyle()),
                  SizedBox(height: spacing_standard_new),
                  divider()
                ],
              ),
            ),
            SizedBox(height: spacing_standard_new),
            InkWell(
              onTap: () {
                AmEmailScreen().launch(context);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(sh_lbl_email, style: primaryTextStyle()),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color:
                            appStore.isDarkModeOn ? white : sh_textColorPrimary,
                      )
                    ],
                  ),
                  Text("Response within 1 business hour",
                      style: secondaryTextStyle()),
                  SizedBox(height: spacing_standard_new),
                  divider()
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
