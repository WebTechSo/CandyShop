import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AmAdminLoginScreen.dart';
import 'package:american_sweets/screens/AmForgetPassword.dart';
import 'package:american_sweets/screens/AmSignUp.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/screens/VerifyEmailScreen.dart';

class AmSignIn extends StatefulWidget {
  static String tag = '/AmSignIn';

  @override
  AmSignInState createState() => AmSignInState();
}

class AmSignInState extends State<AmSignIn> {
  var emailCont = TextEditingController();
  var passwordCont = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _obscurePassword = true;

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
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
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
                            color: Colors.white, // gradient overrides this
                          ),
                        ),
                      ),
                      Text(
                        "Sweets",
                        style: GoogleFonts.workSans(
                          fontSize: 45,
                          fontWeight: FontWeight.bold,
                          color: sh_colorPrimary,
                        ),
                      ),
                      Text(
                        sh_moto,
                        style: secondaryTextStyle(size: 16),
                        maxLines: 3,
                        textAlign: TextAlign.center,
                      ),
                      40.height,
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        autofocus: false,
                        controller: emailCont,
                        textCapitalization: TextCapitalization.words,
                        style: primaryTextStyle(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter email';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.cardColor,
                          hintText: sh_hint_Email,
                          hintStyle: primaryTextStyle(),
                          contentPadding:
                              EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            borderSide: BorderSide(
                                color: sh_colorPrimary,
                                width: 1.5), // active border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1), // normal border
                          ),
                        ),
                      ),
                      16.height,
                      TextFormField(
                        keyboardType: TextInputType.text,
                        autofocus: false,
                        obscureText: _obscurePassword,
                        controller: passwordCont,
                        textCapitalization: TextCapitalization.words,
                        style: primaryTextStyle(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter password';
                          if (value.length < 6) return 'Password too short';
                          return null;
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: context.cardColor,
                          hintText: sh_hint_password,
                          hintStyle: primaryTextStyle(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: sh_textColorSecondary,
                            ),
                          ),
                          contentPadding:
                              EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            borderSide: BorderSide(
                                color: sh_colorPrimary,
                                width: 1.5), // active border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32.0),
                            borderSide: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1), // normal border
                          ),
                        ),
                      ),
                      32.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              AmAdminLoginScreen().launch(context);
                            },
                            child: Text(
                              "Admin Login",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: sh_colorPrimary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              finish(context);
                              AmSweetsForgetPassword().launch(context);
                            },
                            child: Text(
                              sh_lbl_forgot_password,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: sh_colorPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      24.height,
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        // height: double.infinity,
                        child: MaterialButton(
                          padding: EdgeInsets.all(spacing_standard),
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : text(sh_lbl_log_in,
                                  fontSize: textSizeNormal,
                                  fontFamily: fontMedium,
                                  textColor: sh_white),
                          textColor: sh_white,
                          shape: RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(40.0)),
                          color: sh_colorPrimary,
                          onPressed: () => _loginUser(),
                        ),
                      ),
                      16.height,
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              sh_lbl_dont_have_account,
                              style: GoogleFonts.workSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black, // normal text color
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                AmSignUp().launch(
                                    context); // your signup screen navigation
                              },
                              child: ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: [sh_gradient_1st, sh_gradient_2nd],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(Rect.fromLTWH(
                                    0, 0, bounds.width, bounds.height)),
                                child: Text(
                                  sh_lbl_sign_up_link,
                                  style: GoogleFonts.workSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Colors.white, // gradient will override
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              left: 16,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: context.cardColor,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: sh_textColorPrimary),
                    onPressed: () {
                      finish(context);
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 30,
              right: 16,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: context.cardColor,
                  child: IconButton(
                    icon: Icon(Icons.home_outlined, color: sh_textColorPrimary),
                    onPressed: () {
                      AmHomeScreen().launch(context, isNewTask: true);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginUser() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCont.text.trim(),
        password: passwordCont.text.trim(),
      );
      await cred.user?.reload();
      final verified = cred.user?.emailVerified ?? false;
      if (!verified) {
        Get.offAll(() => const VerifyEmailScreen());
        return;
      }
      Get.offAll(() => AmHomeScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Login Failed",
        e.message ?? "Authentication error",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
