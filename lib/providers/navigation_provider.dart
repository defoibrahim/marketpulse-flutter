import 'package:flutter/material.dart';

/// Provider for managing the bottom navigation state
class NavigationProvider with ChangeNotifier {
  NavigationProvider({int initialIndex = 0}) : _selectedIndex = initialIndex;

  int _selectedIndex;

  int get selectedIndex => _selectedIndex;

  void setIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}
