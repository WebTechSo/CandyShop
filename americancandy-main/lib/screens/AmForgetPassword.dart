import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AmSignUp.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AmSignIn.dart';
import 'package:get/get.dart';
import 'package:american_sweets/data/repositories/authentication_repository.dart';
import 'package:american_sweets/screens/VerifyEmailScreen.dart';
import 'package:american_sweets/utils/exceptions/firebase_auth_exceptions.dart';

class AmSweetsForgetPassword extends StatefulWidget {
  static String tag = '/AmSweetsForgetPassword';

  @override
  AmSweetsForgetPasswordState createState() => AmSweetsForgetPasswordState();
}

class AmSweetsForgetPasswordState extends State<AmSweetsForgetPassword> {
  var emailCont = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  Future<void> _resetPassword() async {
    final form = formKey.currentState;
    if (form == null || !form.validate()) return;

    try {
      isLoading.value = true;
      final email = emailCont.text.trim();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );
      final exists = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (exists.docs.isEmpty) {
        finish(context);
        Get.off(() => VerifyEmailScreen(
              title: 'Oops! Email Not Found',
              subtitle:
                  "We couldn’t find an account with that email address. Please try again or sign up to create a new account.",
              showResend: false,
              primaryLabel: 'Reset Password',
              onPrimaryPressed: () {
                Get.off(() => AmSweetsForgetPassword());
              },
              showSecondary: true,
              secondaryLabel: 'Sign up Instead',
              onSecondaryPressed: () {
                Get.off(() => AmSignUp());
              },
              icon: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 8, spreadRadius: 2)
                  ],
                ),
                child: Center(
                  child: Icon(Icons.sentiment_dissatisfied,
                      size: 40, color: sh_colorPrimary),
                ),
              ),
            ));
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: email,
          actionCodeSettings: ActionCodeSettings(
            url: 'https://amaricancandy-c87c3.firebaseapp.com/reset-password',
            handleCodeInApp: true,
            iOSBundleId: 'com.example.americanSweets',
            androidPackageName: 'com.sweetstop.app',
            androidInstallApp: true,
            androidMinimumVersion: '1',
          ),
        );
        toast("Password reset email sent to $email");
        finish(context);
        Get.off(() => VerifyEmailScreen(
              title: 'Check Your Email!',
              subtitle:
                  "We've sent you a link to reset your password. Please check your inbox.",
              showResend: false,
              primaryLabel: 'Back to Login',
              onPrimaryPressed: () {
                Get.offAll(() => AmSignIn());
              },
            ));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        finish(context);
        Get.off(() => VerifyEmailScreen(
              title: 'Oops! Email Not Found',
              subtitle:
                  "We couldn’t find an account with that email address. Please try again or sign up to create a new account.",
              showResend: false,
              primaryLabel: 'Reset Password',
              onPrimaryPressed: () {
                Get.off(() => AmSweetsForgetPassword());
              },
              showSecondary: true,
              secondaryLabel: 'Sign up Instead',
              onSecondaryPressed: () {
                Get.off(() => AmSignUp());
              },
              icon: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 8, spreadRadius: 2)
                  ],
                ),
                child: Center(
                  child: Icon(Icons.sentiment_dissatisfied,
                      size: 40, color: sh_colorPrimary),
                ),
              ),
            ));
      } else {
        finish(context);
        toast(UFirebaseAuthException(e.code).message);
      }
    } catch (e) {
      finish(context);
      toast(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

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
                child: Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [sh_gradient_1st, sh_gradient_2nd],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        child: Text(
                          "American",
                          style: GoogleFonts.workSans(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      4.height,
                      Text(
                        "Sweets",
                        style: GoogleFonts.workSans(
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                          color: sh_colorPrimary,
                        ),
                      ),
                      32.height,
                      TextFormField(
                        controller: emailCont,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final val = v?.trim() ?? '';
                          if (val.isEmpty) return 'Email is required';
                          if (!val.validateEmail()) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          filled: true,
                          fillColor: context.cardColor,
                          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            borderSide: BorderSide(color: Colors.red, width: 1),
                          ),
                        ),
                      ),
                      16.height,
                      Obx(() => SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: MaterialButton(
                              padding: EdgeInsets.all(spacing_standard),
                              child: isLoading.value
                                  ? CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          sh_white),
                                    )
                                  : Text(sh_lbl_reset_password,
                                      style: TextStyle(fontSize: 20)),
                              textColor: sh_white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0)),
                              color: isLoading.value
                                  ? Colors.grey
                                  : sh_colorPrimary,
                              onPressed:
                                  isLoading.value ? null : _resetPassword,
                            ),
                          )),
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
            ),
          ],
        ),
      ),
    );
  }
}
