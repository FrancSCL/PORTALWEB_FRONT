# Guía de Navegación - Sistema Mejorado

## ✅ Cambios Implementados

Se ha implementado un sistema de navegación **sencillo, escalable y mantenible** usando rutas nombradas de Flutter.

### 📁 Archivos Creados/Modificados

1. **`lib/src/config/app_routes.dart`** (NUEVO)
   - Centraliza todas las rutas de la aplicación
   - Define constantes para cada ruta
   - Generador de rutas con `generateRoute()`
   - Función para obtener títulos de rutas

2. **`lib/src/services/navigation_service.dart`** (REFACTORIZADO)
   - Simplificado y mejorado
   - Usa rutas nombradas en lugar de MaterialPageRoute directo
   - Mantiene funcionalidad de navegación inteligente

3. **`lib/main.dart`** (ACTUALIZADO)
   - Configurado con `navigatorKey` global
   - Usa `onGenerateRoute` para manejar todas las rutas
   - `initialRoute` configurado

4. **`lib/src/app.dart`** (ACTUALIZADO)
   - Usa NavigationService para redirecciones automáticas

5. **`lib/src/widgets/persistent_sidebar.dart`** (ACTUALIZADO)
   - Usa rutas nombradas en lugar de instanciar widgets directamente

6. **`lib/src/screens/home_screen.dart`** (ACTUALIZADO)
   - Usa rutas nombradas para navegación

---

## 🚀 Cómo Usar la Nueva Navegación

### Navegación Básica

```dart
// Navegar a una pantalla
NavigationHelper.navigateTo(context, AppRoutes.estimaciones);

// Navegar y reemplazar (útil para login)
NavigationHelper.navigateToReplacement(context, AppRoutes.home);

// Navegar y limpiar stack (útil para logout)
NavigationHelper.navigateToAndRemoveUntil(context, AppRoutes.login);

// Volver atrás
NavigationHelper.goBack(context);
```

### Usando NavigationService (sin contexto)

```dart
// Obtener la instancia
final navService = NavigationService();

// Navegar
navService.navigateTo(AppRoutes.estimaciones);

// Ir al home
navService.goToHome();

// Ir al login
navService.goToLogin();
```

### Rutas Disponibles

Todas las rutas están definidas en `AppRoutes`:

```dart
// Autenticación
AppRoutes.splash
AppRoutes.login
AppRoutes.home

// Módulos principales
AppRoutes.estimaciones
AppRoutes.pautasGestion
AppRoutes.mapeo
AppRoutes.adminUsuarios
AppRoutes.parametros

// Pautas
AppRoutes.pautasCrear
AppRoutes.pautasFormulario
AppRoutes.pautasFormularioDinamico
AppRoutes.pautasConfiguracion

// Conteo
AppRoutes.conteoAtributoEspecie
AppRoutes.conteoAtributoOptimo
AppRoutes.manejoParametrosConteo

// Configuración
AppRoutes.cambiarClave
AppRoutes.cambiarSucursal

// Reportes
AppRoutes.historialCuartel
AppRoutes.muestras
AppRoutes.produccion
AppRoutes.riego
AppRoutes.actividades

// Testing
AppRoutes.lookerTest
```

---

## 📝 Agregar una Nueva Ruta

### Paso 1: Agregar la constante en `app_routes.dart`

```dart
class AppRoutes {
  // ... rutas existentes
  
  static const String miNuevaPantalla = '/mi-nueva-pantalla';
  
  // Agregar el título
  static String getRouteTitle(String route) {
    switch (route) {
      // ... casos existentes
      case miNuevaPantalla:
        return 'Mi Nueva Pantalla';
      // ...
    }
  }
}
```

### Paso 2: Agregar el caso en `generateRoute()`

```dart
static Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // ... casos existentes
    
    case miNuevaPantalla:
      return MaterialPageRoute(
        builder: (_) => const MiNuevaPantallaScreen(),
      );
    
    // ...
  }
}
```

### Paso 3: Usar la ruta en tu código

```dart
// En cualquier lugar de tu código
NavigationHelper.navigateTo(context, AppRoutes.miNuevaPantalla);
```

---

## 🎯 Ventajas del Nuevo Sistema

### ✅ Sencillo
- Una sola forma de navegar
- Código más limpio y legible
- Menos repetición

### ✅ Escalable
- Fácil agregar nuevas rutas
- Centralizado en un solo archivo
- Fácil de mantener

### ✅ Mantenible
- Todas las rutas en un solo lugar
- Cambios en una pantalla no afectan otras
- Fácil de refactorizar

### ✅ Consistente
- Mismo patrón en toda la app
- Menos errores
- Más predecible

---

## 🔄 Migración de Código Existente

### Antes (Viejo Sistema)
```dart
// ❌ Antes
NavigationHelper.navigateToScreen(
  context,
  const EstimacionesScreen(),
  '/estimaciones',
  'Estimaciones',
  parentRoute: '/',
);
```

### Después (Nuevo Sistema)
```dart
// ✅ Ahora
NavigationHelper.navigateTo(context, AppRoutes.estimaciones);
```

### Antes (Viejo Sistema)
```dart
// ❌ Antes
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const MapeoScreen()),
);
```

### Después (Nuevo Sistema)
```dart
// ✅ Ahora
NavigationHelper.navigateTo(context, AppRoutes.mapeo);
```

---

## 📚 Ejemplos de Uso

### Ejemplo 1: Navegación desde un botón

```dart
ElevatedButton(
  onPressed: () {
    NavigationHelper.navigateTo(context, AppRoutes.estimaciones);
  },
  child: const Text('Ver Estimaciones'),
)
```

### Ejemplo 2: Navegación después de una acción

```dart
Future<void> _crearPauta() async {
  // ... lógica de creación
  
  // Navegar a la pantalla de gestión
  NavigationHelper.navigateToReplacement(
    context,
    AppRoutes.pautasGestion,
  );
}
```

### Ejemplo 3: Logout

```dart
Future<void> _logout() async {
  await authProvider.logout();
  NavigationHelper.navigateToAndRemoveUntil(
    context,
    AppRoutes.login,
  );
}
```

### Ejemplo 4: Navegación condicional

```dart
void _navegarSegunRol() {
  if (usuario.esAdmin) {
    NavigationHelper.navigateTo(context, AppRoutes.adminUsuarios);
  } else {
    NavigationHelper.navigateTo(context, AppRoutes.estimaciones);
  }
}
```

---

## 🛠️ Troubleshooting

### Problema: "Route not found"
**Solución**: Verifica que la ruta esté definida en `AppRoutes` y en `generateRoute()`

### Problema: "Navigator operation requested with a context that does not include a Navigator"
**Solución**: Asegúrate de tener un `BuildContext` válido. Usa `NavigationService()` si no tienes contexto.

### Problema: La pantalla no se muestra
**Solución**: Verifica que el widget esté importado correctamente en `app_routes.dart`

---

## 📊 Comparación

| Aspecto | Sistema Anterior | Sistema Nuevo |
|---------|------------------|---------------|
| Líneas de código | ~250 | ~150 |
| Archivos de rutas | Dispersas | 1 centralizado |
| Mantenibilidad | Media | Alta |
| Escalabilidad | Baja | Alta |
| Consistencia | Baja | Alta |
| Facilidad de uso | Media | Alta |

---

## ✅ Checklist de Migración

Si tienes código que aún usa el sistema antiguo:

- [ ] Reemplazar `NavigationHelper.navigateToScreen()` por `NavigationHelper.navigateTo()`
- [ ] Reemplazar `Navigator.push(MaterialPageRoute(...))` por rutas nombradas
- [ ] Reemplazar `Navigator.pushReplacementNamed()` por `NavigationHelper.navigateToReplacement()`
- [ ] Actualizar `currentRoute` en `MainScaffold` para usar `AppRoutes.*`
- [ ] Verificar que todas las rutas estén en `app_routes.dart`

---

**Versión**: 2.0.0  
**Fecha**: Diciembre 2024  
**Estado**: ✅ Implementado y Funcional

