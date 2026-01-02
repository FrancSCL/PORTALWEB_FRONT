import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://api-portalweb-927498545444.us-central1.run.app/api';
  }
  
  static String get authUrl => '$baseUrl/auth';
  static String get usuariosUrl => '$baseUrl/usuarios';
  static String get sucursalesUrl => '$baseUrl/sucursales';
  static String get cuartelesUrl => '$baseUrl/cuarteles';
  static String get mapeoUrl => '$baseUrl/mapeo';
}
