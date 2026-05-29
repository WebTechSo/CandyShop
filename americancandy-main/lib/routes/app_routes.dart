
import 'package:american_sweets/routes/routes.dart';
import 'package:get/get.dart';

import 'package:american_sweets/screens/VerifyEmailScreen.dart';
// import '../loading.dart';

class UAppRoutes {
  static final screens = [
    // GetPage(name: URoutes.home, page: () => const LoadingScreen()),
    // GetPage(
    //   name: URoutes.store,
    //   page: () => const StoreScreen(),
    // ),
    // GetPage(
    //   name: URoutes.wishlist,
    //   page: () => const WishlistScreen(),
    // ),
    // GetPage(
    //   name: URoutes.order,
    //   page: () => const OrderScreen(),
    // ),
    // GetPage(
    //   name: URoutes.checkout,
    //   page: () => const CheckoutScreen(),
    // ),
    // GetPage(
    //   name: URoutes.cart,
    //   page: () => const CartScreen(),
    // ),
    // GetPage(
    //   name: URoutes.signup,
    //   page: () => const SignUpScreen(),
    // ),
    GetPage(
      name: URoutes.verifyEmail,
      page: () => const VerifyEmailScreen(),
    ),
    // GetPage(
    //   name: URoutes.signIn,
    //   page: () => const LoginScreen(),
    // ),
    // GetPage(
    //   name: URoutes.forgetPassword,
    //   page: () => const ForgetPasswordScreen(),
    // ),
    // GetPage(
    //   name: URoutes.onBoarding,
    //   page: () => const OnBoardingScreen(),
    // ),
  ];
}
