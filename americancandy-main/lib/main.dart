import 'package:american_sweets/data/repositories/category_repository.dart';
import 'package:american_sweets/data/services/branch_services.dart';
import 'package:american_sweets/data/repositories/authentication_repository.dart';
import 'package:american_sweets/utils/constants/keys.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get_storage/get_storage.dart';
import 'firebase_options.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/screens/AmSplashScreen.dart';
import 'package:american_sweets/store/AppStore.dart';
import 'package:american_sweets/utils/AppTheme.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'package:american_sweets/utils/AmDataGenerater.dart';
import 'package:get/get.dart';
import 'package:american_sweets/routes/app_routes.dart';
import 'package:flutter/foundation.dart';

// import 'data/repositories/authentication/controllers/login/login_controller.dart';

import 'package:american_sweets/screens/AmNewPasswordScreen.dart';
import 'package:app_links/app_links.dart';

// Helper to handle deep links
void _handleDeepLink(Uri deepLink) {
  print('Deep Link Received: $deepLink');

  if (deepLink.queryParameters.containsKey('oobCode')) {
    final oobCode = deepLink.queryParameters['oobCode'];
    if (oobCode != null) {
      Get.offAll(() => AmNewPasswordScreen(oobCode: oobCode));
    }
  }
}

AppStore appStore = AppStore();

Future<void> main() async {
  /// Widgets Flutter Binding
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  /// Flutter Native Splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  /// Get Storage Initialization
  await GetStorage.init();

  /// Initialize Branch SDK
  if (!kIsWeb) {
    Get.put(BranchServices()).initBranch();
  }

  /// Initialize Publishable Key
  if (!kIsWeb) {
    Stripe.publishableKey = UKeys.stripePublishableKey;
  }

  /// Firebase Initialization
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      .then((value) {
    Get.put(AuthenticationRepository());
  });

  // Handle Deep Links for Password Reset
  if (!kIsWeb) {
    try {
      final _appLinks = AppLinks();

      // Check initial link
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }

      // Listen to link stream
      _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      }).onError((error) {
        print('Deep Link Failed: $error');
      });
    } catch (e) {
      print('Deep Link Error: $e');
    }
  }

  /// Portrait Up The Device
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  await initialize(aLocaleLanguageList: languageList());

  appStore.toggleDarkMode(value: getBoolAsync(isDarkModeOnPref));

  defaultToastGravityGlobal = ToastGravity.BOTTOM;

  // REMOVE SPLASH AFTER INITIALIZATION
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AmericanSweet${!isMobile ? ' ${platformName()}' : ''}',
        home: AmSplashScreen(),
        theme: !appStore.isDarkModeOn
            ? AppThemeData.lightTheme
            : AppThemeData.darkTheme,
        navigatorKey: Get.key,
        scrollBehavior: SBehavior(),
        supportedLocales: LanguageDataModel.languageLocales(),
        localeResolutionCallback: (locale, supportedLocales) => locale,
        getPages: UAppRoutes.screens,
      ),
    );
  }
}
