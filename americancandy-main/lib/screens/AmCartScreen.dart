import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart';
import 'package:american_sweets/screens/AmCartFragment.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmStrings.dart';

class AmCartScreen extends StatefulWidget {
  static String tag = '/AmCartScreen';

  @override
  AmCartScreenState createState() => AmCartScreenState();
}

class AmCartScreenState extends State<AmCartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sh_lbl_account, style: boldTextStyle(size: 18)),
        iconTheme: IconThemeData(color: appStore.isDarkModeOn ? white : sh_textColorPrimary),
      ),
      body: AmCartFragment(),
    );
  }
}
