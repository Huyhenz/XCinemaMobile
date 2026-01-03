import 'package:flutter/material.dart';

class NavigationProvider extends InheritedWidget {
  final Function(int) navigateTo;
  final int currentIndex;
  final bool isAdmin;

  const NavigationProvider({
    super.key,
    required super.child,
    required this.navigateTo,
    required this.currentIndex,
    required this.isAdmin,
  });

  static NavigationProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NavigationProvider>();
  }

  @override
  bool updateShouldNotify(NavigationProvider oldWidget) {
    return currentIndex != oldWidget.currentIndex ||
        isAdmin != oldWidget.isAdmin ||
        navigateTo != oldWidget.navigateTo;
  }
}

