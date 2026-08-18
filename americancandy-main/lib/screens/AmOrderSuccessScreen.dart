import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/main.dart'; // Needed for appStore and possibly AmHomeScreen
import 'package:american_sweets/utils/AmColors.dart';
import 'package:american_sweets/utils/AmConstant.dart';
import 'AmHomeScreen.dart';

// NOTE: You will need to replace 'AmHomeScreen()' with your actual home screen widget.
// Assuming your home screen is defined elsewhere and is accessible.
// For demonstration, let's assume you have a primary screen called 'AmDashBoardScreen'
// which typically houses the Bottom Navigation Bar/Home content.

class AmOrderSuccessScreen extends StatelessWidget {
  static String tag = '/AmOrderSuccessScreen';
  final String orderNumber;
  final String paymentMethod;

  // Constructor to receive the order number
  AmOrderSuccessScreen({required this.orderNumber, required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    // Determine the color of the success icon/text based on theme
    Color successColor = Colors.green;
    Color textColor = appStore.isDarkModeOn ? white : sh_textColorPrimary;

    return Scaffold(
      // Prevents the user from going back with the hardware/system back button
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: context.scaffoldBackgroundColor,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing_standard_new),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Brand logo and name
              Image.asset(
                'images/american-confectioners-ltd.png',
                width: 260,
                height: 90,
                fit: BoxFit.contain,
              ),
              8.height,
              Text(
                'Sweet Stop',
                style: boldTextStyle(size: 20, color: textColor),
              ),
              24.height,
              // 1. Success Icon (Checkmark)
              Icon(
                Icons.check_circle,
                color: successColor,
                size: 100,
              ),

              32.height,

              // 2. Bold Success Message
              Text(
                'Thank you for your order!',
                textAlign: TextAlign.center,
                style: boldTextStyle(size: 24, color: textColor),
              ),
              8.height,
              if(paymentMethod.toLowerCase == 'bank transfer')
                Text(
                  'Your payment was successful, and we’ve received your order.',
                  textAlign: TextAlign.center,
                  style: primaryTextStyle(size: 16, color: textColor),
                )
              else
                Text(
                  'We’ve received your order.',
                  textAlign: TextAlign.center,
                  style: primaryTextStyle(size: 16, color: textColor),
                ),
              16.height,

              // 3. Confirmation Email Text
              Text(
                'A confirmation email has been sent to your email address with order details.',
                textAlign: TextAlign.center,
                style: secondaryTextStyle(size: 14),
              ),

              16.height,

              // 4. Order Number Text
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: 'Order ID: ',
                  style: primaryTextStyle(size: 16, color: textColor),
                  children: <TextSpan>[
                    TextSpan(
                      text: '#$orderNumber',
                      style: boldTextStyle(size: 16, color: textColor),
                    ),
                  ],
                ),
              ),

              16.height,

              // 5. Follow-up Text
              Text(
                'Our team will contact you shortly regarding delivery and next steps.',
                textAlign: TextAlign.center,
                style: secondaryTextStyle(size: 14),
              ),

              64.height,

              // 4. Continue Shopping Button
              AppButton(
                width: context.width() * 0.7, // Set button width
                onTap: () {
                  // Navigate back to the home screen and clear all previous routes
                  // Replace 'AmDashBoardScreen()' with your actual home/dashboard widget
                  AmHomeScreen().launch(context);
                },

                text: "Continue Shopping",
                color: sh_colorPrimary, // Primary color for the button
                textColor: white,
                textStyle: boldTextStyle(color: white),
                shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Example usage to call this screen:
/* AmOrderSuccessScreen(orderNumber: '123456789').launch(context);
*/
