import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class MuestrasScreen extends StatefulWidget {
  const MuestrasScreen({super.key});

  @override
  State<MuestrasScreen> createState() => _MuestrasScreenState();
}

class _MuestrasScreenState extends State<MuestrasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Muestras
  List<Map<String, dynamic>> _muestras = [];
  bool _isLoadingMuestras = false;
  String? _errorMuestras;
  
  // Configuraciones para el formulario
  List<Map<String, dynamic>> _configuraciones = [];
  List<Map<String, dynamic>> _temporadas = [];
  List<Map<String, dynamic>> _cuarteles = [];
  
  // Formulario
  final _formKey = GlobalKey<FormState>();
  final _valorAtributoController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  // Estados del formulario
  int? _selectedConfiguracion;
  int? _selectedTemporada;
  int? _selectedCuartel;
  int? _selectedPlanta;
  String? _selectedTipoPlanta;
  
  // Estados de edición
  String? _editingMuestraId;
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
    _valorAtributoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarMuestras(),
      _cargarConfiguraciones(),
      _cargarTemporadas(),
      _cargarCuarteles(),
    ]);
  }

  Future<void> _cargarMuestras() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingMuestras = true;
      _errorMuestras = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/muestras'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _muestras = List<Map<String, dynamic>>.from(data['data']['muestras']);
          });
        } else {
          setState(() {
            _errorMuestras = data['message'] ?? 'Error al cargar muestras';
          });
        }
      } else {
        setState(() {
          _errorMuestras = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMuestras = 'Error al cargar muestras: $e';
      });
    } finally {
      setState(() {
        _isLoadingMuestras = false;
      });
    }
  }

  Future<void> _cargarConfiguraciones() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/configuraciones-agrupadas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data']['tipos_conteo'] != null) {
          List<Map<String, dynamic>> configuraciones = [];
          for (var tipo in data['data']['tipos_conteo']) {
            for (var config in tipo['configuraciones']) {
              configuraciones.add({
                'id': config['id'],
                'nombre': '${config['nombre_labor']} - ${config['nombre_especie']} - ${config['nombre_atributo']}',
                'nombre_labor': config['nombre_labor'],
                'nombre_especie': config['nombre_especie'],
                'nombre_atributo': config['nombre_atributo'],
                'config_tipoplanta': config['config_tipoplanta'],
              });
            }
          }
          setState(() {
            _configuraciones = configuraciones;
          });
        }
      }
    } catch (e) {
      print('Error cargando configuraciones: $e');
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

  Future<void> _crearMuestra() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/muestras'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_configuracion': _selectedConfiguracion,
          'id_temporada': _selectedTemporada,
          'id_cuartel': _selectedCuartel,
          'valor_atributo': double.parse(_valorAtributoController.text),
          'id_planta': _selectedPlanta,
          'id_tipoplanta': _selectedTipoPlanta,
          'observaciones': _observacionesController.text.trim().isEmpty 
              ? null 
              : _observacionesController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Muestra creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _limpiarFormulario();
          _cargarMuestras();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al crear muestra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${response.statusCode}: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear muestra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _actualizarMuestra(String id) async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/pautas/muestras/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'valor_atributo': double.parse(_valorAtributoController.text),
          'observaciones': _observacionesController.text.trim().isEmpty 
              ? null 
              : _observacionesController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Muestra actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _limpiarFormulario();
          _cargarMuestras();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al actualizar muestra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${response.statusCode}: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar muestra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  Future<void> _eliminarMuestra(String id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/muestras/$id'),
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
              content: Text(data['message'] ?? 'Muestra eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarMuestras();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al eliminar muestra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${response.statusCode}: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar muestra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editarMuestra(Map<String, dynamic> muestra) {
    setState(() {
      _editingMuestraId = muestra['id'];
      _selectedConfiguracion = muestra['id_configuracion'];
      _selectedTemporada = muestra['id_temporada'];
      _selectedCuartel = muestra['id_cuartel'];
      _selectedPlanta = muestra['id_planta'];
      _selectedTipoPlanta = muestra['id_tipoplanta'];
      _valorAtributoController.text = muestra['valor_atributo'].toString();
      _observacionesController.text = muestra['observaciones'] ?? '';
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _editingMuestraId = null;
      _selectedConfiguracion = null;
      _selectedTemporada = null;
      _selectedCuartel = null;
      _selectedPlanta = null;
      _selectedTipoPlanta = null;
      _valorAtributoController.clear();
      _observacionesController.clear();
    });
  }

  Widget _buildFormularioMuestra() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingMuestraId != null ? 'Editar Muestra' : 'Nueva Muestra',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              
              // Configuración de Pauta
              DropdownButtonFormField<int>(
                value: _selectedConfiguracion,
                decoration: const InputDecoration(
                  labelText: 'Configuración de Pauta',
                  border: OutlineInputBorder(),
                ),
                items: _configuraciones.map((config) {
                  return DropdownMenuItem<int>(
                    value: config['id'],
                    child: Text(config['nombre']),
                  );
                }).toList(),
                onChanged: _editingMuestraId == null ? (value) {
                  setState(() {
                    _selectedConfiguracion = value;
                  });
                } : null,
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona una configuración de pauta';
                  }
                  return null;
                },
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
                onChanged: _editingMuestraId == null ? (value) {
                  setState(() {
                    _selectedTemporada = value;
                  });
                } : null,
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
                onChanged: _editingMuestraId == null ? (value) {
                  setState(() {
                    _selectedCuartel = value;
                  });
                } : null,
                validator: (value) {
                  if (value == null) {
                    return 'Selecciona un cuartel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Planta (opcional)
              TextFormField(
                initialValue: _selectedPlanta?.toString(),
                decoration: const InputDecoration(
                  labelText: 'ID Planta (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 5',
                ),
                keyboardType: TextInputType.number,
                onChanged: _editingMuestraId == null ? (value) {
                  _selectedPlanta = value.isEmpty ? null : int.tryParse(value);
                } : null,
              ),
              const SizedBox(height: 16),
              
              // Tipo de Planta (opcional)
              TextFormField(
                initialValue: _selectedTipoPlanta,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Planta (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 02',
                ),
                onChanged: _editingMuestraId == null ? (value) {
                  _selectedTipoPlanta = value.isEmpty ? null : value;
                } : null,
              ),
              const SizedBox(height: 16),
              
              // Valor del Atributo
              TextFormField(
                controller: _valorAtributoController,
                decoration: const InputDecoration(
                  labelText: 'Valor del Atributo',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 150.5',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El valor del atributo es requerido';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un valor numérico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Observaciones
              TextFormField(
                controller: _observacionesController,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Notas adicionales sobre la muestra',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Botones
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isCreating ? null : (_editingMuestraId != null 
                        ? () => _actualizarMuestra(_editingMuestraId!) 
                        : _crearMuestra),
                    icon: Icon(_editingMuestraId != null ? Icons.update : Icons.add),
                    label: Text(_editingMuestraId != null ? 'Actualizar' : 'Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_editingMuestraId != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _limpiarFormulario,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaMuestras() {
    if (_isLoadingMuestras) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMuestras != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar muestras',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMuestras!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarMuestras,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_muestras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay muestras registradas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera muestra usando el formulario de arriba',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _muestras.length,
      itemBuilder: (context, index) {
        final muestra = _muestras[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.science,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              '${muestra['nombre_labor']} - ${muestra['nombre_especie']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${muestra['nombre_atributo']}: ${muestra['valor_atributo']}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarMuestra(muestra),
                  tooltip: 'Editar muestra',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Muestra'),
                        content: Text('¿Estás seguro de que quieres eliminar esta muestra?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarMuestra(muestra['id']);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Eliminar muestra',
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Fecha', '${muestra['fecha']} ${muestra['hora_registro']}'),
                    _buildInfoRow('Temporada', muestra['nombre_temporada']),
                    _buildInfoRow('Cuartel', muestra['nombre_cuartel']),
                    if (muestra['nombre_planta'] != null)
                      _buildInfoRow('Planta', muestra['nombre_planta']),
                    if (muestra['nombre_tipo_planta'] != null)
                      _buildInfoRow('Tipo Planta', muestra['nombre_tipo_planta']),
                    if (muestra['observaciones'] != null && muestra['observaciones'].isNotEmpty)
                      _buildInfoRow('Observaciones', muestra['observaciones']),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Gestión de Muestras',
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
                  icon: Icon(Icons.add_circle),
                  text: 'Capturar Muestra',
                ),
                Tab(
                  icon: Icon(Icons.list),
                  text: 'Muestras Registradas',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Captura de Muestra
                Column(
                  children: [
                    _buildFormularioMuestra(),
                    const Spacer(),
                  ],
                ),
                // Tab de Lista de Muestras
                _buildListaMuestras(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
