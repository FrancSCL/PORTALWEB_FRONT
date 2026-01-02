import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class PautasFormularioDinamicoScreen extends StatefulWidget {
  const PautasFormularioDinamicoScreen({super.key});

  @override
  State<PautasFormularioDinamicoScreen> createState() => _PautasFormularioDinamicoScreenState();
}

class _PautasFormularioDinamicoScreenState extends State<PautasFormularioDinamicoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Labor-Especie
  List<Map<String, dynamic>> _laborEspecies = [];
  bool _isLoadingLaborEspecies = false;
  String? _errorLaborEspecies;
  
  // Formulario dinámico
  Map<String, dynamic>? _formularioData;
  List<Map<String, dynamic>> _configuraciones = [];
  List<Map<String, dynamic>> _tiposPlanta = [];
  bool _isLoadingFormulario = false;
  String? _errorFormulario;
  
  // Temporadas y Cuarteles
  List<Map<String, dynamic>> _temporadas = [];
  List<Map<String, dynamic>> _cuarteles = [];
  
  // Estados del formulario
  int? _selectedLaborEspecie;
  int? _selectedTemporada;
  int? _selectedCuartel;
  
  // Controllers para valores dinámicos
  Map<String, TextEditingController> _valorControllers = {};
  Map<String, String?> _tipoPlantaSelections = {};
  
  // Estados de creación
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valorControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarLaborEspecies(),
      _cargarTemporadas(),
      _cargarCuarteles(),
    ]);
  }

  Future<void> _cargarLaborEspecies() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingLaborEspecies = true;
      _errorLaborEspecies = null;
    });

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
        if (data['success'] == true) {
          setState(() {
            _laborEspecies = List<Map<String, dynamic>>.from(data['data']['labor_especies']);
          });
        } else {
          setState(() {
            _errorLaborEspecies = data['message'] ?? 'Error al cargar labor-especie';
          });
        }
      } else {
        setState(() {
          _errorLaborEspecies = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorLaborEspecies = 'Error al cargar labor-especie: $e';
      });
    } finally {
      setState(() {
        _isLoadingLaborEspecies = false;
      });
    }
  }

  Future<void> _cargarTemporadas() async {
    // TODO: Implementar endpoint de temporadas
    // Por ahora usamos datos mock
    setState(() {
      _temporadas = [
        {'id': 1, 'nombre': 'Temporada 2024-2025'},
        {'id': 2, 'nombre': 'Temporada 2023-2024'},
      ];
    });
  }

  Future<void> _cargarCuarteles() async {
    // TODO: Implementar endpoint de cuarteles
    // Por ahora usamos datos mock
    setState(() {
      _cuarteles = [
        {'id': 1, 'nombre': 'Cuartel Norte'},
        {'id': 2, 'nombre': 'Cuartel Sur'},
        {'id': 3, 'nombre': 'Cuartel Este'},
      ];
    });
  }

  Future<void> _generarFormularioDinamico(int laborId, int especieId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingFormulario = true;
      _errorFormulario = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/formulario/$laborId/$especieId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _formularioData = data['data'];
            _configuraciones = List<Map<String, dynamic>>.from(data['data']['configuraciones']);
            _tiposPlanta = List<Map<String, dynamic>>.from(data['data']['tipos_planta']);
          });
          
          // Inicializar controllers para cada configuración
          _inicializarControllers();
          
        } else {
          setState(() {
            _errorFormulario = data['message'] ?? 'Error al generar formulario';
          });
        }
      } else {
        setState(() {
          _errorFormulario = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorFormulario = 'Error al generar formulario: $e';
      });
    } finally {
      setState(() {
        _isLoadingFormulario = false;
      });
    }
  }

  void _inicializarControllers() {
    // Limpiar controllers anteriores
    _valorControllers.values.forEach((controller) => controller.dispose());
    _valorControllers.clear();
    _tipoPlantaSelections.clear();
    
    // Crear controllers para cada configuración
    for (var config in _configuraciones) {
      String key = '${config['id_atributo']}_${config['id_tipoplanta'] ?? 'sin_tipo'}';
      _valorControllers[key] = TextEditingController();
      _tipoPlantaSelections[key] = config['id_tipoplanta'];
    }
  }

  Future<void> _crearPautaCompleta() async {
    if (_selectedLaborEspecie == null || _selectedTemporada == null || _selectedCuartel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar que todos los valores estén completos
    for (var config in _configuraciones) {
      String key = '${config['id_atributo']}_${config['id_tipoplanta'] ?? 'sin_tipo'}';
      if (_valorControllers[key]?.text.trim().isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Completa el valor para ${config['nombre_atributo']}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      // 1. Crear la pauta
      final pautaResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/pautas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_conteotipo': _selectedLaborEspecie,
          'id_temporada': _selectedTemporada,
          'id_cuartel': _selectedCuartel,
        }),
      );

      if (pautaResponse.statusCode == 200 || pautaResponse.statusCode == 201) {
        final pautaData = json.decode(pautaResponse.body);
        if (pautaData['success'] == true) {
          String pautaId = pautaData['data']['id'];
          
          // 2. Crear los detalles de la pauta
          List<Map<String, dynamic>> detalles = [];
          for (var config in _configuraciones) {
            String key = '${config['id_atributo']}_${config['id_tipoplanta'] ?? 'sin_tipo'}';
            double valor = double.parse(_valorControllers[key]!.text);
            
            detalles.add({
              'id_atributo': config['id_atributo'],
              'id_tipoplanta': config['id_tipoplanta'],
              'valor_atributo': valor,
            });
          }

          final detallesResponse = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/pautas/pautas/$pautaId/detalles-masivo'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'detalles': detalles}),
          );

          if (detallesResponse.statusCode == 200 || detallesResponse.statusCode == 201) {
            final detallesData = json.decode(detallesResponse.body);
            if (detallesData['success'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pauta creada exitosamente con ${detallesData['data']['total_creados']} detalles'),
                  backgroundColor: Colors.green,
                ),
              );
              _limpiarFormulario();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(detallesData['message'] ?? 'Error al crear detalles'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al crear detalles: ${detallesResponse.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(pautaData['message'] ?? 'Error al crear pauta'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear pauta: ${pautaResponse.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear pauta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _selectedLaborEspecie = null;
      _selectedTemporada = null;
      _selectedCuartel = null;
      _formularioData = null;
      _configuraciones.clear();
      _tiposPlanta.clear();
    });
    _valorControllers.values.forEach((controller) => controller.clear());
    _tipoPlantaSelections.clear();
  }

  Widget _buildSelectorLaborEspecie() {
    if (_isLoadingLaborEspecies) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLaborEspecies != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar labor-especie',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorLaborEspecies!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarLaborEspecies,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Labor-Especie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedLaborEspecie,
              decoration: const InputDecoration(
                labelText: 'Labor - Especie',
                border: OutlineInputBorder(),
              ),
              items: _laborEspecies.map((item) {
                return DropdownMenuItem<int>(
                  value: item['id'],
                  child: Text('${item['nombre_labor']} - ${item['nombre_especie']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLaborEspecie = value;
                });
                if (value != null) {
                  var selectedItem = _laborEspecies.firstWhere((e) => e['id'] == value);
                  _generarFormularioDinamico(selectedItem['id_labor'], selectedItem['id_especie']);
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona una labor-especie';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectedLaborEspecie != null ? () {
                var item = _laborEspecies.firstWhere((e) => e['id'] == _selectedLaborEspecie);
                _generarFormularioDinamico(item['id_labor'], item['id_especie']);
              } : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Generar Formulario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioDinamico() {
    if (_isLoadingFormulario) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorFormulario != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al generar formulario',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorFormulario!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_formularioData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Selecciona una Labor-Especie',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para generar el formulario dinámico',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formulario Dinámico',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Información de la labor-especie seleccionada
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${_formularioData!['labor_especie']['nombre_labor']} - ${_formularioData!['labor_especie']['nombre_especie']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Campos dinámicos
            ..._configuraciones.map((config) {
              String key = '${config['id_atributo']}_${config['id_tipoplanta'] ?? 'sin_tipo'}';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        config['nombre_atributo'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (config['id_tipoplanta'] != null) ...[
                      Expanded(
                        child: Text(
                          'Tipo: ${config['nombre_tipo_planta']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                    Expanded(
                      child: TextFormField(
                        controller: _valorControllers[key],
                        decoration: const InputDecoration(
                          labelText: 'Valor',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Número válido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioPauta() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos de la Pauta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Temporada
            DropdownButtonFormField<int>(
              value: _selectedTemporada,
              decoration: const InputDecoration(
                labelText: 'Temporada',
                border: OutlineInputBorder(),
              ),
              items: _temporadas.map((temporada) {
                return DropdownMenuItem<int>(
                  value: temporada['id'],
                  child: Text(temporada['nombre']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTemporada = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona una temporada';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Cuartel
            DropdownButtonFormField<int>(
              value: _selectedCuartel,
              decoration: const InputDecoration(
                labelText: 'Cuartel',
                border: OutlineInputBorder(),
              ),
              items: _cuarteles.map((cuartel) {
                return DropdownMenuItem<int>(
                  value: cuartel['id'],
                  child: Text(cuartel['nombre']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCuartel = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un cuartel';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Botón crear
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _crearPautaCompleta,
                icon: _isCreating 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isCreating ? 'Creando...' : 'Crear Pauta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Formulario Dinámico de Pautas',
      body: Column(
        children: [
          Container(
            color: AppTheme.primaryColor.withOpacity(0.1),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: AppTheme.primaryColor,
              tabs: const [
                Tab(
                  icon: Icon(Icons.build),
                  text: 'Configurar',
                ),
                Tab(
                  icon: Icon(Icons.description),
                  text: 'Formulario',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Configuración
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSelectorLaborEspecie(),
                      _buildFormularioDinamico(),
                    ],
                  ),
                ),
                // Tab de Formulario
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildFormularioPauta(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
