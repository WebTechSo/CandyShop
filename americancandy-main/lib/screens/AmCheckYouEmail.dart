import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AmSignUp.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AmSignIn.dart';

class AmCheckYouEmail extends StatefulWidget {
  static String tag = '/AmCheckYouEmail';

  @override
  AmCheckYouEmailState createState() => AmCheckYouEmailState();
}

class AmCheckYouEmailState extends State<AmCheckYouEmail> {
  var emailCont = TextEditingController();
  var passwordCont = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(

        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Top-left
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                splash_usa,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
              ),
            ),

            // Top-right
            Positioned(
              top: 0,
              right: 0,
              child: Image.asset(
                splash_brazil,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
              ),
            ),

            // Bottom-left
            Positioned(
              bottom: 0,
              left: 0,
              child: Image.asset(
                splash_canada,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
              ),
            ),

            // Bottom-right
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                splash_japan,
                width: width * 0.5,
                height: width * 0.5,
                fit: BoxFit.cover,
              ),
            ),

            // Main content (scrollable)
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset(
                      check_email,
                      width: 180, // adjust as needed
                      height: 180,
                      fit: BoxFit.contain,
                    ),
                    32.height,
                    TextFormField(
                      controller: emailCont,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: sh_hint_enter_your_email_id,
                        filled: true,
                        fillColor: context.cardColor,
                        contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32.0),
                        ),
                      ),
                    ),
                    16.height,
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: MaterialButton(
                        padding: EdgeInsets.all(spacing_standard),
                        child: Text(sh_lbl_reset_password, style: TextStyle(fontSize: 20)),
                        textColor: sh_white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40.0)),
                        color: sh_colorPrimary,
                        onPressed: () {
                          finish(context);
                          AmHomeScreen().launch(context);
                        },
                      ),
                    ),
                    32.height,
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(

                        onPressed: () => {AmSignIn().launch(context)},
                        child: Text(
                          sh_lbl_back_login,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: sh_colorPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}
