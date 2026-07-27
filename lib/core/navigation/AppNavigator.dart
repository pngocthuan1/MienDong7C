import 'package:flutter/material.dart';

class AppNavigator {
  const AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> pushNamedGlobal(
    String routeName, {
    Object? arguments,
  }) async {
    try {
      await navigatorKey.currentState?.pushNamed(
        routeName,
        arguments: arguments,
      );
    } catch (_) {}
  }

  static Future<void> pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      await Navigator.pushNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } catch (_) {}
  }

  static Future<void> replaceNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      await Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: arguments,
      );
    } catch (_) {}
  }

  static Future<void> replaceAndKeepRoot(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      await Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
        (route) => route.isFirst,
        arguments: arguments,
      );
    } catch (_) {}
  }

  static Future<void> resetToNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    try {
      await Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
        (route) => false,
        arguments: arguments,
      );
    } catch (_) {}
  }

  static void forwardAfterBuild(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replaceCurrent = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) {
        return;
      }

      if (replaceCurrent) {
        replaceNamed(context, routeName, arguments: arguments);
      } else {
        pushNamed(context, routeName, arguments: arguments);
      }
    });
  }

  static void safePop<T extends Object?>(BuildContext context, [T? result]) {
    try {
      if (Navigator.canPop(context)) {
        Navigator.pop(context, result);
      }
    } catch (_) {}
  }
}
