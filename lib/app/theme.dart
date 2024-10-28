import 'dart:math' show max;

import 'package:flutter/material.dart';

class SphiaTheme {
  static ThemeData darkTheme(
    int themeColorInt,
    BuildContext context,
  ) {
    final themeColor = Color(themeColorInt);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      drawerTheme: DrawerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        width: max(MediaQuery.of(context).size.width / 7.5 + 15, 150),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        tileHeight: 50,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        indicatorColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: themeColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        toolbarTextStyle: const TextStyle(color: Colors.white),
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: themeColor,
        labelColor: Colors.white,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColor;
          } else {
            return Colors.white;
          }
        }),
        trackColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColor.withOpacity(0.5);
          } else {
            return Colors.transparent;
          }
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      colorScheme: ColorScheme.dark(
        primary: themeColor,
        primaryContainer: themeColor,
        secondary: themeColor,
        secondaryContainer: themeColor,
        surface: Colors.grey[900]!,
        surfaceTint: Colors.grey[100],
      ),
      cardColor: Colors.grey[800]!,
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            if (states.contains(WidgetState.disabled)) {
              return themeColor.withOpacity(0.5);
            } else {
              return themeColor;
            }
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: themeColor.withOpacity(0.1), width: 2);
            } else {
              return BorderSide(color: themeColor, width: 2);
            }
          } else if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: themeColor.withOpacity(0.5), width: 2);
          }
          return BorderSide(color: themeColor, width: 2);
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashRadius: 0,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static ThemeData lightTheme(
    int themeColorInt,
    BuildContext context,
  ) {
    final themeColor = Color(themeColorInt);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      drawerTheme: DrawerThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        width: max(MediaQuery.of(context).size.width / 7.5 + 15, 150),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(
        tileHeight: 50,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
        indicatorColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        foregroundColor: Colors.grey,
        titleTextStyle: TextStyle(
          color: themeColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        toolbarTextStyle: const TextStyle(color: Colors.black),
      ),
      tabBarTheme: TabBarTheme(
        indicatorColor: themeColor,
        labelColor: Colors.black,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: CircleBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColor;
          } else {
            return Colors.black;
          }
        }),
        trackColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return themeColor.withOpacity(0.5);
          } else {
            return Colors.transparent;
          }
        }),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: themeColor,
        primaryContainer: themeColor,
        secondary: themeColor,
        secondaryContainer: themeColor,
        surface: Colors.grey[200]!,
        surfaceTint: Colors.grey[850],
      ),
      cardColor: Colors.grey[100],
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            if (states.contains(WidgetState.disabled)) {
              return themeColor.withOpacity(0.5);
            } else {
              return themeColor;
            }
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: themeColor.withOpacity(0.1), width: 2);
            } else {
              return BorderSide(color: themeColor, width: 2);
            }
          } else if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: themeColor.withOpacity(0.5), width: 2);
          }
          return BorderSide(color: themeColor, width: 2);
        }),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashRadius: 0,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
