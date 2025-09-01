import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SidebarProvider extends ChangeNotifier {
  bool _isExpanded = false;
  
  bool get isExpanded => _isExpanded;
  
  SidebarProvider() {
    _loadState();
  }
  
  void toggleSidebar() {
    _isExpanded = !_isExpanded;
    _saveState();
    notifyListeners();
  }
  
  void setExpanded(bool expanded) {
    _isExpanded = expanded;
    _saveState();
    notifyListeners();
  }
  
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isExpanded = prefs.getBool('sidebar_expanded') ?? false;
      notifyListeners();
    } catch (e) {
      // Si hay error, usar estado por defecto
      _isExpanded = false;
    }
  }
  
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sidebar_expanded', _isExpanded);
    } catch (e) {
      // Ignorar errores de guardado
    }
  }
}
