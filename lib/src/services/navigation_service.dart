import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final List<NavigationItem> _navigationHistory = [];
  
  void pushRoute(String routeName, String title, {String? parentRoute}) {
    final item = NavigationItem(
      route: routeName,
      title: title,
      parentRoute: parentRoute,
      timestamp: DateTime.now(),
    );
    _navigationHistory.add(item);
    print('Navegación: Agregado $routeName ($title). Historial: ${_navigationHistory.length} items');
  }
  
  void popRoute() {
    if (_navigationHistory.isNotEmpty) {
      NavigationItem removed = _navigationHistory.removeLast();
      print('Navegación: Removido ${removed.route} (${removed.title}). Historial: ${_navigationHistory.length} items');
    }
  }
  
  NavigationItem? getPreviousRoute() {
    if (_navigationHistory.length >= 2) {
      return _navigationHistory[_navigationHistory.length - 2];
    }
    return null;
  }
  
  bool canGoBack() {
    return _navigationHistory.length > 1;
  }
  
  void clearHistory() {
    _navigationHistory.clear();
    print('Navegación: Historial limpiado');
  }
  
  List<NavigationItem> get history => List.from(_navigationHistory);
  
  List<NavigationItem> getBreadcrumbs() {
    return List.from(_navigationHistory);
  }
  
  // Navegar a una ruta específica y limpiar el historial desde esa ruta
  void navigateToRoute(BuildContext context, String routeName, String title, {String? parentRoute}) {
    // Si ya estamos en esa ruta, no hacer nada
    if (_navigationHistory.isNotEmpty && _navigationHistory.last.route == routeName) {
      return;
    }
    
    pushRoute(routeName, title, parentRoute: parentRoute);
  }
  
  // Navegar hacia atrás de manera inteligente
  void navigateBack(BuildContext context) {
    if (_navigationHistory.length > 1) {
      // Remover la ruta actual
      popRoute();
      
      // Obtener la ruta anterior
      final previousRoute = _navigationHistory.last;
      
      // Navegar a la ruta anterior
      Navigator.pop(context);
    } else {
      // Si no hay historial, ir al home
      Navigator.pop(context);
    }
  }
}

class NavigationItem {
  final String route;
  final String title;
  final String? parentRoute;
  final DateTime timestamp;
  
  NavigationItem({
    required this.route,
    required this.title,
    this.parentRoute,
    required this.timestamp,
  });
  
  @override
  String toString() {
    return 'NavigationItem(route: $route, title: $title, parent: $parentRoute)';
  }
}

class NavigationHelper {
  static Future<void> navigateWithHistory(
    BuildContext context, 
    Widget destination, 
    String routeName, 
    String title, {
    String? parentRoute,
  }) async {
    NavigationService().pushRoute(routeName, title, parentRoute: parentRoute);
    
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    ).then((_) {
      // Cuando se regresa de la pantalla, removemos la ruta del historial
      NavigationService().popRoute();
    });
  }
  
  static void navigateBack(BuildContext context) {
    NavigationService().navigateBack(context);
  }
  
  static Widget buildBackButton(BuildContext context, {String? customRoute}) {
    final canGoBack = NavigationService().canGoBack();
    
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: canGoBack ? () {
        if (customRoute != null) {
          Navigator.pop(context);
        } else {
          NavigationService().navigateBack(context);
        }
      } : null,
      tooltip: canGoBack ? 'Volver atrás' : 'No hay pantalla anterior',
    );
  }
  
  static Widget buildHomeButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        _navigateToHome(context);
      },
      tooltip: 'Volver al menú principal',
    );
  }
  
  static Widget buildBreadcrumbs(BuildContext context) {
    final breadcrumbs = NavigationService().getBreadcrumbs();
    
    if (breadcrumbs.length <= 1) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.navigation, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: breadcrumbs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == breadcrumbs.length - 1;
                  
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: isLast ? null : () {
                          // Navegar hacia atrás hasta esta ruta
                          _navigateToBreadcrumb(context, index);
                        },
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: isLast ? Colors.grey[800] : Colors.blue[600],
                            fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (!isLast) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  static void _navigateToHome(BuildContext context) {
    // Limpiar el historial de navegación
    NavigationService().clearHistory();
    
    // Navegar hacia atrás hasta llegar al home
    while (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
  
  static void _navigateToBreadcrumb(BuildContext context, int targetIndex) {
    final navigationService = NavigationService();
    final breadcrumbs = navigationService.getBreadcrumbs();
    
    // Calcular cuántas pantallas necesitamos hacer pop
    final currentIndex = breadcrumbs.length - 1;
    final stepsBack = currentIndex - targetIndex;
    
    // Hacer pop las veces necesarias
    for (int i = 0; i < stepsBack; i++) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        navigationService.popRoute();
      } else {
        break;
      }
    }
  }
  
  // Método para navegar a una pantalla específica con contexto
  static Future<void> navigateToScreen(
    BuildContext context,
    Widget screen,
    String routeName,
    String title, {
    String? parentRoute,
  }) async {
    await navigateWithHistory(context, screen, routeName, title, parentRoute: parentRoute);
  }
}