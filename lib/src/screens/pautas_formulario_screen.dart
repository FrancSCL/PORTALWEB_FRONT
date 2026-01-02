import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../widgets/main_scaffold.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class PautasFormularioScreen extends StatefulWidget {
  const PautasFormularioScreen({super.key});

  @override
  State<PautasFormularioScreen> createState() => _PautasFormularioScreenState();
}

class _PautasFormularioScreenState extends State<PautasFormularioScreen> {
  List<Map<String, dynamic>> _laborEspecie = [];
  List<Map<String, dynamic>> _cuarteles = [];
  List<Map<String, dynamic>> _temporadas = [];
  List<Map<String, dynamic>> _formularioCampos = [];
  List<Map<String, dynamic>> _tiposPlanta = [];
  
  bool _isLoading = true;
  bool _isGenerandoFormulario = false;
  bool _isGuardando = false;
  String? _errorMessage;

  // Variables del formulario
  int? _selectedLaborEspecie;
  int? _selectedCuartel;
  int? _selectedTemporada;
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  @override
  void dispose() {
    // Limpiar controladores
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _cargarLaborEspecie(),
        _cargarCuarteles(),
        _cargarTemporadas(),
      ]);
      
      // Verificar si se cargaron datos
      if (_laborEspecie.isEmpty && _cuarteles.isEmpty && _temporadas.isEmpty) {
        setState(() {
          _errorMessage = 'No se pudieron cargar los datos. Verifica tu conexión o contacta al administrador.';
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
        if (data['success'] == true && data['data'] != null && data['data']['labor_especie'] != null) {
          setState(() {
            _laborEspecie = List<Map<String, dynamic>>.from(data['data']['labor_especie']);
          });
        } else {
          print('Error en respuesta de labor-especie: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('Error HTTP en labor-especie: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar labor-especie: $e');
    }
  }

  Future<void> _cargarCuarteles() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cuarteles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['cuarteles'] != null) {
          setState(() {
            _cuarteles = List<Map<String, dynamic>>.from(data['data']['cuarteles']);
          });
        } else {
          print('Error en respuesta de cuarteles: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('Error HTTP en cuarteles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar cuarteles: $e');
    }
  }

  Future<void> _cargarTemporadas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/temporadas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['temporadas'] != null) {
          setState(() {
            _temporadas = List<Map<String, dynamic>>.from(data['data']['temporadas']);
          });
        } else {
          print('Error en respuesta de temporadas: ${data['message'] ?? 'Sin mensaje'}');
        }
      } else {
        print('Error HTTP en temporadas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al cargar temporadas: $e');
    }
  }

  Future<void> _generarFormulario() async {
    if (_selectedLaborEspecie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una labor-especie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGenerandoFormulario = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Obtener labor y especie del item seleccionado
      final laborEspecieItem = _laborEspecie.firstWhere(
        (item) => item['id'] == _selectedLaborEspecie,
      );

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/formulario/${laborEspecieItem['id_labor']}/${laborEspecieItem['id_especie']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _formularioCampos = List<Map<String, dynamic>>.from(data['data']['configuraciones']);
            _tiposPlanta = List<Map<String, dynamic>>.from(data['data']['tipos_planta']);
          });

          // Crear controladores para cada campo
          for (var campo in _formularioCampos) {
            final key = '${campo['id_atributo']}_${campo['id_tipoplanta'] ?? 'sin_tipo'}';
            _controllers[key] = TextEditingController();
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Formulario generado con ${_formularioCampos.length} campos'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al generar formulario'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error del servidor: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar formulario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerandoFormulario = false;
      });
    }
  }

  Future<void> _guardarPauta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCuartel == null || _selectedTemporada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona cuartel y temporada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isGuardando = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) return;

      // Crear pauta
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

      if (pautaResponse.statusCode == 201) {
        final pautaData = json.decode(pautaResponse.body);
        if (pautaData['success'] == true) {
          final pautaId = pautaData['data']['id'];

          // Crear detalles
          final detalles = <Map<String, dynamic>>[];
          for (var campo in _formularioCampos) {
            final key = '${campo['id_atributo']}_${campo['id_tipoplanta'] ?? 'sin_tipo'}';
            final controller = _controllers[key];
            if (controller != null && controller.text.isNotEmpty) {
              detalles.add({
                'id_atributo': campo['id_atributo'],
                'id_tipoplanta': campo['id_tipoplanta'],
                'valor_atributo': double.parse(controller.text),
              });
            }
          }

          if (detalles.isNotEmpty) {
            final detallesResponse = await http.post(
              Uri.parse('${ApiConfig.baseUrl}/pautas/pautas/$pautaId/detalles-masivo'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: json.encode({
                'detalles': detalles,
              }),
            );

            if (detallesResponse.statusCode == 201) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pauta creada exitosamente con ${detalles.length} detalles'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
              _limpiarFormulario();
            } else {
              final detallesData = json.decode(detallesResponse.body);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(detallesData['message'] ?? 'Error al crear detalles'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se ingresaron valores para ningún atributo'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        final pautaData = json.decode(pautaResponse.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pautaData['message'] ?? 'Error al crear pauta'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar pauta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGuardando = false;
      });
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _selectedLaborEspecie = null;
      _selectedCuartel = null;
      _selectedTemporada = null;
      _formularioCampos = [];
      _tiposPlanta = [];
    });

    // Limpiar controladores
    for (var controller in _controllers.values) {
      controller.clear();
    }

    _formKey.currentState?.reset();
  }

  Widget _buildSelectorLaborEspecie() {
    return Card(
      margin: const EdgeInsets.all(16),
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
                labelText: 'Labor-Especie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
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
                  _formularioCampos = []; // Limpiar formulario anterior
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona una labor-especie';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerandoFormulario ? null : _generarFormulario,
                icon: _isGenerandoFormulario
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.build),
                label: Text(_isGenerandoFormulario ? 'Generando...' : 'Generar Formulario'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioDinamico() {
    if (_formularioCampos.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.dynamic_form_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Selecciona una labor-especie y genera el formulario',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formulario Dinámico (${_formularioCampos.length} campos)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCuartel,
                      decoration: const InputDecoration(
                        labelText: 'Cuartel',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: _cuarteles.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(item['nombre']),
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedTemporada,
                      decoration: const InputDecoration(
                        labelText: 'Temporada',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: _temporadas.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'],
                          child: Text(item['nombre']),
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
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Atributos a Evaluar:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._formularioCampos.map((campo) {
                final key = '${campo['id_atributo']}_${campo['id_tipoplanta'] ?? 'sin_tipo'}';
                final controller = _controllers[key];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: campo['nombre_atributo'],
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.edit),
                      suffixText: campo['nombre_tipo_planta'] != null 
                          ? '(${campo['nombre_tipo_planta']})' 
                          : null,
                      suffixStyle: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (double.tryParse(value) == null) {
                          return 'Ingresa un número válido';
                        }
                      }
                      return null;
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isGuardando ? null : _guardarPauta,
                      icon: _isGuardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isGuardando ? 'Guardando...' : 'Guardar Pauta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _limpiarFormulario,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarDatosIniciales,
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
      return MainScaffold(
        title: 'Crear Pauta',
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return MainScaffold(
        title: 'Crear Pauta',
        body: _buildErrorState(),
      );
    }

    return MainScaffold(
      title: 'Crear Pauta',
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSelectorLaborEspecie(),
            _buildFormularioDinamico(),
          ],
        ),
      ),
    );
  }
}
