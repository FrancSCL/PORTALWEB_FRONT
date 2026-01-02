import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';
import '../services/http_interceptor.dart';

class PautasCrearNuevaScreen extends StatefulWidget {
  final Map<String, dynamic>? cuartelPreseleccionado;
  
  const PautasCrearNuevaScreen({
    super.key,
    this.cuartelPreseleccionado,
  });

  @override
  State<PautasCrearNuevaScreen> createState() => _PautasCrearNuevaScreenState();
}

class _PautasCrearNuevaScreenState extends State<PautasCrearNuevaScreen> {
  int _currentStep = 0;
  PageController _pageController = PageController();
  
  // Datos del flujo
  List<Map<String, dynamic>> _cuarteles = [];
  Map<String, dynamic>? _cuartelSeleccionado;
  Map<String, dynamic>? _especieInfo;
  List<Map<String, dynamic>> _laboresDisponibles = [];
  Map<String, dynamic>? _laborSeleccionada;
  Map<String, dynamic>? _formularioData;
  Map<String, dynamic> _valoresFormulario = {};
  Map<String, String> _tiposPlantaSeleccionados = {};
  List<Map<String, dynamic>> _configuraciones = [];
  
  // Estados de carga
  bool _isLoadingCuarteles = false;
  bool _isLoadingEspecie = false;
  bool _isLoadingLabores = false;
  bool _isLoadingFormulario = false;
  bool _isGuardando = false;
  
  // Errores
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.cuartelPreseleccionado != null) {
      _cuartelSeleccionado = widget.cuartelPreseleccionado;
      // Cargar información de la especie del cuartel preseleccionado
      _cargarEspecieInfo();
    } else {
      _cargarCuarteles();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _cargarCuarteles() async {
    setState(() {
      _isLoadingCuarteles = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Usar endpoint específico para cuarteles de la sucursal activa del usuario
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/cuarteles/sucursal-activa'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _cuarteles = List<Map<String, dynamic>>.from(data['data']['cuarteles']);
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar cuarteles';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar cuarteles: $e';
      });
    } finally {
      setState(() {
        _isLoadingCuarteles = false;
      });
    }
  }

  Future<void> _cargarEspecieInfo() async {
    if (_cuartelSeleccionado == null) return;
    
    setState(() {
      _isLoadingEspecie = true;
      _errorMessage = null;
    });

    try {
      // Simular carga de información de especie
      // En un caso real, harías una llamada al backend
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _especieInfo = {
          'id': _cuartelSeleccionado!['id_variedad'],
          'nombre': _cuartelSeleccionado!['nombre_especie'],
          'cuartel_id': _cuartelSeleccionado!['id'],
        };
        _isLoadingEspecie = false;
      });
      
      // Avanzar al siguiente paso
      _siguientePaso();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar información de especie: $e';
        _isLoadingEspecie = false;
      });
    }
  }

  Future<void> _obtenerEspeciePorCuartel(int cuartelId) async {
    setState(() {
      _isLoadingEspecie = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/cuartel-especie/$cuartelId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _especieInfo = data['data'];
          });
          // Cargar labores disponibles para esta especie
          await _cargarLaboresPorEspecie(_especieInfo!['id_especie']);
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al obtener especie del cuartel';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al obtener especie del cuartel: $e';
      });
    } finally {
      setState(() {
        _isLoadingEspecie = false;
      });
    }
  }

  Future<void> _cargarLaboresPorEspecie(int especieId) async {
    setState(() {
      _isLoadingLabores = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/labores-por-especie/$especieId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _laboresDisponibles = List<Map<String, dynamic>>.from(data['data']['labores']);
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al cargar labores';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar labores: $e';
      });
    } finally {
      setState(() {
        _isLoadingLabores = false;
      });
    }
  }

  Future<void> _generarFormularioDinamico(int laborId, int especieId) async {
    setState(() {
      _isLoadingFormulario = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/formulario-dinamico/$laborId/$especieId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _formularioData = data['data'];
            _configuraciones = List<Map<String, dynamic>>.from(data['data']['atributos']);
            
            // Inicializar valores del formulario basado en las configuraciones
            _valoresFormulario = {};
            _tiposPlantaSeleccionados = {};
            
            for (var configuracion in _configuraciones) {
              final atributoId = configuracion['id_atributo'].toString();
              _valoresFormulario[atributoId] = '';
              
              // Inicializar tipo de planta si existe en la configuración
              if (configuracion['id_tipoplanta'] != null) {
                _tiposPlantaSeleccionados[atributoId] = configuracion['id_tipoplanta'].toString();
              }
            }
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Error al generar formulario';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al generar formulario: $e';
      });
    } finally {
      setState(() {
        _isLoadingFormulario = false;
      });
    }
  }

  void _seleccionarCuartel(Map<String, dynamic> cuartel) {
    setState(() {
      _cuartelSeleccionado = cuartel;
    });
    _obtenerEspeciePorCuartel(cuartel['id']);
  }

  void _seleccionarLabor(Map<String, dynamic> labor) {
    setState(() {
      _laborSeleccionada = labor;
    });
    _generarFormularioDinamico(labor['id_labor'], _especieInfo!['id_especie']);
  }

  void _siguientePaso() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pasoAnterior() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _guardarPauta() async {
    if (_formularioData == null) return;

    setState(() {
      _isGuardando = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Crear la pauta principal
      final pautaResponse = await HttpInterceptor.post(
        context,
        Uri.parse('${ApiConfig.baseUrl}/pautas/pautas'),
        body: {
          'id_cuartel': _cuartelSeleccionado!['id'],
          'id_temporada': 1, // TODO: Obtener temporada actual
          'observaciones': 'Pauta creada desde el nuevo flujo',
        },
      );

      if (pautaResponse.statusCode == 200 || pautaResponse.statusCode == 201) {
        final pautaData = json.decode(pautaResponse.body);
        
        if (pautaData['success'] == true) {
          final pautaId = pautaData['data']['id'];
          
          // Crear los detalles de la pauta basado en las configuraciones
          List<Map<String, dynamic>> detalles = [];
          for (var configuracion in _configuraciones) {
            final atributoId = configuracion['id_atributo'].toString();
            final valor = _valoresFormulario[atributoId];
            
            if (valor != null && valor.isNotEmpty) {
              // Obtener el tipo de planta seleccionado por el usuario
              final tipoPlantaSeleccionado = _tiposPlantaSeleccionados[atributoId];
              
              detalles.add({
                'id_atributo': configuracion['id_atributo'],
                'valor_atributo': double.tryParse(valor) ?? 0.0,
                'id_tipoplanta': tipoPlantaSeleccionado ?? configuracion['id_tipoplanta'],
                'observaciones': 'Valor ingresado desde formulario dinámico - ${configuracion['nombre_atributo']}',
              });
            }
          }

          // Crear detalles masivamente
          final detallesResponse = await HttpInterceptor.post(
            context,
            Uri.parse('${ApiConfig.baseUrl}/pautas/pautas/$pautaId/detalles-masivo'),
            body: {
              'detalles': detalles,
            },
          );

          if (detallesResponse.statusCode == 200 || detallesResponse.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pauta ${pautaData['data']['id']} creada exitosamente'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Volver a la pantalla anterior
            Navigator.pop(context);
          } else {
            setState(() {
              _errorMessage = 'Error al crear detalles de la pauta';
            });
          }
        } else {
          setState(() {
            _errorMessage = pautaData['message'] ?? 'Error al crear pauta';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error ${pautaResponse.statusCode}: ${pautaResponse.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar pauta: $e';
      });
    } finally {
      setState(() {
        _isGuardando = false;
      });
    }
  }

  Widget _buildPaso1() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso 1: Seleccionar Cuartel',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona el cuartel donde realizarás la pauta. El sistema obtendrá automáticamente la especie y variedad.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoadingCuarteles)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _cuarteles.length,
                itemBuilder: (context, index) {
                  final cuartel = _cuarteles[index];
                  final isSelected = _cuartelSeleccionado?['id'] == cuartel['id'];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.grey[300],
                        child: Icon(
                          Icons.location_on,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        cuartel['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('ID: ${cuartel['id']}'),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () => _seleccionarCuartel(cuartel),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 16),
          if (_cuartelSeleccionado != null && _especieInfo != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Cuartel:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Cuartel: ${_cuartelSeleccionado!['nombre']}'),
                  Text('Variedad: ${_especieInfo!['nombre_variedad']}'),
                  Text('Especie: ${_especieInfo!['nombre_especie']}'),
                  Text('Caja Equivalente: ${_especieInfo!['caja_equivalente']} kg'),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _cuartelSeleccionado != null && _especieInfo != null ? _siguientePaso : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Siguiente'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paso 2: Seleccionar Labor',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selecciona la labor que realizarás en el cuartel ${_cuartelSeleccionado?['nombre']} con ${_especieInfo?['nombre_especie']}.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoadingLabores)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _laboresDisponibles.length,
                itemBuilder: (context, index) {
                  final labor = _laboresDisponibles[index];
                  final isSelected = _laborSeleccionada?['id_labor'] == labor['id_labor'];
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected 
                            ? AppTheme.primaryColor 
                            : Colors.grey[300],
                        child: Icon(
                          Icons.work,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                      title: Text(
                        labor['nombre_labor'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text('Especie: ${labor['nombre_especie']}'),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                      onTap: () => _seleccionarLabor(labor),
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 16),
          if (_laborSeleccionada != null && _formularioData != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Labor Seleccionada:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Labor: ${_laborSeleccionada!['nombre_labor']}'),
                  Text('Especie: ${_laborSeleccionada!['nombre_especie']}'),
                  Text('Atributos a completar: ${_formularioData!['total_atributos']}'),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _pasoAnterior,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Anterior'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _laborSeleccionada != null && _formularioData != null ? _siguientePaso : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Siguiente'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaso3() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completar Formulario',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.grey[800],
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Labor ${_laborSeleccionada?['nombre_labor']} • ${_especieInfo?['nombre_especie']}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
          
          if (_isLoadingFormulario)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            )
          else if (_formularioData != null)
            Expanded(
              child: Column(
                children: [
                   // Información minimalista
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                     margin: const EdgeInsets.only(bottom: 32),
                     decoration: BoxDecoration(
                       border: Border(
                         bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                       ),
                     ),
                     child: Row(
                       children: [
                         Text(
                           '${_formularioData!['total_atributos']} atributos',
                           style: TextStyle(
                             fontSize: 14,
                             color: Colors.grey[500],
                             fontWeight: FontWeight.w400,
                           ),
                         ),
                         const Spacer(),
                         Text(
                           '${_formularioData!['labor_especie']['caja_equivalente']} kg caja',
                           style: TextStyle(
                             fontSize: 14,
                             color: Colors.grey[500],
                             fontWeight: FontWeight.w400,
                           ),
                         ),
                       ],
                     ),
                   ),
                  
                  // Mensaje cuando no hay configuraciones
                  if (_configuraciones.isEmpty)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 80,
                              color: Colors.orange[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No hay configuraciones creadas',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[200]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Para crear una pauta de ${_formularioData!['labor_especie']['nombre_labor']}-${_formularioData!['labor_especie']['nombre_especie']}, primero debes crear las configuraciones.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Las configuraciones definen qué atributos se van a medir para esta combinación labor-especie.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navegar a configuración conteo-pauta
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/parametros');
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Ir a Configuración'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Volver a Gestión de Pautas',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                   // Lista de atributos basada en configuraciones (solo si hay configuraciones)
                   if (_configuraciones.isNotEmpty)
                     Expanded(
                       child: ListView.builder(
                         itemCount: _configuraciones.length,
                         itemBuilder: (context, index) {
                           final configuracion = _configuraciones[index];
                           final atributoId = configuracion['id_atributo'].toString();
                           final valorActual = _valoresFormulario[atributoId] ?? '';
                           final tipoPlantaActual = _tiposPlantaSeleccionados[atributoId];
                           
                           return Container(
                             margin: const EdgeInsets.only(bottom: 24),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 // Título del atributo
                                 Row(
                                   children: [
                                     Text(
                                       configuracion['nombre_atributo'],
                                       style: TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.w500,
                                         color: Colors.grey[800],
                                       ),
                                     ),
                                     if (configuracion['nombre_tipo_planta'] != null) ...[
                                       const SizedBox(width: 8),
                                       Container(
                                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                         decoration: BoxDecoration(
                                           color: Colors.grey[100],
                                           borderRadius: BorderRadius.circular(4),
                                         ),
                                         child: Text(
                                           configuracion['nombre_tipo_planta'],
                                           style: TextStyle(
                                             fontSize: 12,
                                             color: Colors.grey[600],
                                             fontWeight: FontWeight.w400,
                                           ),
                                         ),
                                       ),
                                     ],
                                     const Spacer(),
                                     if (valorActual.isNotEmpty)
                                       Container(
                                         width: 8,
                                         height: 8,
                                         decoration: BoxDecoration(
                                           color: Colors.green[400],
                                           shape: BoxShape.circle,
                                         ),
                                       ),
                                   ],
                                 ),
                                 const SizedBox(height: 8),
                                 
                                 // Campo de entrada minimalista
                                 TextFormField(
                                   decoration: InputDecoration(
                                     hintText: 'Ingresa el valor',
                                     border: UnderlineInputBorder(
                                       borderSide: BorderSide(color: Colors.grey[300]!),
                                     ),
                                     enabledBorder: UnderlineInputBorder(
                                       borderSide: BorderSide(color: Colors.grey[300]!),
                                     ),
                                     focusedBorder: UnderlineInputBorder(
                                       borderSide: BorderSide(color: Colors.grey[800]!, width: 2),
                                     ),
                                     suffixText: 'kg',
                                     contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                   ),
                                   style: TextStyle(
                                     fontSize: 16,
                                     color: Colors.grey[800],
                                   ),
                                   keyboardType: TextInputType.number,
                                   initialValue: valorActual,
                                   onChanged: (value) {
                                     setState(() {
                                       _valoresFormulario[atributoId] = value;
                                     });
                                   },
                                 ),
                                   
                                 // Selector de tipo de planta minimalista
                                 if (configuracion['nombre_tipo_planta'] != null) ...[
                                   const SizedBox(height: 8),
                                   DropdownButtonFormField<String>(
                                     decoration: InputDecoration(
                                       hintText: 'Tipo de planta',
                                       border: UnderlineInputBorder(
                                         borderSide: BorderSide(color: Colors.grey[300]!),
                                       ),
                                       enabledBorder: UnderlineInputBorder(
                                         borderSide: BorderSide(color: Colors.grey[300]!),
                                       ),
                                       focusedBorder: UnderlineInputBorder(
                                         borderSide: BorderSide(color: Colors.grey[800]!, width: 2),
                                       ),
                                       contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                     ),
                                     style: TextStyle(
                                       fontSize: 14,
                                       color: Colors.grey[700],
                                     ),
                                     value: tipoPlantaActual ?? configuracion['id_tipoplanta']?.toString(),
                                     items: [
                                       DropdownMenuItem(
                                         value: configuracion['id_tipoplanta']?.toString(),
                                         child: Text(configuracion['nombre_tipo_planta']),
                                       ),
                                     ],
                                     onChanged: (value) {
                                       setState(() {
                                         _tiposPlantaSeleccionados[atributoId] = value ?? '';
                                       });
                                     },
                                   ),
                                 ],
                               ],
                             ),
                           );
                         },
                       ),
                     ),
                ],
              ),
            ),
          
          
           const SizedBox(height: 48),
           Row(
             children: [
               TextButton(
                 onPressed: _pasoAnterior,
                 style: TextButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                 ),
                 child: Text(
                   'Anterior',
                   style: TextStyle(
                     fontSize: 16,
                     color: Colors.grey[600],
                     fontWeight: FontWeight.w400,
                   ),
                 ),
               ),
               const Spacer(),
               ElevatedButton(
                 onPressed: _isGuardando ? null : _guardarPauta,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.grey[800],
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                   elevation: 0,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(2),
                   ),
                 ),
                 child: _isGuardando 
                     ? const SizedBox(
                         height: 16,
                         width: 16,
                         child: CircularProgressIndicator(
                           strokeWidth: 2,
                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                         ),
                       )
                     : Text(
                         'Guardar',
                         style: TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w400,
                         ),
                       ),
               ),
             ],
           ),
        ],
      ),
    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Error al cargar la información',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (widget.cuartelPreseleccionado != null) {
                  _cargarEspecieInfo();
                } else {
                  _cargarCuarteles();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Pauta'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: NavigationHelper.buildBackButton(context),
        actions: [
          NavigationHelper.buildHomeButton(context),
        ],
      ),
      body: _errorMessage != null ? _buildErrorWidget() : Column(
        children: [
           // Indicador de pasos compacto
           Container(
             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
             decoration: BoxDecoration(
               color: AppTheme.primaryColor.withOpacity(0.05),
             ),
             child: Row(
               children: [
                 _buildStepIndicator(0, 'Cuartel', Icons.location_on),
                 const SizedBox(width: 12),
                 _buildStepIndicator(1, 'Labor', Icons.work),
                 const SizedBox(width: 12),
                 _buildStepIndicator(2, 'Formulario', Icons.edit),
               ],
             ),
           ),
          
          // Contenido de los pasos
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPaso1(),
                _buildPaso2(),
                _buildPaso3(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isActive 
                ? AppTheme.primaryColor 
                : Colors.grey[300],
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive ? Colors.white : Colors.grey[600],
              size: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive ? AppTheme.primaryColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
