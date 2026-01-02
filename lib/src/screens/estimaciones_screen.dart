import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/http_interceptor.dart';
import 'pautas_crear_nueva_screen.dart';
// import 'historial_cuartel_screen.dart';

class EstimacionesScreen extends StatefulWidget {
  const EstimacionesScreen({super.key});

  @override
  State<EstimacionesScreen> createState() => _EstimacionesScreenState();
}

class _EstimacionesScreenState extends State<EstimacionesScreen> {
  List<Map<String, dynamic>> _especiesAgrupadas = [];
  List<Map<String, dynamic>> _tiposEstimacion = [];
  Map<String, dynamic>? _totalesGenerales;
  bool _isLoading = true;
  String? _errorMessage;
  int _totalEspecies = 0;
  String _busqueda = '';
  
  // Nuevas variables para la vista detallada
  Map<String, dynamic>? _cuartelSeleccionado;
  Map<String, dynamic>? _informacionGeneral;
  List<Map<String, dynamic>> _estimaciones = [];
  List<Map<String, dynamic>> _pautas = [];
  List<Map<String, dynamic>> _rendimientos = [];
  List<Map<String, dynamic>> _mapeos = [];
  List<Map<String, dynamic>> _frutosRamilla = [];
  List<Map<String, dynamic>> _calibres = [];
  bool _isLoadingDetalle = false;
  
  // Filtros
  String? _especieSeleccionada;
  String? _variedadSeleccionada;
  List<String> _especiesDisponibles = [];
  List<String> _variedadesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _cargarDashboard();
      await _cargarVariedades();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar los datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarVariedades() async {
    try {
      // Extraer variedades únicas de los cuarteles en todas las especies
      final variedades = <String>{};
      for (final especie in _especiesAgrupadas) {
        final cuarteles = List<Map<String, dynamic>>.from(especie['cuarteles'] ?? []);
        for (final cuartel in cuarteles) {
          final variedad = cuartel['variedad']?.toString();
          if (variedad != null && variedad.isNotEmpty && variedad != 'N/A') {
            variedades.add(variedad);
          }
        }
      }
      
      // Debug: Verificar que las variedades se cargan correctamente
      print('DEBUG: Variedades cargadas: ${variedades.toList()..sort()}');
      
      setState(() {
        _variedadesDisponibles = variedades.toList()..sort();
      });
    } catch (e) {
      print('Error cargando variedades: $e');
    }
  }

  Future<void> _cargarDashboard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    // Cargar cuarteles de la sucursal activa
    await _cargarCuartelesSucursalActiva();
  }

  Future<void> _cargarCuartelesSucursalActiva() async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/cuarteles/sucursal-activa'),
      );

      final data = json.decode(response.body);
      
      // Debug: Verificar estructura de datos
      print('DEBUG: Datos recibidos del backend:');
      print('DEBUG: Total cuarteles: ${data['data']['cuarteles']?.length ?? 0}');
      if (data['data']['cuarteles']?.isNotEmpty == true) {
        final primerCuartel = data['data']['cuarteles'][0];
        print('DEBUG: Primer cuartel campos: ${primerCuartel.keys}');
        print('DEBUG: Primer cuartel variedad: ${primerCuartel['variedad']}');
        print('DEBUG: Primer cuartel especie_nombre: ${primerCuartel['especie_nombre']}');
        print('DEBUG: Primer cuartel nombre_especie: ${primerCuartel['nombre_especie']}');
      }
      
      if (response.statusCode == 200 && data['success'] == true) {
        final cuarteles = List<Map<String, dynamic>>.from(data['data']['cuarteles']);
        final sucursalInfo = data['data']['sucursal_info'];
        
        // Agrupar cuarteles por especie
        final especiesAgrupadas = <String, Map<String, dynamic>>{};
        
        for (var cuartel in cuarteles) {
          final especieNombre = cuartel['especie_nombre'] ?? cuartel['nombre_especie'] ?? 'Sin Especie';
          
          if (!especiesAgrupadas.containsKey(especieNombre)) {
            especiesAgrupadas[especieNombre] = {
              'especie_nombre': especieNombre,
              'especie_id': cuartel['id_variedad'], // Usar id_variedad como referencia
              'cuarteles': <Map<String, dynamic>>[],
              'total_cuarteles': 0,
            };
          }
          
          // Agregar información adicional al cuartel
          final cuartelConInfo = Map<String, dynamic>.from(cuartel);
          cuartelConInfo['total_estimaciones'] = 0; // Valor por defecto
          cuartelConInfo['estado'] = cuartel['id_estado'] == 1 ? 'ACTIVO' : 'INACTIVO';
          cuartelConInfo['activo'] = cuartel['id_estado'] == 1;
          
          especiesAgrupadas[especieNombre]!['cuarteles'].add(cuartelConInfo);
          especiesAgrupadas[especieNombre]!['total_cuarteles']++;
        }
        
        setState(() {
          _especiesAgrupadas = especiesAgrupadas.values.toList();
          _tiposEstimacion = []; // No disponible en este endpoint
          _totalesGenerales = {
            'total_estimaciones': 0,
            'total_cajas': 0,
            'total_kg_embalaje': 0,
            'total_kg_industria': 0,
          };
          _totalEspecies = especiesAgrupadas.length;
          _errorMessage = null;
          
          // Extraer especies disponibles para el filtro
          _especiesDisponibles = _especiesAgrupadas
              .map((especie) => especie['especie_nombre'] as String)
              .where((nombre) => nombre != null && nombre.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
        });
      } else if (response.statusCode == 404 && data['success'] == false) {
        // Sin datos disponibles
        setState(() {
          _especiesAgrupadas = [];
          _tiposEstimacion = [];
          _totalesGenerales = {
            'total_estimaciones': 0,
            'total_cajas': 0,
            'total_kg_embalaje': 0,
            'total_kg_industria': 0,
          };
          _totalEspecies = 0;
          _errorMessage = data['message'] ?? 'No hay cuarteles disponibles para tu sucursal activa';
        });
      } else {
        // Error del servidor
        throw Exception(data['message'] ?? 'Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _especiesAgrupadas = [];
        _tiposEstimacion = [];
        _totalesGenerales = {
          'total_estimaciones': 0,
          'total_cajas': 0,
          'total_kg_embalaje': 0,
          'total_kg_industria': 0,
        };
        _totalEspecies = 0;
        _errorMessage = 'Error al cargar cuarteles de la sucursal activa: $e';
      });
    }
  }

  List<Map<String, dynamic>> get _cuartelesFiltrados {
    List<Map<String, dynamic>> todosLosCuarteles = [];

    // Extraer todos los cuarteles de todas las especies
    for (var especie in _especiesAgrupadas) {
      final cuarteles = List<Map<String, dynamic>>.from(especie['cuarteles'] ?? []);
      for (var cuartel in cuarteles) {
        // Agregar información de la especie al cuartel
        final cuartelConEspecie = Map<String, dynamic>.from(cuartel);
        cuartelConEspecie['especie_nombre'] = especie['especie_nombre'];
        todosLosCuarteles.add(cuartelConEspecie);
      }
    }

    // Aplicar filtros
    List<Map<String, dynamic>> filtrados = todosLosCuarteles;

    // Filtrar por especie seleccionada
    if (_especieSeleccionada != null && _especieSeleccionada!.isNotEmpty) {
      filtrados = filtrados.where((cuartel) {
        return cuartel['especie_nombre'] == _especieSeleccionada;
      }).toList();
    }

      // Filtrar por variedad seleccionada
      if (_variedadSeleccionada != null && _variedadSeleccionada!.isNotEmpty) {
        print('DEBUG: Filtrando por variedad: $_variedadSeleccionada');
        print('DEBUG: Cuarteles antes del filtro de variedad: ${filtrados.length}');
        filtrados = filtrados.where((cuartel) {
          final variedad = cuartel['variedad']?.toString();
          final match = variedad == _variedadSeleccionada;
          if (match) print('DEBUG: Match encontrado - ${cuartel['nombre']}: $variedad');
          return match;
        }).toList();
        print('DEBUG: Cuarteles después del filtro de variedad: ${filtrados.length}');
      }

    // Siempre mostrar solo cuarteles activos
    filtrados = filtrados.where((cuartel) {
      final isActivo = cuartel['estado'] == 'ACTIVO' || cuartel['activo'] == true;
      return isActivo;
    }).toList();

    // Filtrar por búsqueda si está activa
    if (_busqueda.isNotEmpty) {
      final busqueda = _busqueda.toLowerCase();
      filtrados = filtrados.where((cuartel) {
        final nombre = cuartel['nombre']?.toString().toLowerCase() ?? '';
        final descripcion = cuartel['descripcion']?.toString().toLowerCase() ?? '';
        final ceco = cuartel['nombre_ceco']?.toString().toLowerCase() ?? '';
        final sucursal = cuartel['nombre_sucursal']?.toString().toLowerCase() ?? '';
        final especie = cuartel['especie_nombre']?.toString().toLowerCase() ?? '';
        return nombre.contains(busqueda) || 
               descripcion.contains(busqueda) || 
               ceco.contains(busqueda) || 
               sucursal.contains(busqueda) ||
               especie.contains(busqueda);
      }).toList();
    }

    // Ordenar por nombre
    filtrados.sort((a, b) {
      final nombreA = a['nombre']?.toString() ?? '';
      final nombreB = b['nombre']?.toString() ?? '';
      return nombreA.compareTo(nombreB);
    });

    return filtrados;
  }

  void _crearNuevaPauta() {
    if (_cuartelSeleccionado == null) return;
    
    // Mostrar formulario modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FormularioCrearPautaModal(
        cuartel: _cuartelSeleccionado!,
        onPautaCreada: () {
          // Recargar detalles del cuartel después de crear la pauta
          _cargarDetallesCuartel(_cuartelSeleccionado!['id']);
        },
      ),
    );
  }

  void _crearNuevoRendimiento() {
    if (_cuartelSeleccionado == null) return;
    
    // Mostrar formulario modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FormularioCrearRendimientoModal(
        cuartelId: _cuartelSeleccionado!['id'],
        cuartelNombre: _cuartelSeleccionado!['nombre'],
        onRendimientoCreado: () {
          // Recargar detalles del cuartel después de crear el rendimiento
          _cargarDetallesCuartel(_cuartelSeleccionado!['id']);
        },
      ),
    );
  }

  void _verHistorialCuartel(Map<String, dynamic> cuartel) {
    setState(() {
      _cuartelSeleccionado = cuartel;
      _isLoadingDetalle = true;
    });
    _cargarDetallesCuartel(cuartel['id']);
  }

  Future<void> _cargarDetallesCuartel(int cuartelId) async {
    try {
      // Hacer llamadas paralelas a todos los endpoints
      await Future.wait([
        _cargarInformacionGeneral(cuartelId),
        _cargarEstimaciones(cuartelId),
        _cargarPautas(cuartelId),
        _cargarRendimientos(cuartelId),
        _cargarMapeos(cuartelId),
        _cargarFrutosRamilla(cuartelId),
        _cargarCalibres(cuartelId),
      ]);

      setState(() {
        _isLoadingDetalle = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDetalle = false;
      });
      print('Error cargando detalles del cuartel: $e');
    }
  }

  Future<void> _cargarInformacionGeneral(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/informacion-general'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _informacionGeneral = data['data']['cuartel'];
          });
        }
      }
    } catch (e) {
      print('Error cargando información general: $e');
    }
  }

  Future<void> _cargarEstimaciones(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/estimaciones'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _estimaciones = List<Map<String, dynamic>>.from(data['data']['estimaciones']);
          });
        }
      }
    } catch (e) {
      print('Error cargando estimaciones: $e');
    }
  }

  Future<void> _cargarPautas(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/pautas'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _pautas = List<Map<String, dynamic>>.from(data['data']['pautas']);
          });
        }
      }
    } catch (e) {
      print('Error cargando pautas: $e');
    }
  }

  Future<void> _cargarRendimientos(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/rendimiento-packing'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _rendimientos = List<Map<String, dynamic>>.from(data['data']['rendimientos']);
          });
        }
      }
    } catch (e) {
      print('Error cargando rendimientos: $e');
    }
  }

  Future<void> _cargarMapeos(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/mapeos'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _mapeos = List<Map<String, dynamic>>.from(data['data']['mapeos']);
          });
        }
      }
    } catch (e) {
      print('Error cargando mapeos: $e');
    }
  }

  Future<void> _cargarFrutosRamilla(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/frutos-ramilla-historico'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _frutosRamilla = List<Map<String, dynamic>>.from(data['data']['frutos_ramilla']);
          });
        }
      }
    } catch (e) {
      print('Error cargando frutos/ramilla: $e');
    }
  }

  Future<void> _cargarCalibres(int cuartelId) async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/$cuartelId/calibres-historicos'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _calibres = List<Map<String, dynamic>>.from(data['data']['calibres']);
          });
        }
      }
    } catch (e) {
      print('Error cargando calibres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Estimaciones',
      currentRoute: '/estimaciones',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _especiesAgrupadas.isEmpty
                  ? _buildEmptyState()
                  : _buildVistaDosColumnas(),
    );
  }

  Widget _buildVistaDosColumnas() {
    return Row(
      children: [
        // Panel izquierdo - Lista de cuarteles
        Expanded(
          flex: 2,
          child: _buildPanelIzquierdo(),
        ),
        // Separador
        Container(
          width: 1,
          color: Colors.grey[300],
        ),
        // Panel derecho - Detalles del cuartel
        Expanded(
          flex: 3,
          child: _buildPanelDerecho(),
        ),
      ],
    );
  }

  Widget _buildPanelIzquierdo() {
    return Column(
      children: [
        _buildHeader(),
        _buildFiltros(),
        Expanded(
          child: _buildCuartelesList(),
        ),
      ],
    );
  }

  Widget _buildPanelDerecho() {
    if (_cuartelSeleccionado == null) {
      return _buildPanelVacio();
    }

    return Column(
      children: [
        _buildHeaderDetalle(),
        Expanded(
          child: _isLoadingDetalle
              ? const Center(child: CircularProgressIndicator())
              : _buildDetallesCuartel(),
        ),
      ],
    );
  }

  Widget _buildPanelVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona un cuartel para ver sus detalles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDetalle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: AppTheme.mediumGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _cuartelSeleccionado?['nombre'] ?? 'Cuartel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mediumGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _cuartelSeleccionado?['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesCuartel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información General
          _buildCardDetalle(
            title: 'Información General',
            icon: Icons.info_outline,
            child: _buildInformacionGeneralSection(),
          ),
          const SizedBox(height: 16),
          
          // Estimaciones
          _buildCardDetalle(
            title: 'Estimaciones',
            icon: Icons.analytics,
            count: _estimaciones.length,
            child: _buildEstimacionesSection(),
            actions: [
              TextButton(
                onPressed: () {
                  // TODO: Implementar nueva estimación
                },
                child: const Text('NUEVA ESTIMACIÓN'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Pautas
          _buildCardDetalle(
            title: 'Pautas',
            icon: Icons.assignment,
            count: _pautas.length,
            child: _buildPautasSection(),
            actions: [
              TextButton(
                onPressed: _cuartelSeleccionado != null ? () => _crearNuevaPauta() : null,
                child: const Text('NUEVA PAUTA'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rendimiento Packing
          _buildCardDetalle(
            title: 'Rendimiento Packing',
            icon: Icons.trending_up,
            count: _rendimientos.length,
            child: _buildRendimientosSection(),
            actions: [
              TextButton(
                onPressed: _cuartelSeleccionado != null ? () => _crearNuevoRendimiento() : null,
                child: const Text('NUEVO RENDIMIENTO'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mapeos
          _buildCardDetalle(
            title: 'Mapeos',
            icon: Icons.map,
            count: _mapeos.length,
            child: _buildMapeosSection(),
            actions: [
              TextButton(
                onPressed: () {
                  // TODO: Implementar nuevo mapeo
                },
                child: const Text('NUEVO MAPEO'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Frutos/Ramilla Histórico
          _buildCardDetalle(
            title: 'Frutos/Ramilla Histórico',
            icon: Icons.eco,
            count: _frutosRamilla.length,
            child: _buildFrutosRamillaSection(),
            actions: [
              TextButton(
                onPressed: () {
                  // TODO: Implementar añadir frutos/ramilla
                },
                child: const Text('AÑADIR'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Calibres Históricos
          _buildCardDetalle(
            title: 'Calibres Históricos',
            icon: Icons.straighten,
            count: _calibres.length,
            child: _buildCalibresSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = authProvider.userData;
    final sucursalNombre = userData?['sucursal_nombre'] ?? 'Sucursal no definida';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.mediumGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Estimaciones',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mediumGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sucursal: $sucursalNombre',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.mediumGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Especies: $_totalEspecies',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar cuarteles...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Colors.grey[500],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _busqueda = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 8),
          
          // Filtros compactos
          Row(
            children: [
              // Filtro por especie
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _especieSeleccionada,
                      hint: Text(
                        'Especie',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._especiesDisponibles.map((especie) {
                          return DropdownMenuItem<String>(
                            value: especie,
                            child: Text(especie),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _especieSeleccionada = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              
              // Filtro de variedad
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _variedadSeleccionada,
                      hint: Text(
                        'Variedad',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._variedadesDisponibles.map((variedad) {
                          return DropdownMenuItem<String>(
                            value: variedad,
                            child: Text(variedad),
                          );
                        }),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _variedadSeleccionada = value;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              
              // Botón limpiar
              if (_especieSeleccionada != null || _variedadSeleccionada != null)
                Container(
                  height: 36,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _especieSeleccionada = null;
                        _variedadSeleccionada = null;
                      });
                    },
                    icon: Icon(Icons.clear, size: 14),
                    label: Text('Limpiar', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando estimaciones...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    // Determinar el tipo de error y mostrar el mensaje apropiado
    bool isDataNotAvailable = _errorMessage!.contains('No hay datos disponibles');
    bool isTablesNotExist = _errorMessage!.contains('tablas no existen');
    bool isNoDataAssigned = _errorMessage!.contains('No se encontraron especies');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDataNotAvailable ? Icons.info_outline : Icons.error_outline,
              size: 64,
              color: isDataNotAvailable ? Colors.orange[400] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              isDataNotAvailable ? 'Sin datos disponibles' : 'Error del sistema',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDataNotAvailable ? Colors.orange[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Mensaje específico según el tipo de error
            if (isTablesNotExist)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.build,
                      color: Colors.orange[600],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acción requerida: Contactar al administrador para crear las tablas de especies y cuarteles en la base de datos.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (isNoDataAssigned)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.blue[600],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acción requerida: Contactar al administrador para asignar cuarteles a tu sucursal.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mediumGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay especies disponibles',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las especies con sus cuarteles aparecerán aquí cuando tengas acceso a ellos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _cargarDatos,
            icon: const Icon(Icons.refresh),
            label: const Text('Refrescar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mediumGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuartelesList() {
    final cuartelesFiltrados = _cuartelesFiltrados;

    return Container(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Lista de cuarteles
          Expanded(
            child: cuartelesFiltrados.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: cuartelesFiltrados.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final cuartel = cuartelesFiltrados[index];
                      return _buildCuartelItem(cuartel);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEspecieCard(Map<String, dynamic> especie) {
    final cuarteles = List<Map<String, dynamic>>.from(especie['cuarteles'] ?? []);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la especie
              Row(
                children: [
                  Icon(
                    Icons.eco,
                    color: AppTheme.mediumGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      especie['especie_nombre'] ?? 'Especie ${especie['especie_id']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mediumGreen,
                      ),
                    ),
                  ),
                  Text(
                    '${especie['total_cuarteles'] ?? 0} cuarteles',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Lista de cuarteles
              if (cuarteles.isNotEmpty)
                ...cuarteles.map((cuartel) => _buildCuartelItem(cuartel)).toList()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No hay cuarteles disponibles para esta especie',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuartelItem(Map<String, dynamic> cuartel) {
    final isActivo = cuartel['estado'] == 'ACTIVO' || cuartel['activo'] == true;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verHistorialCuartel(cuartel),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícono de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActivo 
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActivo ? Icons.location_on : Icons.location_off,
                    color: isActivo ? AppTheme.primaryColor : Colors.grey[400],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del cuartel
                      Text(
                        cuartel['nombre'] ?? 'Cuartel ${cuartel['id']}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Información secundaria
                      Row(
                        children: [
                          // Especie
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 10,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cuartel['especie_nombre'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // CECO
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 10,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cuartel['nombre_ceco'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Sucursal
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_city,
                                  size: 10,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cuartel['nombre_sucursal'] ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Estado y estimaciones
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActivo 
                            ? AppTheme.primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActivo ? 'ACTIVO' : 'INACTIVO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActivo ? AppTheme.primaryColor : Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Estimaciones
                    Text(
                      '${cuartel['total_estimaciones'] ?? 0}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    final date = DateTime.tryParse(fecha);
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ==== DETALLE: item renderers ====
  Widget _buildEstimacionItem(Map<String, dynamic> estimacion) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (estimacion['tipo_estimacion'] ?? 'N/A').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Cajas/Ha: ${(estimacion['estimacion_cajas_ha'] ?? 0).toString()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Estimación: ${(estimacion['estimacion'] ?? 0).toString()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            (estimacion['fecha'] ?? 'N/A').toString(),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPautaItem(Map<String, dynamic> pauta) {
    final String labor = (pauta['labor'] ?? 'N/A').toString();
    final String fechaInicio = (pauta['fecha_inicio'] ?? 'N/A').toString();
    final int temporada = int.tryParse((pauta['temporada'] ?? pauta['id_temporada'] ?? '1').toString()) ?? 1;
    final String nombreTemporada = (pauta['nombre_temporada'] ?? '').toString();
    
    // Determinar color según la temporada
    Color temporadaColor = _getTemporadaColor(temporada);
    Color backgroundColor = temporadaColor.withOpacity(0.1);
    IconData temporadaIcon = Icons.calendar_month;
    
    // Crear texto de temporada
    String temporadaText = 'T$temporada';
    if (nombreTemporada.isNotEmpty) {
      temporadaText = 'T$temporada ($nombreTemporada)';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navegar a detalles de la pauta
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de la labor
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getLaborIcon(labor),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labor,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          fechaInicio,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Temporada con estilo mejorado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: temporadaColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      temporadaIcon,
                      size: 12,
                      color: temporadaColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      temporadaText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: temporadaColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Flecha de navegación
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getLaborIcon(String labor) {
    switch (labor.toLowerCase()) {
      case 'poda':
        return Icons.content_cut;
      case 'raleo':
        return Icons.remove_circle_outline;
      case 'riego':
        return Icons.water_drop;
      case 'fertilización':
        return Icons.eco;
      case 'cosecha':
        return Icons.agriculture;
      default:
        return Icons.work_outline;
    }
  }
  
  Color _getTemporadaColor(int temporada) {
    switch (temporada) {
      case 1:
        return Colors.blue[600]!;
      case 2:
        return Colors.green[600]!;
      case 3:
        return Colors.orange[600]!;
      case 4:
        return Colors.purple[600]!;
      case 5:
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _getRendimientoColor(double rendimiento) {
    if (rendimiento >= 90) return Colors.green[600]!;
    if (rendimiento >= 80) return Colors.orange[600]!;
    if (rendimiento >= 70) return Colors.amber[600]!;
    return Colors.red[600]!;
  }

  Widget _buildRendimientoItem(Map<String, dynamic> rendimiento) {
    final double rendimientoValue = (rendimiento['rendimiento'] ?? 0).toDouble();
    final String fecha = (rendimiento['fecha'] ?? 'N/A').toString();
    final String usuario = (rendimiento['usuario'] ?? 'Usuario').toString();
    
    // Determinar color según el rendimiento
    Color backgroundColor = _getRendimientoColor(rendimientoValue);
    
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Icono con porcentaje
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${rendimientoValue.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Información del rendimiento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rendimiento: ${rendimientoValue.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fecha,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Usuario
          Text(
            usuario,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapeoItem(Map<String, dynamic> mapeo) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (mapeo['fecha'] ?? 'N/A').toString(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('Plantas 7: ${(mapeo['plantas_7'] ?? 0).toString()}', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Text('Plantas 5: ${(mapeo['plantas_5'] ?? 0).toString()}', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Text('Plantas 3: ${(mapeo['plantas_3'] ?? 0).toString()}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrutoItem(Map<String, dynamic> fruto) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'FRUTOS/RAMILLA HISTÓRICO: ${(fruto['frutos_ramilla'] ?? 0).toString()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            (fruto['fecha'] ?? 'N/A').toString(),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibreItem(Map<String, dynamic> calibre) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (calibre['calibre'] ?? 'N/A').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Cantidad: ${(calibre['cantidad'] ?? 0).toString()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            (calibre['fecha'] ?? 'N/A').toString(),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  // ==== DETALLE: helpers UI ====
  Widget _buildCardDetalle({
    required String title,
    required IconData icon,
    int? count,
    required Widget child,
    List<Widget>? actions,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.mediumGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mediumGreen,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.mediumGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (actions != null) ...actions,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==== DETALLE: secciones ====
  Widget _buildInformacionGeneralSection() {
    if (_informacionGeneral == null) {
      return _buildDetalleEmpty('No hay información disponible');
    }
    return Column(
      children: [
        _buildInfoRow('CUARTEL', _informacionGeneral!['nombre']?.toString() ?? 'N/A'),
        _buildInfoRow('VARIEDAD', _informacionGeneral!['variedad']?.toString() ?? 'N/A'),
        _buildInfoRow('CECO', _informacionGeneral!['nombre_ceco']?.toString() ?? 'N/A'),
        _buildInfoRow('SUCURSAL', _informacionGeneral!['nombre_sucursal']?.toString() ?? 'N/A'),
        _buildInfoRow('SUPERFICIE PRODUCTIVA', '${_informacionGeneral!['superficie_productiva'] ?? 0}'),
        _buildInfoRow('AÑO PLANTACIÓN', '${_informacionGeneral!['año_plantacion'] ?? 'N/A'}'),
        _buildInfoRow('PLANTAS/Ha TEÓRICAS', '${_informacionGeneral!['plantas_ha_teoricas'] ?? 0}'),
        _buildInfoRow('PORTAINJERTO', '${_informacionGeneral!['portainjerto'] ?? 'N/A'}'),
        _buildInfoRow('ESTADO PRODUCTIVO', _informacionGeneral!['estado_productivo']?.toString() ?? 'N/A'),
        _buildInfoRow('Nº BRAZOS/EJES', '${_informacionGeneral!['numero_brazos_ejes'] ?? 0}'),
      ],
    );
  }

  Widget _buildEstimacionesSection() {
    if (_estimaciones.isEmpty) return _buildDetalleEmpty('No hay estimaciones registradas');
    return Column(
      children: _estimaciones.map((e) => _buildEstimacionItem(e)).toList(),
    );
  }

  Widget _buildPautasSection() {
    if (_pautas.isEmpty) return _buildDetalleEmpty('No hay pautas registradas');
    return Column(
      children: _pautas.map((e) => _buildPautaItem(e)).toList(),
    );
  }

  Widget _buildRendimientosSection() {
    if (_rendimientos.isEmpty) return _buildDetalleEmpty('No hay rendimientos registrados');
    return Column(
      children: _rendimientos.map((e) => _buildRendimientoItem(e)).toList(),
    );
  }

  Widget _buildMapeosSection() {
    if (_mapeos.isEmpty) return _buildDetalleEmpty('No hay mapeos registrados');
    return Column(
      children: _mapeos.map((e) => _buildMapeoItem(e)).toList(),
    );
  }

  Widget _buildFrutosRamillaSection() {
    if (_frutosRamilla.isEmpty) return _buildDetalleEmpty('No hay datos históricos');
    return Column(
      children: _frutosRamilla.map((e) => _buildFrutoItem(e)).toList(),
    );
  }

  Widget _buildCalibresSection() {
    if (_calibres.isEmpty) return _buildDetalleEmpty('No hay calibres registrados');
    return Column(
      children: _calibres.map((e) => _buildCalibreItem(e)).toList(),
    );
  }

  Widget _buildDetalleEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        message,
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      ),
    );
  }
}

class _FormularioCrearPautaModal extends StatefulWidget {
  final Map<String, dynamic> cuartel;
  final VoidCallback onPautaCreada;

  const _FormularioCrearPautaModal({
    required this.cuartel,
    required this.onPautaCreada,
  });

  @override
  State<_FormularioCrearPautaModal> createState() => _FormularioCrearPautaModalState();
}

class _FormularioCrearPautaModalState extends State<_FormularioCrearPautaModal> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _frutosController = TextEditingController();
  final _cargadoresController = TextEditingController();
  
  Map<String, dynamic>? _laborSeleccionada;
  Map<String, dynamic>? _especieData;
  int? _laborIdSeleccionada;
  String? _laborNombreSeleccionada;
  String? _tipoPlantaPeso;
  String? _tipoPlantaFrutos;
  String? _tipoPlantaCargadores;
  String? _idConteoTipo; // id_conteotipo requerido por el endpoint unificado
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Map<String, dynamic>> _laboresDisponibles = [];
  List<Map<String, dynamic>> _tiposPlanta = [];
  List<Map<String, dynamic>> _atributosFormulario = [];
  // Muestras: key = "atributoId|tipoPlantaId" -> lista de TextEditingController
  final Map<String, List<TextEditingController>> _muestrasControllers = {};

  String _getLaborDisplay(Map<String, dynamic> labor) {
    final keys = ['nombre', 'nombre_labor', 'descripcion', 'titulo', 'label'];
    for (final k in keys) {
      final v = labor[k]?.toString();
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    // fallback: primer string no vacío del mapa
    for (final entry in labor.entries) {
      final v = entry.value?.toString();
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    final id = labor['id']?.toString();
    return id != null ? 'Labor $id' : 'Sin nombre';
  }

  String _getTipoPlantaDisplay(String tipoId) {
    // Debug: mostrar qué estamos buscando
    print('DEBUG: Buscando tipo $tipoId en ${_tiposPlanta.length} tipos disponibles');
    
    // Buscar el tipo de planta en la lista cargada
    try {
      final tipo = _tiposPlanta.firstWhere(
        (t) => (t['id'] ?? t['tipo_id']).toString() == tipoId,
      );
      
      String? nombre = tipo['nombre'] ?? tipo['nombre_tipo'] ?? tipo['descripcion'];
      
      if (nombre != null && nombre.toString().trim().isNotEmpty) {
        print('DEBUG: Encontrado tipo $tipoId: $nombre');
        return nombre.toString().trim();
      }
    } catch (e) {
      print('DEBUG: Tipo $tipoId no encontrado en la lista');
    }
    
    // Fallback: mostrar tipo genérico
    return 'TIPO $tipoId';
  }

  @override
  void initState() {
    super.initState();
    // Cargar datos de forma asíncrona
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEspecieDelCuartel();
    });
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _frutosController.dispose();
    _cargadoresController.dispose();
    super.dispose();
  }

  Future<void> _cargarEspecieDelCuartel() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/cuartel-especie/${widget.cuartel['id']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _especieData = data['data'];
          });
          // Cargar labores después de obtener la especie
          _cargarLaboresPorEspecie();
        } else {
          setState(() {
            _errorMessage = 'Error al cargar especie del cuartel: ${data['message']}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error HTTP ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar especie del cuartel: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarLaboresPorEspecie() async {
    if (_especieData == null) return;

    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/labores-por-especie/${_especieData!['id_especie']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          List<Map<String, dynamic>> labores = [];
          if (data['data'] is List) {
            labores = List<Map<String, dynamic>>.from(data['data']);
          } else if (data['data']['labores'] is List) {
            labores = List<Map<String, dynamic>>.from(data['data']['labores']);
          }
          
          // Normalizar nombre de labor (algunos backends usan otros campos)
          String _resolverNombreLabor(Map<String, dynamic> labor) {
            final posiblesClaves = ['nombre', 'nombre_labor', 'descripcion', 'titulo', 'label'];
            for (final clave in posiblesClaves) {
              final valor = labor[clave]?.toString();
              if (valor != null && valor.trim().isNotEmpty) return valor.trim();
            }
            // fallback: toma el primer string no vacío que exista
            for (final entry in labor.entries) {
              final v = entry.value?.toString();
              if (v != null && v.trim().isNotEmpty) return v.trim();
            }
            final id = labor['id']?.toString();
            return id != null ? 'Labor $id' : 'Sin nombre';
          }

          labores = labores.map((l) {
            final map = Map<String, dynamic>.from(l);
            map['nombre'] = _resolverNombreLabor(map);
            return map;
          }).toList()
            ..sort((a, b) => (a['nombre'] ?? '').toString().compareTo((b['nombre'] ?? '').toString()));

          setState(() {
            _laboresDisponibles = labores;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar labores: $e';
      });
    }
  }

  Future<void> _cargarFormularioDinamico(int laborId) async {
    if (_especieData == null) return;
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/formulario-dinamico/$laborId/${_especieData!['id_especie']}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final d = data['data'];
          setState(() {
            _idConteoTipo = d['labor_especie']?['id']?.toString();
            // Validar que backend responde la misma labor seleccionada
            final nombreLaborBackend = d['labor_especie']?['nombre_labor']?.toString();
            if (nombreLaborBackend != null && _laborNombreSeleccionada != null &&
                nombreLaborBackend.toLowerCase() != _laborNombreSeleccionada!.toLowerCase()) {
              _errorMessage = 'Advertencia: la labor devuelta (${nombreLaborBackend}) no coincide con la seleccionada (${_laborNombreSeleccionada}).';
            }
            // Agrupar atributos por nombre + tipo_planta para evitar duplicados
            final attrs = List<Map<String, dynamic>>.from(d['atributos'] ?? []);
            final Map<String, Map<String, dynamic>> atributosUnicos = {};
            
            for (final a in attrs) {
              final String nombreAtributo = (a['nombre_atributo'] ?? 'Atributo').toString();
              final String tipoPlanta = (a['id_tipoplanta'] ?? '').toString();
              final int idAtributo = (a['id_atributo'] is int) ? a['id_atributo'] : int.tryParse(a['id_atributo'].toString()) ?? -1;
              
              if (idAtributo == -1 || tipoPlanta.isEmpty) continue;
              
              // Crear clave única: nombre_atributo + tipo_planta
              final String clave = '${nombreAtributo}_$tipoPlanta';
              
              if (!atributosUnicos.containsKey(clave)) {
                atributosUnicos[clave] = {
                  'id': idAtributo,
                  'nombre_atributo': nombreAtributo,
                  'tipo_planta': tipoPlanta,
                  'nombre_tipo_planta': a['nombre_tipo_planta'] ?? 'TIPO $tipoPlanta',
                  'factor_productivo': a['factor_productivo'] ?? 1.0,
                };
              }
            }
            
            // Convertir a lista para el formulario
            _atributosFormulario = atributosUnicos.values.toList();
            // inicializar una muestra por cada atributo único
            _muestrasControllers.clear();
            for (final attr in _atributosFormulario) {
              final attrId = attr['id'];
              final tipoPlanta = attr['tipo_planta'];
              final key = '$attrId|$tipoPlanta';
              _muestrasControllers[key] = [TextEditingController()];
            }
            _errorMessage = null;
          });
          
          // Cargar tipos de planta después del setState
          await _cargarTiposPlanta();
          if (_atributosFormulario.isEmpty) {
            setState(() {
              _errorMessage = 'No hay configuración activa para esta labor en la especie seleccionada';
            });
          }
        } else {
          setState(() {
            _atributosFormulario = [];
            _muestrasControllers.clear();
            _errorMessage = data['message']?.toString() ?? 'No fue posible generar el formulario para esta labor';
          });
        }
      }
    } catch (e) {
      setState(() { _errorMessage = 'Error al cargar formulario dinámico: $e'; });
    }
  }

  void _agregarMuestraInicial(int atributoId, String tipoPlantaId) {
    final key = '$atributoId|$tipoPlantaId';
    setState(() {
      _muestrasControllers.putIfAbsent(key, () => []);
      _muestrasControllers[key]!.add(TextEditingController());
    });
  }

  void _agregarMuestra(int atributoId, String tipoPlantaId) {
    final key = '$atributoId|$tipoPlantaId';
    setState(() {
      _muestrasControllers.putIfAbsent(key, () => []);
      _muestrasControllers[key]!.add(TextEditingController());
    });
  }

  void _eliminarMuestra(int atributoId, String tipoPlantaId, int index) {
    final key = '$atributoId|$tipoPlantaId';
    setState(() {
      final lista = _muestrasControllers[key];
      if (lista != null && index >= 0 && index < lista.length) {
        final c = lista.removeAt(index);
        c.dispose();
      }
    });
  }

  Future<void> _cargarTiposPlanta() async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/tipos-planta'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Manejar la estructura correcta de la respuesta
          List<Map<String, dynamic>> tipos = [];
          if (data['data'] is List) {
            tipos = List<Map<String, dynamic>>.from(data['data']);
          } else if (data['data']['tipos'] is List) {
            tipos = List<Map<String, dynamic>>.from(data['data']['tipos']);
          }
          
          setState(() {
            _tiposPlanta = tipos;
          });
          
          // Debug: mostrar tipos cargados
          print('DEBUG: Tipos de planta cargados: ${tipos.map((t) => '${t['id']}: ${t['nombre']}').join(', ')}');
        } else {
          setState(() {
            _errorMessage = 'Error en la respuesta del servidor: ${data['message'] ?? 'Respuesta inválida'}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error HTTP ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar tipos de planta: $e';
      });
    }
  }

  Future<void> _guardarPauta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_laborSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una labor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Preparar detalles desde las muestras dinámicas
      List<Map<String, dynamic>> detalles = [];
      _muestrasControllers.forEach((key, controllers) {
        final parts = key.split('|');
        if (parts.length != 2) return;
        final idAtributo = int.tryParse(parts[0]);
        final idTipo = parts[1];
        if (idAtributo == null) return;
        for (final c in controllers) {
          final valor = double.tryParse(c.text.trim());
          if (valor != null && valor > 0) {
            detalles.add({
              'id_atributo': idAtributo,
              'id_tipoplanta': idTipo,
              'valor_atributo': valor,
            });
          }
        }
      });

      // Usar el nuevo endpoint unificado
      final pautaData = {
        'id_cuartel': widget.cuartel['id'],
        'id_temporada': 1,
        'fecha': DateTime.now().toIso8601String().split('T')[0],
        if (_idConteoTipo != null) 'id_conteotipo': _idConteoTipo,
        'detalles': detalles,
      };

      final response = await HttpInterceptor.post(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/pautas-completa'),
        body: pautaData,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pauta creada exitosamente: ${data['data']['pauta_id']}'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onPautaCreada();
          Navigator.pop(context);
        } else {
          throw Exception(data['message'] ?? 'Error al crear pauta');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al crear pauta: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Crear Nueva Pauta',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Información del cuartel
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cuartel: ${widget.cuartel['nombre']}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_especieData != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_florist,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Especie: ${_especieData!['nombre_especie']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Variedad: ${_especieData!['nombre_variedad']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_idConteoTipo == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Selecciona una labor con configuración activa para continuar',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Labor
              Text(
                'Labor *',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              _laboresDisponibles.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cargando labores...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<Map<String, dynamic>>(
                      value: _laborSeleccionada,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Selecciona una labor'),
                      items: _laboresDisponibles.map((labor) {
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: labor,
                          child: Text(_getLaborDisplay(labor)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _laborSeleccionada = value;
                          // Usar SIEMPRE id_labor para pedir el formulario. Si no viene, caer a id (pivot) solo como último recurso.
                          _laborIdSeleccionada = int.tryParse((value?['id_labor'] ?? value?['labor_id'] ?? value?['id']).toString());
                          _laborNombreSeleccionada = _getLaborDisplay(value ?? {});
                          // limpiar formulario previo
                          _atributosFormulario = [];
                          _muestrasControllers.clear();
                          _idConteoTipo = null;
                          _errorMessage = null;
                        });
                        if (_laborIdSeleccionada != null) {
                          _cargarFormularioDinamico(_laborIdSeleccionada!);
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor selecciona una labor';
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 16),

              // Formulario dinámico por atributo único
              if (_atributosFormulario.isNotEmpty)
                ..._atributosFormulario.map((attr) {
                  final int atributoId = attr['id'];
                  final String nombreAtributo = attr['nombre_atributo'];
                  final String tipoPlanta = attr['tipo_planta'];
                  // Mapeo directo de tipos según la tabla mostrada
                  String nombreTipoPlanta = 'TIPO $tipoPlanta';
                  switch (tipoPlanta) {
                    case '4':
                      nombreTipoPlanta = 'TIPO 7 (PRODUCTIVA)';
                      break;
                    case '3':
                      nombreTipoPlanta = 'TIPO 5 (PRODUCTIVIDAD MEDIA)';
                      break;
                    case '2':
                      nombreTipoPlanta = 'TIPO 3 (PRODUCTIVIDAD BAJA)';
                      break;
                    case '1':
                      nombreTipoPlanta = 'TIPO 1 (REPLANTE)';
                      break;
                    case '0':
                      nombreTipoPlanta = 'TIPO 0 (PLANTA MUERTA)';
                      break;
                    default:
                      // Intentar obtener desde _tiposPlanta si está disponible
                      try {
                        final tipo = _tiposPlanta.firstWhere(
                          (t) => (t['id'] ?? t['tipo_id']).toString() == tipoPlanta,
                        );
                        nombreTipoPlanta = tipo['nombre'] ?? tipo['descripcion'] ?? 'TIPO $tipoPlanta';
                      } catch (e) {
                        nombreTipoPlanta = 'TIPO $tipoPlanta';
                      }
                  }
                  final key = '$atributoId|$tipoPlanta';
                  final muestras = _muestrasControllers[key] ?? [];
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header del atributo con tipo de planta
                          Row(
                            children: [
                              Icon(Icons.analytics, color: AppTheme.primaryColor, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$nombreAtributo - $nombreTipoPlanta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              // Botones para agregar/eliminar valores
                              if (muestras.isNotEmpty)
                                IconButton(
                                  onPressed: () => _eliminarMuestra(atributoId, tipoPlanta, muestras.length - 1),
                                  icon: Icon(Icons.remove_circle_outline, size: 20, color: Colors.red[600]),
                                  tooltip: 'Eliminar último valor',
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                              IconButton(
                                onPressed: () => _agregarMuestra(atributoId, tipoPlanta),
                                icon: Icon(Icons.add_circle_outline, size: 20, color: Colors.green[600]),
                                tooltip: 'Agregar valor',
                                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Campos de entrada para las muestras
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(muestras.length, (index) {
                              final controller = muestras[index];
                              return Container(
                                width: 140,
                                child: TextFormField(
                                  controller: controller,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    hintText: 'Valor numérico',
                                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                                  ),
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

              const SizedBox(height: 24),
              
              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading || _idConteoTipo == null || _atributosFormulario.isEmpty
                        ? null
                        : _guardarPauta,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Guardar Pauta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormularioCrearRendimientoModal extends StatefulWidget {
  final int cuartelId;
  final String cuartelNombre;
  final VoidCallback onRendimientoCreado;

  const _FormularioCrearRendimientoModal({
    required this.cuartelId,
    required this.cuartelNombre,
    required this.onRendimientoCreado,
  });

  @override
  _FormularioCrearRendimientoModalState createState() => _FormularioCrearRendimientoModalState();
}

class _FormularioCrearRendimientoModalState extends State<_FormularioCrearRendimientoModal> {
  final _formKey = GlobalKey<FormState>();
  final _rendimientoController = TextEditingController();
  final _fechaController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Establecer fecha actual por defecto
    _fechaController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _rendimientoController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nuevo Rendimiento Packing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Cuartel: ${widget.cuartelNombre}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Campo de fecha
              TextFormField(
                controller: _fechaController,
                decoration: InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La fecha es obligatoria';
                  }
                  try {
                    DateTime.parse(value);
                  } catch (e) {
                    return 'Formato de fecha inválido (YYYY-MM-DD)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de rendimiento
              TextFormField(
                controller: _rendimientoController,
                decoration: InputDecoration(
                  labelText: 'Rendimiento (%)',
                  hintText: '0-100',
                  suffixText: '%',
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El rendimiento es obligatorio';
                  }
                  final rendimiento = double.tryParse(value);
                  if (rendimiento == null || rendimiento < 0 || rendimiento > 100) {
                    return 'El rendimiento debe estar entre 0 y 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _guardarRendimiento,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarRendimiento() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final datos = {
          'rendimiento': double.parse(_rendimientoController.text),
          'fecha': _fechaController.text,
        };

        final response = await HttpInterceptor.post(
          context,
          Uri.parse('${ApiConfig.baseUrl}/estimaciones/cuartel/${widget.cuartelId}/rendimiento-packing'),
          body: jsonEncode(datos),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 201) {
          final result = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Rendimiento creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onRendimientoCreado();
          Navigator.of(context).pop();
        } else {
          final error = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['message'] ?? 'Error al guardar el rendimiento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
