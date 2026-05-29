import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:american_sweets/utils/constants/texts.dart';
import 'package:american_sweets/data/repositories/authentication_repository.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    this.title,
    this.subtitle,
    this.primaryLabel,
    this.onPrimaryPressed,
    this.showResend = true,
    this.resendLabel,
    this.onResendPressed,
    this.icon,
    this.showSecondary = false,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String? title;
  final String? subtitle;
  final String? primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool showResend;
  final String? resendLabel;
  final Future<void> Function()? onResendPressed;
  final Widget? icon;
  final bool showSecondary;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        t.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
        return;
      }
      setState(() {
        _secondsRemaining -= 1;
      });
    });
  }

  String _formatRemaining(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final cardWidth = width < 500 ? width - spacing_xlarge : 420.0;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
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
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                splash_canada,
                width: width * 0.8,
                height: height,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Bottom-right
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                splash_japan,
                width: width * 0.8,
                height: height,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  width: cardWidth,
                  margin: EdgeInsets.all(spacing_xlarge),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: EdgeInsets.all(spacing_xlarge),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          widget.icon ??
                              Image.asset(check_email, width: 80, height: 80),
                          16.height,
                          Text(
                            widget.title ?? UTexts.verifyEmailTitle,
                            style:
                                boldTextStyle(size: 20, color: sh_colorPrimary),
                            textAlign: TextAlign.center,
                          ),
                          12.height,
                          Text(
                            widget.subtitle ?? UTexts.verifyEmailSubTitle,
                            style: secondaryTextStyle(),
                            textAlign: TextAlign.center,
                          ),
                          24.height,
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: MaterialButton(
                              padding: EdgeInsets.all(spacing_standard),
                              child: Text(
                                  widget.primaryLabel ?? UTexts.uContinue,
                                  style: TextStyle(fontSize: 18)),
                              textColor: sh_white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0)),
                              color: sh_colorPrimary,
                              onPressed: widget.onPrimaryPressed ??
                                  () {
                                    Get.offAll(() => AmHomeScreen());
                                  },
                            ),
                          ),
                          if (widget.showSecondary) ...[
                            12.height,
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [sh_gradient_1st, sh_gradient_2nd],
                                  ),
                                  borderRadius: BorderRadius.circular(40.0),
                                ),
                                child: MaterialButton(
                                  padding: EdgeInsets.all(spacing_standard),
                                  child: Text(
                                      widget.secondaryLabel ?? UTexts.uContinue,
                                      style: TextStyle(
                                          fontSize: 18, color: sh_white)),
                                  onPressed: widget.onSecondaryPressed,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(40.0)),
                                ),
                              ),
                            ),
                          ],
                          if (widget.showResend) ...[
                            12.height,
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: sh_colorPrimary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(40.0)),
                                ),
                                onPressed: _secondsRemaining > 0
                                    ? null
                                    : () async {
                                        try {
                                          if (widget.onResendPressed != null) {
                                            await widget.onResendPressed!();
                                          } else {
                                            await AuthenticationRepository
                                                .instance
                                                .sendEmailVerification();
                                          }
                                          _startCooldown(120);
                                          Get.snackbar('Email sent',
                                              'Verification email has been sent');
                                        } catch (e) {
                                          Get.snackbar('Error', e.toString());
                                        }
                                      },
                                child: Text(
                                  _secondsRemaining > 0
                                      ? 'Resend in ${_formatRemaining(_secondsRemaining)}'
                                      : (widget.resendLabel ??
                                          UTexts.resendEmail),
                                  style: TextStyle(color: sh_colorPrimary),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
