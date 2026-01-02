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
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      // Para web, usar localStorage directamente
      final token = html.window.localStorage['token'];
      final userData = html.window.localStorage['user'];

      if (token != null && userData != null) {
        _token = token;
        _user = jsonDecode(userData);
        _isAuthenticated = true;
      }
    } catch (e) {
      print('Error loading auth state: $e');
    } finally {
      _isLoading = false;
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
        
        if (data['success'] == true) {
          // Estructura correcta según la respuesta del backend
          _token = data['access_token'];
          _user = {
            'usuario': data['usuario'],
            'nombre': data['nombre'],
            'id_sucursal': data['id_sucursal'],
            'sucursal_nombre': data['sucursal_nombre'],
            'id_rol': data['id_rol'],
            'id_perfil': data['id_perfil'],
          };
          _isAuthenticated = true;

          // Guardar en localStorage para web
          html.window.localStorage['token'] = _token!;
          html.window.localStorage['user'] = jsonEncode(_user);

          print('Login exitoso para usuario: ${_user?['usuario']} (${_user?['nombre']})');
          print('Sucursal: ${_user?['sucursal_nombre']}');
          return true;
        } else {
          print('Login failed: ${data['message'] ?? 'Error desconocido'}');
          return false;
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Error response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
