import 'package:flutter/material.dart';
import '../app.dart';
import 'page_transitions.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/estimaciones_screen.dart';
import '../screens/pautas_gestion_screen.dart';
import '../screens/pautas_crear_nueva_screen.dart';
import '../screens/pautas_formulario_screen.dart';
import '../screens/pautas_formulario_dinamico_screen.dart';
import '../screens/pautas_configuracion_screen.dart';
import '../screens/mapeo_screen.dart';
import '../screens/conteo_atributo_especie_screen.dart';
import '../screens/conteo_atributo_optimo_screen.dart';
import '../screens/manejo_parametros_conteo_screen.dart';
import '../screens/admin_usuarios_screen.dart';
import '../screens/parametros_screen.dart';
import '../screens/configuracion_asociaciones_screen.dart';
import '../screens/muestras_screen.dart';
import '../screens/produccion_screen.dart';
import '../screens/riego_screen.dart';
import '../screens/actividades_screen.dart';
import '../screens/cambiar_clave_screen.dart';
import '../screens/cambiar_sucursal_screen.dart';
import '../screens/historial_cuartel_screen.dart';
import '../screens/looker_test_screen.dart';

/// Rutas centralizadas de la aplicación
class AppRoutes {
  // Rutas principales
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  
  // Módulos principales
  static const String estimaciones = '/estimaciones';
  static const String pautasGestion = '/pautas';
  static const String pautasCrear = '/pautas/crear';
  static const String pautasFormulario = '/pautas/formulario';
  static const String pautasFormularioDinamico = '/pautas/formulario-dinamico';
  static const String pautasConfiguracion = '/pautas/configuracion';
  
  static const String mapeo = '/mapeo';
  
  static const String conteoAtributoEspecie = '/conteo/atributo-especie';
  static const String conteoAtributoOptimo = '/conteo/atributo-optimo';
  static const String manejoParametrosConteo = '/conteo/parametros';
  
  static const String adminUsuarios = '/admin/usuarios';
  
  static const String parametros = '/parametros';
  static const String configuracionAsociaciones = '/parametros/asociaciones';
  
  static const String muestras = '/muestras';
  static const String produccion = '/produccion';
  static const String riego = '/riego';
  static const String actividades = '/actividades';
  
  // Configuración de usuario
  static const String cambiarClave = '/configuracion/cambiar-clave';
  static const String cambiarSucursal = '/configuracion/cambiar-sucursal';
  
  // Reportes
  static const String historialCuartel = '/reportes/historial-cuartel';
  
  // Testing
  static const String lookerTest = '/testing/looker';

  /// Generador de rutas con soporte para parámetros y transiciones modernas
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    // Si no hay nombre de ruta, usar App widget (maneja autenticación)
    if (settings.name == null || settings.name == '/') {
      return PageTransitions.fadeRoute(const App(), settings: settings);
    }

    switch (settings.name) {
      // Rutas principales - Sin animación para evitar parpadeos
      case splash:
        return PageTransitions.noTransitionRoute(const App(), settings: settings);
      
      case login:
        return PageTransitions.fadeRoute(const LoginScreen(), settings: settings);
      
      case home:
        return PageTransitions.modernRoute(const HomeScreen(), settings: settings);
      
      // Módulos principales - Transiciones modernas y fluidas
      case estimaciones:
        return PageTransitions.modernRoute(const EstimacionesScreen(), settings: settings);
      
      case pautasGestion:
        return PageTransitions.modernRoute(const PautasGestionScreen(), settings: settings);
      
      case pautasCrear:
        return PageTransitions.modernRoute(const PautasCrearNuevaScreen(), settings: settings);
      
      case pautasFormulario:
        return PageTransitions.modernRoute(const PautasFormularioScreen(), settings: settings);
      
      case pautasFormularioDinamico:
        return PageTransitions.modernRoute(const PautasFormularioDinamicoScreen(), settings: settings);
      
      case pautasConfiguracion:
        return PageTransitions.modernRoute(const PautasConfiguracionScreen(), settings: settings);
      
      case mapeo:
        return PageTransitions.modernRoute(const MapeoScreen(), settings: settings);
      
      case conteoAtributoEspecie:
        return PageTransitions.modernRoute(const ConteoAtributoEspecieScreen(), settings: settings);
      
      case conteoAtributoOptimo:
        return PageTransitions.modernRoute(const ConteoAtributoOptimoScreen(), settings: settings);
      
      case manejoParametrosConteo:
        return PageTransitions.modernRoute(const ManejoParametrosConteoScreen(), settings: settings);
      
      case adminUsuarios:
        return PageTransitions.modernRoute(const AdminUsuariosScreen(), settings: settings);
      
      case parametros:
        return PageTransitions.modernRoute(const ParametrosScreen(), settings: settings);
      
      case configuracionAsociaciones:
        return PageTransitions.modernRoute(const ConfiguracionAsociacionesScreen(), settings: settings);
      
      case muestras:
        return PageTransitions.modernRoute(const MuestrasScreen(), settings: settings);
      
      case produccion:
        return PageTransitions.modernRoute(const ProduccionScreen(), settings: settings);
      
      case riego:
        return PageTransitions.modernRoute(const RiegoScreen(), settings: settings);
      
      case actividades:
        return PageTransitions.modernRoute(const ActividadesScreen(), settings: settings);
      
      case cambiarClave:
        return PageTransitions.modernRoute(const CambiarClaveScreen(), settings: settings);
      
      case cambiarSucursal:
        return PageTransitions.modernRoute(const CambiarSucursalScreen(), settings: settings);
      
      case historialCuartel:
        // HistorialCuartelScreen requiere un parámetro cuartel
        final cuartel = args is Map<String, dynamic> ? args['cuartel'] as Map<String, dynamic>? : null;
        if (cuartel == null) {
          // Si no hay cuartel, redirigir a home
          return PageTransitions.modernRoute(const HomeScreen(), settings: settings);
        }
        return PageTransitions.modernRoute(
          HistorialCuartelScreen(cuartel: cuartel),
          settings: settings,
        );
      
      case lookerTest:
        return PageTransitions.modernRoute(const LookerTestScreen(), settings: settings);
      
      default:
        // Ruta no encontrada - redirigir a home
        return PageTransitions.modernRoute(const HomeScreen(), settings: settings);
    }
  }

  /// Obtener el título de la ruta
  static String getRouteTitle(String route) {
    switch (route) {
      case splash:
        return 'Inicio';
      case login:
        return 'Iniciar Sesión';
      case home:
        return 'Dashboard';
      case estimaciones:
        return 'Estimaciones';
      case pautasGestion:
        return 'Gestión de Pautas';
      case pautasCrear:
        return 'Crear Pauta';
      case pautasFormulario:
        return 'Formulario de Pauta';
      case pautasFormularioDinamico:
        return 'Formulario Dinámico';
      case pautasConfiguracion:
        return 'Configuración de Pautas';
      case mapeo:
        return 'Mapeo Agrícola';
      case conteoAtributoEspecie:
        return 'Conteo por Atributo y Especie';
      case conteoAtributoOptimo:
        return 'Atributos Óptimos';
      case manejoParametrosConteo:
        return 'Parámetros de Conteo';
      case adminUsuarios:
        return 'Administración de Usuarios';
      case parametros:
        return 'Parámetros';
      case configuracionAsociaciones:
        return 'Configuración de Asociaciones';
      case muestras:
        return 'Muestras';
      case produccion:
        return 'Producción';
      case riego:
        return 'Riego';
      case actividades:
        return 'Actividades';
      case cambiarClave:
        return 'Cambiar Contraseña';
      case cambiarSucursal:
        return 'Cambiar Sucursal';
      case historialCuartel:
        return 'Historial de Cuartel';
      case lookerTest:
        return 'Looker Test';
      default:
        return 'Portal Web';
    }
  }
}

