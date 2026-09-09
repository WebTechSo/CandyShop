import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/utils/AmStrings.dart';
import 'package:american_sweets/utils/AmWidget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:american_sweets/controllers/signup_controller.dart';
import 'package:american_sweets/data/repositories/user_repository.dart';
import 'package:american_sweets/data/services/AdminCountryService.dart';
import 'package:country_state_city/country_state_city.dart' as csc;

import 'AmSignIn.dart';

class AmSignUp extends StatefulWidget {
  static String tag = '/AmSignUp';

  final userRepo = Get.put(UserRepository());
  final controller = Get.put(SignUpController());

  @override
  AmSignUpState createState() => AmSignUpState();
}

class AmSignUpState extends State<AmSignUp> {
  final countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Australia',
    'Germany',
    'France',
    'Japan'
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final controller = SignUpController.instance;
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              width: width,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // Keep flags same as you requested
                  Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      splash_usa,
                      width: width * 0.5,
                      height: width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Image.asset(
                      splash_brazil,
                      width: width * 0.5,
                      height: width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Image.asset(
                      splash_canada,
                      width: width * 0.5,
                      height: width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Image.asset(
                      splash_japan,
                      width: width * 0.5,
                      height: width * 0.5,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: SingleChildScrollView(
                      child: Form(
                        key: controller.signupFormKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo & title
                            Image.asset(ic_app_icon, width: width * 0.22),
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [sh_gradient_1st, sh_gradient_2nd],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(Rect.fromLTWH(
                                  0, 0, bounds.width, bounds.height)),
                              child: Text(
                                "AMERICAN",
                                style: GoogleFonts.workSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "CONFECTIONERS LTD",
                              style: GoogleFonts.workSans(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: sh_colorPrimary,
                              ),
                            ),
                            32.height,

                            // -------- BUSINESS DETAILS --------
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("BUSINESS DETAILS",
                                  style: boldTextStyle(
                                      size: 18, color: sh_colorPrimary)),
                            ),
                            16.height,
                            buildInputField("Business Name",
                                controller: controller.businessNameCont,
                                required: true),
                            12.height,
                            buildDropdownField(
                                "Country of Registration",
                                (val) => controller
                                    .registrationCountryCont.value = val ?? '',
                                selectedValue:
                                    controller.registrationCountryCont,
                                countriesList: controller.variantCountries),
                            12.height,
                            buildInputField("Registration Number",
                                controller: controller.registrationNumberCont),
                            24.height,

                            // -------- CONTACT DETAILS --------
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("CONTACT & SIGNUP DETAILS",
                                  style: boldTextStyle(
                                      size: 18, color: sh_colorPrimary)),
                            ),
                            16.height,
                            buildInputField("Full Name",
                                controller: controller.fullNameCont,
                                required: true),
                            12.height,
                            buildInputField("Email",
                                keyboardType: TextInputType.emailAddress,
                                controller: controller.emailCont,
                                required: true, validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return 'Email is required';
                              final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                              if (!re.hasMatch(val)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            }),
                            12.height,
                            buildInputField("Contact Telephone Number",
                                keyboardType: TextInputType.phone,
                                controller: controller.contactNumberCont,
                                required: true, validator: (v) {
                              final digits =
                                  (v ?? '').replaceAll(RegExp(r'\D'), '');
                              if (digits.isEmpty) {
                                return 'Telephone is required';
                              }
                              if (digits.length < 7) {
                                return 'Enter a valid telephone number';
                              }
                              return null;
                            },
                                prefixText: (controller
                                                    .variantCountryDialByName[
                                                controller
                                                    .registrationCountryCont
                                                    .value] ??
                                            '')
                                        .isNotEmpty
                                    ? '${controller.variantCountryDialByName[controller.registrationCountryCont.value]} '
                                    : null),
                            12.height,
                            buildInputField("Whatsapp Number",
                                keyboardType: TextInputType.phone,
                                controller: controller.whatsappNumberCont,
                                required: true, validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty)
                                return 'Whatsapp Number is required';
                              return null;
                            },
                                prefixText: (controller
                                                    .variantCountryDialByName[
                                                controller
                                                    .registrationCountryCont
                                                    .value] ??
                                            '')
                                        .isNotEmpty
                                    ? '${controller.variantCountryDialByName[controller.registrationCountryCont.value]} '
                                    : null),
                            12.height,
                            buildInputField("Password",
                                isPassword: true,
                                controller: controller.passwordCont,
                                required: true, validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return 'Password is required';
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            }),
                            24.height,

                            // -------- TERMS & CONDITIONS --------
                            Row(
                              children: [
                                Obx(() => Checkbox(
                                      value: controller.termsAccepted.value,
                                      onChanged: (value) {
                                        controller.termsAccepted.value =
                                            value ?? false;
                                      },
                                      activeColor: sh_colorPrimary,
                                    )),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: primaryTextStyle(size: 14),
                                      children: [
                                        const TextSpan(text: "I agree to the "),
                                        TextSpan(
                                          text: "Terms and Conditions",
                                          style: primaryTextStyle(
                                              color: sh_colorPrimary,
                                              decoration:
                                                  TextDecoration.underline),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              toast(
                                                  "Open Terms and Conditions");
                                            },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            24.height,

                            // -------- BUTTONS --------
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: MaterialButton(
                                padding: EdgeInsets.all(spacing_standard),
                                child: text("Create an Account",
                                    fontSize: textSizeNormal,
                                    fontFamily: fontMedium,
                                    textColor: sh_white),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40.0)),
                                color: sh_colorPrimary,
                                onPressed: () {
                                  final form =
                                      controller.signupFormKey.currentState;
                                  if (form != null && form.validate()) {
                                    controller.registerUser();
                                  } else {
                                    toast(
                                        "Please fill all mandatory fields correctly");
                                  }
                                },
                              ),
                            ),
                            16.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have an account? ",
                                    style: primaryTextStyle(size: 14)),
                                GestureDetector(
                                  onTap: () {
                                    AmSignIn().launch(context);
                                  },
                                  child: Text("Login",
                                      style: primaryTextStyle(
                                          color: sh_colorPrimary,
                                          decoration:
                                              TextDecoration.underline)),
                                ),
                              ],
                            ),
                            32.height,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() => controller.isLoading.value
              ? Container(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(color: sh_colorPrimary),
                  ),
                )
              : SizedBox()),
        ],
      ),
    );
  }

// Simple reusable text input with light border
  Widget buildInputField(String hint,
      {TextInputType keyboardType = TextInputType.text,
      bool isPassword = false,
      TextEditingController? controller,
      bool required = false,
      String? prefixText,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: (value) {
        if (validator != null) return validator(value);
        if (required) {
          final v = value?.trim() ?? '';
          if (v.isEmpty) return '$hint is required';
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: primaryTextStyle(),
      decoration: InputDecoration(
        labelText: required ? '$hint *' : hint,
        labelStyle: primaryTextStyle(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixText: prefixText,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: sh_colorPrimary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: context.cardColor,
      ),
    );
  }

  Widget buildStateDropdownField({
    required SignUpController controller,
    required RxString selectedCountry,
    required TextEditingController stateController,
  }) {
    return Obx(() {
      final countryName = selectedCountry.value.trim();
      final iso = controller.variantCountryIsoByName[countryName] ?? '';
      if (iso.trim().isEmpty) {
        return buildInputField("State",
            controller: stateController, required: true);
      }
      return FutureBuilder<List<csc.State>>(
        future: AdminCountryService.instance.getStatesForCountryIso(iso),
        builder: (context, snapshot) {
          final states = snapshot.data ?? <csc.State>[];
          if (states.isEmpty) {
            return buildInputField("State",
                controller: stateController, required: true);
          }
          final current = stateController.text.trim();
          final hasCurrent = current.isNotEmpty &&
              states.any((s) => s.name.toLowerCase() == current.toLowerCase());
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: "State *",
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: sh_colorPrimary, width: 1),
              ),
              filled: true,
              fillColor: context.cardColor,
            ),
            value: hasCurrent ? current : null,
            items: states
                .map((s) => DropdownMenuItem<String>(
                    value: s.name, child: Text(s.name)))
                .toList(),
            onChanged: (v) {
              stateController.text = v ?? '';
            },
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return 'State is required';
              return null;
            },
          );
        },
      );
    });
  }

  Widget buildDropdownField(String label, Function(String?) onChanged,
      {RxString? selectedValue, RxList<String>? countriesList}) {
    return Obx(() {
      final items = countriesList?.toList() ?? <String>[];
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          hintText: label,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: sh_colorPrimary, width: 1),
          ),
          filled: true,
          fillColor: context.cardColor,
        ),
        value: selectedValue != null && selectedValue.value.isNotEmpty
            ? selectedValue.value
            : null,
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      );
    });
  }
}
