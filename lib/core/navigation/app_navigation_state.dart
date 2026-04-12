import 'package:flutter/material.dart';

class AppNavigationState extends ChangeNotifier {
  late final AppNavigatorObserver observer = AppNavigatorObserver._(this);

  String? _currentRouteName;
  Object? _currentRouteArguments;
  int _selectedTabIndex = 0;
  bool _notificationScheduled = false;

  int get selectedTabIndex => _selectedTabIndex;

  String? get currentRouteName => _currentRouteName;
  Object? get currentRouteArguments => _currentRouteArguments;

  bool isCurrentRoute(String routeName) => _currentRouteName == routeName;

  void _updateRoute(Route<dynamic>? route) {
    final settings = route?.settings;
    final routeName = settings?.name;
    final routeArguments = settings?.arguments;
    if (_currentRouteName == routeName &&
        identical(_currentRouteArguments, routeArguments)) {
      return;
    }
    _currentRouteName = routeName;
    _currentRouteArguments = routeArguments;
    _scheduleNotification();
  }

  void setSelectedIndex(int index) {
    if (_selectedTabIndex == index) return;
    _selectedTabIndex = index;
    notifyListeners();
  }

  void _scheduleNotification() {
    if (_notificationScheduled) return;
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      notifyListeners();
    });
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  AppNavigatorObserver._(this._navigationState);

  final AppNavigationState _navigationState;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _navigationState._updateRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _navigationState._updateRoute(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _navigationState._updateRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
