import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:american_sweets/controllers/admin_login_controller.dart';
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmImages.dart';
import 'package:american_sweets/screens/AmHomeScreen.dart';
import 'package:american_sweets/screens/AmSignIn.dart';
import 'package:american_sweets/screens/AmWalkThroughScreen.dart';

class AmAdminLoginScreen extends StatefulWidget {
  const AmAdminLoginScreen({super.key});

  @override
  State<AmAdminLoginScreen> createState() => _AmAdminLoginScreenState();
}

class _AmAdminLoginScreenState extends State<AmAdminLoginScreen> {
  final AdminLoginController controller = Get.put(AdminLoginController());
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top;

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
            Positioned(
              top: topInset + 8,
              left: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: sh_textColorPrimary),
                  onPressed: () => Get.back(),
                  tooltip: 'Back',
                ),
              ),
            ),
            Positioned(
              top: topInset + 8,
              right: 8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                child: IconButton(
                  icon: Icon(Icons.home, color: sh_textColorPrimary),
                  onPressed: () => Get.offAll(() => AmHomeScreen()),
                  tooltip: 'Home',
                ),
              ),
            ),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // App Logo & Title
                      Image.asset(ic_app_icon, width: width * 0.22),
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
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Sweets",
                        style: GoogleFonts.workSans(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: sh_colorPrimary,
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "Admin Portal",
                        style: GoogleFonts.workSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: sh_textColorPrimary,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email Field
                      TextFormField(
                        controller: controller.emailCont,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: "Admin Email",
                          prefixIcon: Icon(Icons.admin_panel_settings),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter email';
                          if (!value.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      TextFormField(
                        controller: controller.passwordCont,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter password';
                          return null;
                        },
                      ),

                      const SizedBox(height: 30),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Obx(() => MaterialButton(
                              padding: EdgeInsets.all(spacing_standard),
                              child: controller.isLoading.value
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text("Login to Dashboard",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40.0)),
                              color: sh_colorPrimary,
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () => controller.adminLogin(),
                            )),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Get.offAll(() => AmSignIn()),
                            child: Text("User login",
                                style: TextStyle(color: sh_textColorSecondary)),
                          ),
                          TextButton(
                            onPressed: () =>
                                Get.offAll(() => AmWalkThroughScreen()),
                            child: Text("Back to App",
                                style: TextStyle(color: sh_textColorSecondary)),
                          ),
                        ],
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
