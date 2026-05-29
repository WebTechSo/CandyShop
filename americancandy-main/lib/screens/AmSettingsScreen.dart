import 'package:american_sweets/main.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class AmSettingsScreen extends StatefulWidget {
  static String tag = '/AmSettingsScreen';

  @override
  AmSettingsScreenState createState() => AmSettingsScreenState();
}

class AmSettingsScreenState extends State<AmSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;

  bool pushNotification = false;
  bool smsNotification = false;
  bool emailNotification = false;
  String? selectedValue = "English(US)";
  String userEmail = '';
  String userPhone = '';

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    User? user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Fetch Settings
      DocumentSnapshot doc =
          await _db.collection('Settings').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          pushNotification = data['push_notification_enable'] ?? false;
          smsNotification = data['sms_notification_enable'] ?? false;
          emailNotification = data['email_notification_enable'] ?? false;
          selectedValue = data['language'] ?? "English(US)";
          if (data.containsKey('dark_mode_enable')) {
            bool serverDarkMode = data['dark_mode_enable'];
            if (appStore.isDarkModeOn != serverDarkMode) {
              appStore.toggleDarkMode(value: serverDarkMode);
            }
          }
        });
      }

      // Fetch User Details
      DocumentSnapshot userDoc =
          await _db.collection('Users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userEmail = userData['email'] ?? '';
          userPhone = userData['phone'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching settings: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('Settings').doc(user.uid).set({
        key: value,
        'id': user.uid,
        'user_id': user.uid,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error saving setting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sh_lbl_settings, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
        actionsIconTheme: IconThemeData(
            color: appStore.isDarkModeOn ? white : sh_colorPrimary),
        actions: [
          cartIcon(context, 3),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: sh_colorPrimary))
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(
                        left: spacing_standard_new,
                        right: spacing_standard_new,
                        top: spacing_standard_new),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(sh_lbl_push_notification,
                                style: primaryTextStyle()),
                            Switch(
                              value: pushNotification,
                              onChanged: (value) {
                                setState(() {
                                  pushNotification = value;
                                });
                                _saveSetting('push_notification_enable', value);
                              },
                              activeColor: sh_colorPrimary,
                            )
                          ],
                        ),
                        Text(sh_lbl_notification_arrive_on_order_status,
                            style: secondaryTextStyle()),
                        16.height,
                        divider()
                      ],
                    ),
                  ),
                  if (_auth.currentUser != null) ...[
                    Container(
                      margin: EdgeInsets.only(
                          left: spacing_standard_new,
                          right: spacing_standard_new),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(sh_lbl_sms_notification,
                                  style: primaryTextStyle()),
                              Switch(
                                value: smsNotification,
                                onChanged: (value) {
                                  setState(() {
                                    smsNotification = value;
                                  });
                                  _saveSetting(
                                      'sms_notification_enable', value);
                                },
                                activeColor: sh_colorPrimary,
                              )
                            ],
                          ),
                          Text(
                              userPhone.isNotEmpty
                                  ? userPhone
                                  : sh_contact_phone,
                              style: secondaryTextStyle()),
                          SizedBox(height: spacing_standard_new),
                          divider()
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                          left: spacing_standard_new,
                          right: spacing_standard_new),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(sh_lbl_email_notification,
                                  style: primaryTextStyle()),
                              Switch(
                                value: emailNotification,
                                onChanged: (value) {
                                  setState(() {
                                    emailNotification = value;
                                  });
                                  _saveSetting(
                                      'email_notification_enable', value);
                                },
                                activeColor: sh_colorPrimary,
                              )
                            ],
                          ),
                          Text(
                              userEmail.isNotEmpty
                                  ? userEmail
                                  : sh_reference_email,
                              style: secondaryTextStyle()),
                          SizedBox(height: spacing_standard_new),
                          divider()
                        ],
                      ),
                    ),
                  ],
                  Container(
                    margin: EdgeInsets.only(
                        left: spacing_standard_new,
                        right: spacing_standard_new),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Dark Mode', style: primaryTextStyle()),
                            Switch(
                              value: appStore.isDarkModeOn,
                              activeColor: sh_colorPrimary,
                              onChanged: (s) {
                                setState(() {});
                                appStore.toggleDarkMode(value: s);
                                _saveSetting('dark_mode_enable', s);
                              },
                            )
                          ],
                        ),
                        Text('Theme Setting', style: secondaryTextStyle()),
                        SizedBox(height: spacing_standard_new),
                        divider()
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.all(spacing_standard_new),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(sh_lbl_language, style: primaryTextStyle()),
                            DropdownButton<String>(
                              underline: SizedBox(),
                              items: <String>["English(US)", "English(Canada)"]
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value, style: primaryTextStyle()),
                                );
                              }).toList(),
                              //hint:Text(selectedValue),
                              value: selectedValue,
                              onChanged: (newVal) {
                                setState(() {
                                  selectedValue = newVal;
                                });
                                _saveSetting('language', newVal);
                              },
                            ),
                          ],
                        ),
                        16.height,
                        divider()
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
