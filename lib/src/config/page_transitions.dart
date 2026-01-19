import 'package:flutter/material.dart';

/// Transiciones de página modernas y fluidas
class PageTransitions {
  /// Transición fade (desvanecimiento) - Simple y moderna
  static Route<T> fadeRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  /// Transición scale (escala) - Moderna y suave
  static Route<T> scaleRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }

  /// Transición slide horizontal suave - Más fluida que la predeterminada
  static Route<T> slideRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
    bool fromRight = true,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offset = fromRight
            ? const Offset(1.0, 0.0)
            : const Offset(-1.0, 0.0);
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Transición sin animación - Instantánea
  static Route<T> noTransitionRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  /// Transición fade suave - Moderna, simple y fluida (RECOMENDADA)
  static Route<T> modernRoute<T extends Object?>(
    Widget page, {
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Curva de animación suave y moderna
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic, // Más suave que easeOut
        );
        
        // Solo fade - simple y fluido, sin efectos exagerados
        return FadeTransition(
          opacity: curvedAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 180), // Rápido pero suave
      reverseTransitionDuration: const Duration(milliseconds: 150), // Más rápido al volver
    );
  }
}

