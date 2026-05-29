import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:american_sweets/utils/AmColors.dart';

class AppThemeData {
  AppThemeData._();

  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: whiteColor,
    primaryColor: appColorPrimary,
    primaryColorDark: appColorPrimary,
    hoverColor: Colors.white54,
    dividerColor: viewLineColor,
    fontFamily: GoogleFonts.openSans().fontFamily,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? sh_colorPrimary
            : Colors.grey.shade400,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? sh_gradient_2nd.withValues(alpha: 0.6)
            : Colors.black26,
      ),
    ),
    appBarTheme: AppBarTheme(
      color: appLayout_background,
      iconTheme: IconThemeData(color: textPrimaryColor),
      systemOverlayStyle:
      SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.black),
    cardTheme: CardThemeData( // 🔥 FIXED
      color: Colors.white,
    ),
    cardColor: Colors.white,
    iconTheme: IconThemeData(color: textPrimaryColor),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: whiteColor),
    textTheme: TextTheme(
      labelLarge: TextStyle(color: appColorPrimary),
      titleLarge: TextStyle(color: textPrimaryColor),
      titleSmall: TextStyle(color: textSecondaryColor),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.light(primary: appColorPrimary)
        .copyWith(error: Colors.red),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
    }),
  );

  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: appBackgroundColorDark,
    highlightColor: appBackgroundColorDark,
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? sh_colorPrimary
            : Colors.grey.shade600,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? sh_gradient_2nd.withValues(alpha: 0.5)
            : Colors.white24,
      ),
    ),
    appBarTheme: AppBarTheme(
      color: appBackgroundColorDark,
      iconTheme: IconThemeData(color: whiteColor),
      systemOverlayStyle:
      SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light),
      titleTextStyle: primaryTextStyle(color: whiteColor, size: 18),
    ),
    primaryColor: color_primary_black,
    dividerColor: Color(0xFFDADADA).withOpacity(0.3),
    primaryColorDark: color_primary_black,
    textSelectionTheme: TextSelectionThemeData(cursorColor: Colors.white),
    hoverColor: Colors.black12,
    fontFamily: GoogleFonts.openSans().fontFamily,
    bottomSheetTheme:
    BottomSheetThemeData(backgroundColor: appBackgroundColorDark),
    primaryTextTheme: TextTheme(
      titleLarge: primaryTextStyle(color: Colors.white),
      labelSmall: primaryTextStyle(color: Colors.white),
    ),
    cardTheme: CardThemeData( // 🔥 FIXED
      color: cardBackgroundBlackDark,
    ),
    cardColor: appSecondaryBackgroundColor,
    iconTheme: IconThemeData(color: whiteColor),
    textTheme: TextTheme(
      labelLarge: TextStyle(color: whiteColor),
      titleLarge: TextStyle(color: whiteColor),
      titleSmall: TextStyle(color: Colors.white70),
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: ColorScheme.dark(
      primary: appBackgroundColorDark,
      onPrimary: cardBackgroundBlackDark,
    ).copyWith(secondary: whiteColor).copyWith(error: Color(0xFFCF6676)),
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: OpenUpwardsPageTransitionsBuilder(),
    }),
  );
}
