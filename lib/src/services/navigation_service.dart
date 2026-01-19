import 'package:flutter/material.dart';
import '../config/app_routes.dart';

/// Servicio simplificado de navegación usando rutas nombradas
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navegar a una ruta específica
  Future<T?>? navigateTo<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navegar y reemplazar la ruta actual
  Future<T?>? navigateToReplacement<T extends Object?, TO extends Object?>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
    );
  }

  /// Navegar y eliminar todas las rutas anteriores
  Future<T?>? navigateToAndRemoveUntil<T>(
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil<T>(
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Volver atrás
  void goBack<T>([T? result]) {
    if (canGoBack()) {
      navigatorKey.currentState?.pop<T>(result);
    }
  }

  /// Verificar si se puede volver atrás
  bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  /// Ir al home y limpiar el stack
  void goToHome() {
    navigateToAndRemoveUntil(AppRoutes.home);
  }

  /// Ir al login y limpiar el stack
  void goToLogin() {
    navigateToAndRemoveUntil(AppRoutes.login);
  }
}

/// Helper estático para facilitar la navegación
class NavigationHelper {
  static final NavigationService _service = NavigationService();

  /// Navegar a una pantalla
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    return await Navigator.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navegar y reemplazar
  static Future<T?> navigateToReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    return await Navigator.pushReplacementNamed<T, TO>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Navegar y limpiar stack
  static Future<T?> navigateToAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) async {
    return await Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Volver atrás
  static void goBack<T>(BuildContext context, [T? result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop<T>(context, result);
    }
  }

  /// Botón de retroceso
  static Widget buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: Navigator.canPop(context)
          ? () => Navigator.pop(context)
          : null,
      tooltip: 'Volver atrás',
    );
  }

  /// Botón de home
  static Widget buildHomeButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        _navigateToHome(context);
      },
      tooltip: 'Volver al menú principal',
    );
  }

  /// Breadcrumbs simplificados (opcional, puedes mantenerlos si los usas)
  static Widget buildBreadcrumbs(BuildContext context) {
    // Si quieres mantener breadcrumbs, puedes implementarlos aquí
    // Por ahora retornamos un widget vacío
    return const SizedBox.shrink();
  }

  /// Navegar al home
  static void _navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  /// Obtener título de la ruta actual
  static String getCurrentRouteTitle(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null) {
      return AppRoutes.getRouteTitle(route.settings.name ?? '');
    }
    return 'Portal Web';
  }
}
