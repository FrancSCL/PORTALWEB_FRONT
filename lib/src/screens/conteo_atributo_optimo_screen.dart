import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class ConteoAtributoOptimoScreen extends StatefulWidget {
  const ConteoAtributoOptimoScreen({super.key});

  @override
  State<ConteoAtributoOptimoScreen> createState() => _ConteoAtributoOptimoScreenState();
}

class _ConteoAtributoOptimoScreenState extends State<ConteoAtributoOptimoScreen> {
  List<Map<String, dynamic>> _atributosOptimos = [];
  List<Map<String, dynamic>> _atributos = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isEditing = false;
  int? _editingId;
  
  // Controllers para el formulario
  final _formKey = GlobalKey<FormState>();
  final _edadMinController = TextEditingController();
  final _edadMaxController = TextEditingController();
  final _optimoHaController = TextEditingController();
  final _minHaController = TextEditingController();
  final _maxHaController = TextEditingController();
  int? _selectedAtributoId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _edadMinController.dispose();
    _edadMaxController.dispose();
    _optimoHaController.dispose();
    _minHaController.dispose();
    _maxHaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar atributos óptimos y atributos en paralelo
      final futures = await Future.wait([
        _cargarAtributosOptimos(),
        _cargarAtributos(),
      ]);
      
      setState(() {
        _atributosOptimos = futures[0];
        _atributos = futures[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando datos: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _cargarAtributosOptimos() async {
    final token = await _obtenerToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/conteo/atributo-optimo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']['atributos'] ?? []);
      } else {
        throw Exception('Error en respuesta del servidor: ${data['message'] ?? 'Respuesta inválida'}');
      }
    } else {
      throw Exception('Error cargando atributos óptimos: ${response.statusCode}');
    }
  }

  Future<List<Map<String, dynamic>>> _cargarAtributos() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/atributos'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final atributos = List<Map<String, dynamic>>.from(data['data']['atributos'] ?? []);
        
        // Si no hay atributos, mostrar mensaje informativo
        if (atributos.isEmpty && data['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data['message']} - Contacte al administrador para configurar los atributos base'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        return atributos;
      } else {
        throw Exception('Error en respuesta del servidor: ${data['message'] ?? 'Respuesta inválida'}');
      }
    } else {
      throw Exception('Error cargando atributos: ${response.statusCode}');
    }
  }

  Future<String> _obtenerToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token ?? '';
  }

  void _mostrarFormulario([Map<String, dynamic>? atributoOptimo]) {
    if (atributoOptimo != null) {
      // Modo edición
      _isEditing = true;
      _editingId = atributoOptimo['id'];
      _selectedAtributoId = atributoOptimo['id_atributo'];
      _edadMinController.text = atributoOptimo['edad_min'].toString();
      _edadMaxController.text = atributoOptimo['edad_max'].toString();
      _optimoHaController.text = atributoOptimo['optimo_ha'].toString();
      _minHaController.text = atributoOptimo['min_ha'].toString();
      _maxHaController.text = atributoOptimo['max_ha'].toString();
    } else {
      // Modo creación
      _isCreating = true;
      _isEditing = false;
      _editingId = null;
      _selectedAtributoId = null;
      _edadMinController.clear();
      _edadMaxController.clear();
      _optimoHaController.clear();
      _minHaController.clear();
      _maxHaController.clear();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Editar Atributo Óptimo' : 'Crear Atributo Óptimo'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Selector de atributo
                DropdownButtonFormField<int>(
                  value: _selectedAtributoId,
                  decoration: const InputDecoration(
                    labelText: 'Atributo',
                    border: OutlineInputBorder(),
                  ),
                  items: _atributos.map((atributo) {
                    return DropdownMenuItem<int>(
                      value: atributo['id'] as int,
                      child: Text(atributo['nombre'] ?? 'Sin nombre'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAtributoId = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Seleccione un atributo';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Edad mínima y máxima
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _edadMinController,
                        decoration: const InputDecoration(
                          labelText: 'Edad Mínima',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese edad mínima';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _edadMaxController,
                        decoration: const InputDecoration(
                          labelText: 'Edad Máxima',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese edad máxima';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Óptimo por hectárea
                TextFormField(
                  controller: _optimoHaController,
                  decoration: const InputDecoration(
                    labelText: 'Óptimo por Hectárea',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingrese el valor óptimo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Rango mínimo y máximo
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minHaController,
                        decoration: const InputDecoration(
                          labelText: 'Mínimo por Hectárea',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese valor mínimo';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxHaController,
                        decoration: const InputDecoration(
                          labelText: 'Máximo por Hectárea',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingrese valor máximo';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _limpiarFormulario();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _guardarAtributoOptimo,
            child: Text(_isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    setState(() {
      _isCreating = false;
      _isEditing = false;
      _editingId = null;
      _selectedAtributoId = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _guardarAtributoOptimo() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final token = await _obtenerToken();
      final url = _isEditing 
        ? '${ApiConfig.baseUrl}/conteo/atributo-optimo/$_editingId'
        : '${ApiConfig.baseUrl}/conteo/atributo-optimo';
      
      final body = {
        'id_atributo': _selectedAtributoId,
        'edad_min': int.parse(_edadMinController.text),
        'edad_max': int.parse(_edadMaxController.text),
        'optimo_ha': int.parse(_optimoHaController.text),
        'min_ha': int.parse(_minHaController.text),
        'max_ha': int.parse(_maxHaController.text),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.of(context).pop();
        _limpiarFormulario();
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Atributo óptimo actualizado' : 'Atributo óptimo creado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _eliminarAtributoOptimo(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Está seguro de eliminar este atributo óptimo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _obtenerToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/conteo/atributo-optimo/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atributo óptimo eliminado'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error eliminando: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Atributos Óptimos',
      currentRoute: '/conteo-atributo-optimo',
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atributos Óptimos',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Configuración de parámetros óptimos por edad y atributo',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormulario(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Atributo Óptimo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: _atributosOptimos.isEmpty
                                     ? Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.tune_outlined, size: 64, color: Colors.grey[400]),
                           const SizedBox(height: 16),
                           Text(
                             _atributos.isEmpty 
                               ? 'No hay atributos base configurados'
                               : 'No hay atributos óptimos configurados',
                             style: TextStyle(
                               fontSize: 18,
                               color: Colors.grey[600],
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             _atributos.isEmpty
                               ? 'Contacte al administrador para configurar los atributos base del sistema'
                               : 'Cree el primer atributo óptimo para comenzar',
                             style: TextStyle(color: Colors.grey[500]),
                             textAlign: TextAlign.center,
                           ),
                           if (_atributos.isEmpty) ...[
                             const SizedBox(height: 16),
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: Colors.orange[50],
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.orange[200]!),
                               ),
                               child: Row(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                   const SizedBox(width: 8),
                                   Text(
                                     'Se requieren atributos base para crear configuraciones óptimas',
                                     style: TextStyle(
                                       fontSize: 12,
                                       color: Colors.orange[700],
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ],
                       ),
                     )
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Atributo')),
                          DataColumn(label: Text('Edad Mín')),
                          DataColumn(label: Text('Edad Máx')),
                          DataColumn(label: Text('Óptimo/ha')),
                          DataColumn(label: Text('Mín/ha')),
                          DataColumn(label: Text('Máx/ha')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _atributosOptimos.map((atributoOptimo) {
                          final atributo = _atributos.firstWhere(
                            (a) => a['id'] == atributoOptimo['id_atributo'],
                            orElse: () => {'nombre': 'N/A'},
                          );
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(atributo['nombre'] ?? 'N/A')),
                              DataCell(Text(atributoOptimo['edad_min'].toString())),
                              DataCell(Text(atributoOptimo['edad_max'].toString())),
                              DataCell(Text(atributoOptimo['optimo_ha'].toString())),
                              DataCell(Text(atributoOptimo['min_ha'].toString())),
                              DataCell(Text(atributoOptimo['max_ha'].toString())),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _mostrarFormulario(atributoOptimo),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarAtributoOptimo(atributoOptimo['id']),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
