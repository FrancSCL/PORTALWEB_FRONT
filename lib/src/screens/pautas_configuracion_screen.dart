import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/main_scaffold.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';

class PautasConfiguracionScreen extends StatefulWidget {
  const PautasConfiguracionScreen({super.key});

  @override
  State<PautasConfiguracionScreen> createState() => _PautasConfiguracionScreenState();
}

class _PautasConfiguracionScreenState extends State<PautasConfiguracionScreen> {
  List<Map<String, dynamic>> _configuraciones = [];
  List<Map<String, dynamic>> _laborEspecie = [];
  List<Map<String, dynamic>> _atributos = [];
  List<Map<String, dynamic>> _tiposPlanta = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _expandedConfiguracionId;
  List<Map<String, dynamic>> _tiposConteo = [];
  int _totalConfiguraciones = 0;

  // Variables para el formulario
  int? _selectedLaborEspecie;
  int? _selectedAtributo;
  String? _selectedTipoPlanta;
  final _formKey = GlobalKey<FormState>();

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
      // Primero ejecutar debug para ver el estado de las tablas
      await _ejecutarDebug();
      
      await Future.wait([
        _cargarConfiguracionesAgrupadas(),
        _cargarLaborEspecie(),
        _cargarAtributos(),
        _cargarTiposPlanta(),
      ]);
      
      // Verificar si se cargaron datos esenciales
      if (_laborEspecie.isEmpty || _atributos.isEmpty) {
        setState(() {
          _errorMessage = 'No se pudieron cargar los datos esenciales. Verifica tu conexión o contacta al administrador.';
        });
      }
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

  Future<void> _ejecutarDebug() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/debug-tablas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 DEBUG INFO:');
        print('Tablas existentes: ${data['data']['tablas_existentes']}');
        print('Datos en tablas: ${data['data']['datos_tablas']}');
        print('Errores: ${data['data']['errores']}');
        
        // Mostrar información específica sobre configuraciones
        final configuracionesCount = data['data']['datos_tablas']['conteo_dim_configpauta'] ?? 0;
        print('📋 Configuraciones en BD: $configuracionesCount');
        
        if (configuracionesCount == 0) {
          print('⚠️ No hay configuraciones de pauta en la base de datos');
        } else {
          print('✅ Hay $configuracionesCount configuraciones en la base de datos');
        }
      } else {
        print('❌ Error en debug: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error ejecutando debug: $e');
    }
  }

  Future<void> _debugRespuestaCompleta() async {
    try {
      print('🚨 === DEBUG COMPLETO DE RESPUESTA ===');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        print('🚨 ❌ NO HAY TOKEN');
        return;
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/configuraciones-agrupadas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🚨 Status Code: ${response.statusCode}');
      print('🚨 Response Headers: ${response.headers}');
      print('🚨 Response Body (RAW): ${response.body}');
      print('🚨 Response Body Length: ${response.body.length}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('🚨 Parsed JSON Successfully');
          print('🚨 JSON Keys: ${data.keys.toList()}');
          print('🚨 Full JSON Structure:');
          print(json.encode(data));
          
          if (data['success'] != null) {
            print('🚨 success field: ${data['success']} (type: ${data['success'].runtimeType})');
          } else {
            print('🚨 ❌ NO HAY CAMPO success');
          }
          
          if (data['data'] != null) {
            print('🚨 data field exists: ${data['data'].runtimeType}');
            print('🚨 data keys: ${data['data'].keys.toList()}');
            
            if (data['data']['tipos_conteo'] != null) {
              print('🚨 tipos_conteo exists: ${data['data']['tipos_conteo'].runtimeType}');
              print('🚨 tipos_conteo length: ${data['data']['tipos_conteo'].length}');
            } else {
              print('🚨 ❌ NO HAY CAMPO tipos_conteo');
            }
          } else {
            print('🚨 ❌ NO HAY CAMPO data');
          }
          
        } catch (e) {
          print('🚨 ❌ Error parsing JSON: $e');
        }
      } else {
        print('🚨 ❌ HTTP Error: ${response.statusCode}');
        print('🚨 ❌ Error Body: ${response.body}');
      }
      
      print('🚨 === FIN DEBUG COMPLETO ===');
      
    } catch (e) {
      print('🚨 ❌ Exception in debug: $e');
    }
  }

  Future<void> _cargarConfiguracionesAgrupadas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      print('❌ NO HAY TOKEN');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 === INICIANDO CARGA DE CONFIGURACIONES ===');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/configuraciones-agrupadas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Status Code: ${response.statusCode}');
      print('🔍 Response Body Length: ${response.body.length}');
      print('🔍 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('✅ JSON parseado exitosamente');
          print('🔍 Data Keys: ${data.keys.toList()}');
          
          // MOSTRAR TODA LA ESTRUCTURA
          print('🚨 === ESTRUCTURA COMPLETA ===');
          print('🚨 success: ${data['success']} (${data['success'].runtimeType})');
          print('🚨 message: ${data['message']}');
          print('🚨 data exists: ${data['data'] != null}');
          
          if (data['data'] != null) {
            print('🚨 data keys: ${data['data'].keys.toList()}');
            print('🚨 data type: ${data['data'].runtimeType}');
            
            if (data['data']['tipos_conteo'] != null) {
              print('🚨 tipos_conteo exists: ${data['data']['tipos_conteo'].runtimeType}');
              print('🚨 tipos_conteo length: ${data['data']['tipos_conteo'].length}');
              
              // PROCESAR DATOS SIN IMPORTAR LA ESTRUCTURA
              final tiposConteoData = data['data']['tipos_conteo'] as List;
              print('🚨 Procesando ${tiposConteoData.length} tipos de conteo');
              
              setState(() {
                _tiposConteo = List<Map<String, dynamic>>.from(tiposConteoData);
                _totalConfiguraciones = data['data']['total_configuraciones'] ?? 0;
              });
              
              print('✅ DATOS CARGADOS EXITOSAMENTE');
              print('✅ Tipos de conteo: ${_tiposConteo.length}');
              print('✅ Total configuraciones: $_totalConfiguraciones');
              
              // Mostrar cada tipo
              for (int i = 0; i < _tiposConteo.length; i++) {
                final tipo = _tiposConteo[i];
                print('🔍 Tipo $i: ${tipo['nombre_labor']} - ${tipo['nombre_especie']} (${tipo['total_configuraciones']} configs)');
              }
              
            } else {
              print('❌ NO HAY tipos_conteo en data');
            }
          } else {
            print('❌ NO HAY data en la respuesta');
          }
          
          print('🚨 === FIN ESTRUCTURA ===');
          
        } catch (e) {
          print('❌ Error parseando JSON: $e');
          setState(() {
            _errorMessage = 'Error parseando respuesta: $e';
          });
        }
      } else {
        print('❌ Error HTTP: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      print('❌ Error general: $e');
      setState(() {
        _errorMessage = 'Error al cargar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🔄 === FIN CARGA DE CONFIGURACIONES ===');
    }
  }

  Future<void> _cargarConfiguraciones() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/configuraciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🔍 Status Code: ${response.statusCode}');
      print('🔍 Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Parsed Data: $data');
        print('🔍 Data Keys: ${data.keys}');
        if (data['data'] != null) {
          print('🔍 Data.data Keys: ${data['data'].keys}');
        }
        
        if (data['success'] == true && data['data'] != null) {
          final configuracionesData = data['data']['configuraciones'] ?? data['data']['configuraciones_pauta'];
          
          if (configuracionesData != null) {
            setState(() {
              _configuraciones = List<Map<String, dynamic>>.from(configuracionesData);
            });
            print('✅ Configuraciones cargadas: ${_configuraciones.length}');
            
            // Debug: Mostrar estructura de cada configuración
            for (int i = 0; i < _configuraciones.length; i++) {
              final config = _configuraciones[i];
              print('🔍 Configuración $i: ${config.keys}');
              print('🔍 Tipo de planta: ${config['nombre_tipo_planta']}');
              print('🔍 Tipo de planta (alt): ${config['tipo_planta']}');
              print('🔍 Tipo de planta (alt2): ${config['nombre_tipoplanta']}');
            }
            
          } else {
            print('⚠️ No se encontró configuraciones en la respuesta');
            print('Estructura de data.data: ${data['data'].keys}');
            // Si no hay configuraciones, mostrar mensaje informativo
            if (data['message'] != null) {
              print('📋 Mensaje del servidor: ${data['message']}');
            }
          }
        } else {
          print('❌ Error en respuesta de configuraciones: ${data['message'] ?? 'Sin mensaje'}');
          print('Estructura de data: ${data.keys}');
          if (data['data'] != null) {
            print('Estructura de data.data: ${data['data'].keys}');
          }
        }
      } else {
        print('❌ Error HTTP en configuraciones: ${response.statusCode}');
        print('❌ Respuesta del servidor: ${response.body}');
        
        // Mostrar error en la UI
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      print('❌ Error al cargar configuraciones: $e');
      setState(() {
        _errorMessage = 'Error al cargar configuraciones: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarLaborEspecie() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labor-especie'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Verificar si hay labor_especie o labor_especies (diferentes nombres posibles)
          final laborEspecieData = data['data']['labor_especie'] ?? data['data']['labor_especies'] ?? data['data']['labor_especie_combinations'];
          
          if (laborEspecieData != null) {
            setState(() {
              _laborEspecie = List<Map<String, dynamic>>.from(laborEspecieData);
            });
            print('✅ Labor-especie cargadas: ${_laborEspecie.length}');
          } else {
            print('⚠️ No se encontró labor_especie en la respuesta');
            print('Estructura de data.data: ${data['data'].keys}');
          }
        } else {
          print('❌ Error en respuesta de labor-especie: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('Error HTTP en labor-especie: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar labor-especie: $e');
    }
  }

  Future<void> _cargarAtributos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/atributos'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['atributos'] != null) {
          setState(() {
            _atributos = List<Map<String, dynamic>>.from(data['data']['atributos']);
          });
        } else {
          print('Error en respuesta de atributos: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('Error HTTP en atributos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar atributos: $e');
    }
  }

  Future<void> _cargarTiposPlanta() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/tipos-planta'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['tipos_planta'] != null) {
          setState(() {
            _tiposPlanta = List<Map<String, dynamic>>.from(data['data']['tipos_planta']);
          });
        } else {
          print('Error en respuesta de tipos-planta: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('Error HTTP en tipos-planta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar tipos-planta: $e');
    }
  }

  Future<void> _crearConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLaborEspecie == null || _selectedAtributo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona labor-especie y atributo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/configuraciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_conteotipo': _selectedLaborEspecie,
          'id_atributo': _selectedAtributo,
          'id_tipoplanta': _selectedTipoPlanta,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Configuración creada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _cargarConfiguraciones();
          _limpiarFormulario();
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error al crear configuración'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarConfiguracion(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/configuraciones/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Configuración eliminada exitosamente'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          _cargarConfiguraciones();
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error al eliminar configuración'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar configuración: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _selectedLaborEspecie = null;
      _selectedAtributo = null;
      _selectedTipoPlanta = null;
    });
    _formKey.currentState?.reset();
  }

  Widget _buildDebugPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Panel de Debug',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Usa este panel para diagnosticar problemas con las configuraciones de pautas.',
              style: TextStyle(
                color: Colors.orange[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _ejecutarDebug,
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Verificar BD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Revisa la consola del navegador (F12) para ver los resultados del debug'),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Ayuda'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange[600],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Configuración de Pauta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedLaborEspecie,
                      decoration: const InputDecoration(
                        labelText: 'Tipo Conteo',
                        border: OutlineInputBorder(),
                      ),
                      items: _laborEspecie.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text('${item['nombre_labor']} - ${item['nombre_especie']}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLaborEspecie = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una labor-especie';
                        }
                        return null;
                      },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedAtributo,
                      decoration: const InputDecoration(
                        labelText: 'Atributo',
                        border: OutlineInputBorder(),
                      ),
                      items: _atributos.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(item['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAtributo = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona un atributo';
                        }
                        return null;
                      },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
                value: _selectedTipoPlanta,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Planta (Opcional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Sin tipo de planta'),
                  ),
                  ..._tiposPlanta.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['id'],
                      child: Text(item['nombre']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTipoPlanta = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _crearConfiguracion,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Configuración'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                    onPressed: _limpiarFormulario,
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildConfiguracionDetalle(Map<String, dynamic> config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Atributo', config['nombre_atributo'] ?? 'No especificado'),
                  const SizedBox(height: 4),
                  _buildDetailRow('Tipo de Planta', 
                    config['nombre_tipo_planta'] ?? 
                    config['tipo_planta'] ?? 
                    config['nombre_tipoplanta'] ?? 
                    'No especificado'),
                  const SizedBox(height: 4),
                  _buildDetailRow('ID Configuración', config['id'].toString()),
                  const SizedBox(height: 4),
                  _buildDetailRow('ID Empresa', config['id_empresa'].toString()),
                ],
              ),
            ),
            // Botón de eliminar temporalmente deshabilitado
            // IconButton(
            //   icon: const Icon(Icons.delete, color: Colors.red, size: 18),
            //   onPressed: () {
            //     showDialog(
            //       context: context,
            //       builder: (context) => AlertDialog(
            //         title: const Text('Eliminar Configuración'),
            //         content: const Text('¿Estás seguro de que quieres eliminar esta configuración?'),
            //         actions: [
            //           TextButton(
            //             onPressed: () => Navigator.pop(context),
            //             child: const Text('Cancelar'),
            //           ),
            //           TextButton(
            //             onPressed: () {
            //               Navigator.pop(context);
            //               _eliminarConfiguracion(config['id']);
            //             },
            //             child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ],
    );
  }

  void _eliminarTipoConteo(String tipoConteoKey) {
    // Encontrar el tipo de conteo correspondiente
    final tipoConteo = _tiposConteo.firstWhere(
      (tipo) => '${tipo['nombre_labor']} - ${tipo['nombre_especie']}' == tipoConteoKey,
    );
    
    final configuracionesDelTipo = List<Map<String, dynamic>>.from(tipoConteo['configuraciones'] ?? []);
    
    for (final config in configuracionesDelTipo) {
      _eliminarConfiguracion(config['id']);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eliminando todas las configuraciones de $tipoConteoKey...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfiguracionesList() {
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Cargando configuraciones...',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verificando base de datos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (_tiposConteo.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No hay configuraciones de pautas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'El backend reporta que hay 6 configuraciones reales.\nVerifica la consola para más detalles.\n\nTipos de conteo cargados: ${_tiposConteo.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _cargarDatos,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualizar Lista'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _ejecutarDebug,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug BD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                   ElevatedButton.icon(
                     onPressed: _cargarConfiguracionesAgrupadas,
                     icon: const Icon(Icons.refresh),
                     label: const Text('Probar Endpoint Agrupado'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue,
                       foregroundColor: Colors.white,
                     ),
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton.icon(
                     onPressed: _debugRespuestaCompleta,
                     icon: const Icon(Icons.bug_report),
                     label: const Text('Debug Respuesta'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.red,
                       foregroundColor: Colors.white,
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Configuraciones Existentes ($_totalConfiguraciones)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tiposConteo.length,
            itemBuilder: (context, index) {
              final tipoConteo = _tiposConteo[index];
              final configuracionesDelTipo = List<Map<String, dynamic>>.from(tipoConteo['configuraciones'] ?? []);
              final tipoConteoKey = '${tipoConteo['nombre_labor']} - ${tipoConteo['nombre_especie']}';
              final isExpanded = _expandedConfiguracionId == tipoConteoKey;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.settings,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    tipoConteoKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${tipoConteo['total_configuraciones']} configuraciones',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.primaryColor,
                  ),
                  onExpansionChanged: (expanded) {
                    setState(() {
                      _expandedConfiguracionId = expanded ? tipoConteoKey : null;
                    });
                  },
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuraciones de $tipoConteoKey',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...configuracionesDelTipo.asMap().entries.map((entry) {
                            final index = entry.key;
                            final config = entry.value;
                            return Column(
                              children: [
                                if (index > 0) ...[
                                  const Divider(height: 20),
                                ],
                                _buildConfiguracionDetalle(config),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error del sistema',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Pautas'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: NavigationHelper.buildBackButton(context),
          actions: [
            NavigationHelper.buildHomeButton(context),
          ],
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Configuración de Pautas'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          leading: NavigationHelper.buildBackButton(context),
          actions: [
            NavigationHelper.buildHomeButton(context),
          ],
        ),
        body: _buildErrorState(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Pautas'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: NavigationHelper.buildBackButton(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver al menú principal',
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulario fijo arriba
          _buildFormulario(),
          // Configuraciones scrolleables
          Expanded(
            child: _buildConfiguracionesList(),
          ),
        ],
      ),
    );
  }
}
