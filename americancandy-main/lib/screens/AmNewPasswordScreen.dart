import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:american_sweets/screens/AmSignIn.dart';
import 'package:american_sweets/screens/VerifyEmailScreen.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';

class AmNewPasswordScreen extends StatefulWidget {
  final String oobCode;

  const AmNewPasswordScreen({Key? key, required this.oobCode})
      : super(key: key);

  @override
  _AmNewPasswordScreenState createState() => _AmNewPasswordScreenState();
}

class _AmNewPasswordScreenState extends State<AmNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _isLoading = false.obs;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;
      await FirebaseAuth.instance.confirmPasswordReset(
        code: widget.oobCode,
        newPassword: _passwordController.text.trim(),
      );

      toast("Password reset successfully");
      Get.offAll(() => VerifyEmailScreen(
            title: "Reset Password",
            subtitle:
                "Your password has been successfully updated. You can now log in with your new password.",
            primaryLabel: "Back to login",
            onPrimaryPressed: () => Get.offAll(() => AmSignIn()),
            showResend: false,
            icon: SizedBox(),
          ));
    } on FirebaseAuthException catch (e) {
      toast(e.message ?? "Failed to reset password");
    } catch (e) {
      toast("An error occurred: $e");
    } finally {
      _isLoading.value = false;
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
            // Background Flags - Same as VerifyEmailScreen/ForgetPassword
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child: Image.asset(splash_usa,
                    width: width * 0.5, height: width * 0.5, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
                child: Image.asset(splash_brazil,
                    width: width * 0.5, height: width * 0.5, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Image.asset(splash_canada,
                    width: width * 0.7,
                    height: height * 0.7,
                    fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Image.asset(splash_japan,
                    width: width * 0.7,
                    height: height * 0.7,
                    fit: BoxFit.cover),
              ),
            ),

            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: width < 500 ? width : 420,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 5)),
                    ],
                  ),
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Reset Password",
                          style:
                              boldTextStyle(size: 24, color: sh_colorPrimary),
                        ),
                        32.height,

                        // New Password
                        AppTextField(
                          controller: _passwordController,
                          textFieldType: TextFieldType.PASSWORD,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            hintText: 'Enter new password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Password is required';
                            if (v.length < 6)
                              return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        16.height,

                        // Confirm Password
                        AppTextField(
                          controller: _confirmPasswordController,
                          textFieldType: TextFieldType.PASSWORD,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            hintText: 'Confirm password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        32.height,

                        // Reset Button
                        Obx(() => AppButton(
                              width: double.infinity,
                              text: "Reset Password",
                              color: sh_colorPrimary,
                              textColor: Colors.white,
                              shapeBorder: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              onTap: _isLoading.value ? null : _resetPassword,
                              child: _isLoading.value
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : null,
                            )),
                        16.height,

                        // Cancel Button
                        AppButton(
                          width: double.infinity,
                          text: "Cancel",
                          color: sh_gradient_2nd, // Using Gold/Yellow tone
                          textColor: Colors.white,
                          shapeBorder: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          onTap: () => Get.offAll(() => AmSignIn()),
                        ),
                      ],
                    ),
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
