import 'package:flutter/material.dart';

class AppNavigationService {
  AppNavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  static Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) {
    final navigatorState = navigator;
    if (navigatorState == null) {
      return Future<T?>.value(null);
    }

    return navigatorState.pushNamed<T>(routeName, arguments: arguments);
  }
}
