import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get userData => _user;

  AuthProvider() {
    // Inicializar como cargando
    _isLoading = true;
    _isAuthenticated = false;
    
    // Cargar estado de autenticación de forma asíncrona con timeout
    _loadAuthStateWithTimeout();
  }
  
  Future<void> _loadAuthStateWithTimeout() async {
    try {
      await _loadAuthState().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          print('⏱️ Timeout en _loadAuthState, continuando sin autenticación');
          _isLoading = false;
          _isAuthenticated = false;
          notifyListeners();
        },
      );
    } catch (error) {
      print('❌ Error crítico en _loadAuthState: $error');
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<void> _loadAuthState() async {
    try {
      print('🔍 Cargando estado de autenticación...');
      
      // Para web, usar localStorage directamente
      // Usar try-catch para evitar errores si localStorage no está disponible
      String? token;
      String? userData;
      
      try {
        token = html.window.localStorage['token'];
        userData = html.window.localStorage['user'];
      } catch (e) {
        print('⚠️ Error accediendo a localStorage: $e');
      }

      print('📦 Token encontrado: ${token != null && token.isNotEmpty}');
      print('📦 UserData encontrado: ${userData != null && userData.isNotEmpty}');

      if (token != null && token.isNotEmpty && userData != null && userData.isNotEmpty) {
        try {
        _token = token;
        _user = jsonDecode(userData);
        _isAuthenticated = true;
          print('✅ Usuario autenticado: ${_user?['usuario']}');
    } catch (e) {
          print('❌ Error parseando userData: $e');
          // Limpiar datos corruptos
          try {
            html.window.localStorage.remove('token');
            html.window.localStorage.remove('user');
          } catch (_) {}
          _isAuthenticated = false;
        }
      } else {
        print('ℹ️ No hay token o userData, usuario no autenticado');
        _isAuthenticated = false;
      }
    } catch (e, stackTrace) {
      print('❌ Error loading auth state: $e');
      print('Stack trace: $stackTrace');
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      print('✅ Estado de carga completado. isLoading: $_isLoading, isAuthenticated: $_isAuthenticated');
      // Forzar notificación inmediata
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      notifyListeners();
    }
  }

  Future<String?> getToken() async {
    if (_token != null) return _token;
    
    // Para web, usar localStorage directamente
    return html.window.localStorage['token'];
  }

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Llamada real a la API de login
      final loginData = {
        'usuario': username,
        'clave': password,
      };
      
      print('Enviando datos de login: $loginData');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(loginData),
      );

      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 Datos parseados: $data');
        print('📦 data["success"]: ${data['success']}');
        print('📦 data["access_token"] existe: ${data.containsKey('access_token')}');
        
        // Verificar si success es true o si existe access_token (por si la estructura cambió)
        if (data['success'] == true || data.containsKey('access_token')) {
          // Estructura correcta según la respuesta del backend
          _token = data['access_token'] ?? data['token'];
          
          if (_token == null || _token.isEmpty) {
            print('❌ Error: No se encontró access_token en la respuesta');
            _isLoading = false;
            _isAuthenticated = false;
            notifyListeners();
            return false;
          }
          
          _user = {
            'usuario': data['usuario'] ?? data['username'] ?? '',
            'nombre': data['nombre'] ?? data['name'] ?? '',
            'id_sucursal': data['id_sucursal'] ?? data['sucursal_id'] ?? 0,
            'sucursal_nombre': data['sucursal_nombre'] ?? data['sucursal'] ?? '',
            'id_rol': data['id_rol'] ?? data['rol_id'] ?? 0,
            'id_perfil': data['id_perfil'] ?? data['perfil_id'] ?? 0,
          };
          _isAuthenticated = true;

          // Guardar en localStorage para web
          html.window.localStorage['token'] = _token!;
          html.window.localStorage['user'] = jsonEncode(_user);

          print('✅ Login exitoso para usuario: ${_user?['usuario']} (${_user?['nombre']})');
          print('✅ Sucursal: ${_user?['sucursal_nombre']}');
          print('✅ Estado: _isAuthenticated = $_isAuthenticated, _isLoading = $_isLoading');
          
          // Notificar inmediatamente después de establecer el estado
          _isLoading = false;
          
          // Notificar de forma síncrona para que el App widget reaccione
          notifyListeners();
          
          return true;
        } else {
          print('Login failed: ${data['message'] ?? 'Error desconocido'}');
          _isLoading = false;
          _isAuthenticated = false;
          notifyListeners();
          return false;
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        _isLoading = false;
        _isAuthenticated = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error during login: $e');
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Limpiar localStorage para web
      html.window.localStorage.remove('token');
      html.window.localStorage.remove('user');

      _token = null;
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> handleTokenExpiry(BuildContext context) async {
    // Mostrar mensaje de sesión expirada
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión expirada. Redirigiendo al login...'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Cerrar sesión automáticamente
    await logout();
    
    // Redirigir al login usando navegación web
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  Future<void> checkAuthStatus() async {
    await _loadAuthState();
  }

  Future<bool> cambiarSucursal(String nuevaSucursal) async {
    try {
      if (_user == null || _token == null) return false;

      // Buscar el ID de la sucursal por nombre
      final sucursales = await obtenerSucursalesDisponibles();
      final sucursal = sucursales.firstWhere(
        (s) => s['nombre'] == nuevaSucursal,
        orElse: () => {'id': null},
      );

      if (sucursal['id'] == null) {
        print('Sucursal no encontrada: $nuevaSucursal');
        return false;
      }

      // Llamada real a la API para cambiar sucursal
      final response = await http.post(
        Uri.parse('${ApiConfig.authUrl}/cambiar-sucursal'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'id_sucursal': sucursal['id'],
        }),
      );

      print('Respuesta cambiar sucursal: ${response.statusCode}');
      print('Cuerpo respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Actualizar la sucursal en el estado local
        _user!['sucursal_nombre'] = data['sucursal_nombre'];
        _user!['id_sucursal'] = data['id_sucursal'];
        
        // Guardar en localStorage para web
        html.window.localStorage['user'] = jsonEncode(_user);

        // Notificar a los widgets que escuchan
        notifyListeners();

        print('Sucursal cambiada exitosamente a: ${data['sucursal_nombre']}');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        print('Error cambiando sucursal: ${errorData['error'] ?? 'Error desconocido'}');
        return false;
      }
    } catch (e) {
      print('Error cambiando sucursal: $e');
      return false;
    }
  }

  // Obtener lista de sucursales disponibles del backend
  Future<List<Map<String, dynamic>>> obtenerSucursalesDisponibles() async {
    try {
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConfig.sucursalesUrl}/'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Error obteniendo sucursales: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error obteniendo sucursales: $e');
      return [];
    }
  }

  // Obtener lista de nombres de sucursales para el dropdown
  Future<List<String>> getSucursalesDisponibles() async {
    try {
      final sucursales = await obtenerSucursalesDisponibles();
      return sucursales.map((s) => s['nombre'] as String).toList();
    } catch (e) {
      print('Error obteniendo nombres de sucursales: $e');
      // Fallback a lista hardcodeada
      return [
        'SANTA VICTORIA',
        'SAN MANUEL', 
        'CULLIPEUMO',
        'CHOCALAN',
        'HOSPITAL'
      ];
    }
  }
}
