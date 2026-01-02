import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class ConteoAtributoEspecieScreen extends StatefulWidget {
  const ConteoAtributoEspecieScreen({super.key});

  @override
  State<ConteoAtributoEspecieScreen> createState() => _ConteoAtributoEspecieScreenState();
}

class _ConteoAtributoEspecieScreenState extends State<ConteoAtributoEspecieScreen> {
  List<Map<String, dynamic>> _atributosEspecies = [];
  List<Map<String, dynamic>> _atributos = [];
  List<Map<String, dynamic>> _especies = [];
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isEditing = false;
  int? _editingId;
  
  // Controllers para el formulario
  final _formKey = GlobalKey<FormState>();
  int? _selectedAtributoId;
  int? _selectedEspecieId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar datos en paralelo
      final futures = await Future.wait([
        _cargarAtributosEspecies(),
        _cargarAtributos(),
        _cargarEspecies(),
      ]);
      
      setState(() {
        _atributosEspecies = futures[0];
        _atributos = futures[1];
        _especies = futures[2];
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

  Future<List<Map<String, dynamic>>> _cargarAtributosEspecies() async {
    final token = await _obtenerToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/conteo/atributo-especie'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']['atributos_especie'] ?? []);
      } else {
        throw Exception('Error en respuesta del servidor: ${data['message'] ?? 'Respuesta inválida'}');
      }
    } else {
      throw Exception('Error cargando atributos por especie: ${response.statusCode}');
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

  Future<List<Map<String, dynamic>>> _cargarEspecies() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/especies'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] != null) {
        final especies = List<Map<String, dynamic>>.from(data['data']['especies'] ?? []);
        
        // Si no hay especies, mostrar mensaje informativo
        if (especies.isEmpty && data['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${data['message']} - Contacte al administrador para configurar las especies base'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        
        return especies;
      } else {
        throw Exception('Error en respuesta del servidor: ${data['message'] ?? 'Respuesta inválida'}');
      }
    } else {
      throw Exception('Error cargando especies: ${response.statusCode}');
    }
  }

  Future<String> _obtenerToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.token ?? '';
  }

  void _mostrarFormulario([Map<String, dynamic>? atributoEspecie]) {
    if (atributoEspecie != null) {
      // Modo edición
      _isEditing = true;
      _editingId = atributoEspecie['id'];
      _selectedAtributoId = atributoEspecie['id_atributo'];
      _selectedEspecieId = atributoEspecie['id_especie'];
    } else {
      // Modo creación
      _isCreating = true;
      _isEditing = false;
      _editingId = null;
      _selectedAtributoId = null;
      _selectedEspecieId = null;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_isEditing ? 'Editar Atributo-Especie' : 'Crear Atributo-Especie'),
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
                
                // Selector de especie
                DropdownButtonFormField<int>(
                  value: _selectedEspecieId,
                  decoration: const InputDecoration(
                    labelText: 'Especie',
                    border: OutlineInputBorder(),
                  ),
                  items: _especies.map((especie) {
                    return DropdownMenuItem<int>(
                      value: especie['id'] as int,
                      child: Text(especie['nombre'] ?? 'Sin nombre'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedEspecieId = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Seleccione una especie';
                    return null;
                  },
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
            onPressed: _guardarAtributoEspecie,
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
      _selectedEspecieId = null;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _guardarAtributoEspecie() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final token = await _obtenerToken();
      final url = _isEditing 
        ? '${ApiConfig.baseUrl}/conteo/atributo-especie/$_editingId'
        : '${ApiConfig.baseUrl}/conteo/atributo-especie';
      
      final body = {
        'id_atributo': _selectedAtributoId,
        'id_especie': _selectedEspecieId,
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
            content: Text(_isEditing ? 'Relación actualizada' : 'Relación creada'),
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

  Future<void> _eliminarAtributoEspecie(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text('¿Está seguro de eliminar esta relación atributo-especie?'),
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
        Uri.parse('${ApiConfig.baseUrl}/conteo/atributo-especie/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relación eliminada'),
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
      title: 'Atributos por Especie',
      currentRoute: '/conteo-atributo-especie',
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
                      'Atributos por Especie',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asociación de atributos con especies de cultivo',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormulario(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Relación'),
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
                child: _atributosEspecies.isEmpty
                                     ? Center(
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                           const SizedBox(height: 16),
                           Text(
                             (_atributos.isEmpty || _especies.isEmpty)
                               ? 'No hay datos base configurados'
                               : 'No hay relaciones atributo-especie configuradas',
                             style: TextStyle(
                               fontSize: 18,
                               color: Colors.grey[600],
                               fontWeight: FontWeight.w500,
                             ),
                           ),
                           const SizedBox(height: 8),
                           Text(
                             (_atributos.isEmpty || _especies.isEmpty)
                               ? 'Contacte al administrador para configurar los datos base del sistema'
                               : 'Cree la primera relación para comenzar',
                             style: TextStyle(color: Colors.grey[500]),
                             textAlign: TextAlign.center,
                           ),
                           if (_atributos.isEmpty || _especies.isEmpty) ...[
                             const SizedBox(height: 16),
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(
                                 color: Colors.orange[50],
                                 borderRadius: BorderRadius.circular(8),
                                 border: Border.all(color: Colors.orange[200]!),
                               ),
                               child: Column(
                                 children: [
                                   Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                       const SizedBox(width: 8),
                                       Text(
                                         'Se requieren datos base para crear relaciones',
                                         style: TextStyle(
                                           fontSize: 12,
                                           color: Colors.orange[700],
                                           fontWeight: FontWeight.w500,
                                         ),
                                       ),
                                     ],
                                   ),
                                   if (_atributos.isEmpty) ...[
                                     const SizedBox(height: 8),
                                     Text(
                                       '• Atributos base no configurados',
                                       style: TextStyle(
                                         fontSize: 11,
                                         color: Colors.orange[600],
                                       ),
                                     ),
                                   ],
                                   if (_especies.isEmpty) ...[
                                     const SizedBox(height: 4),
                                     Text(
                                       '• Especies base no configuradas',
                                       style: TextStyle(
                                         fontSize: 11,
                                         color: Colors.orange[600],
                                       ),
                                     ),
                                   ],
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
                          DataColumn(label: Text('Especie')),
                          DataColumn(label: Text('Acciones')),
                        ],
                        rows: _atributosEspecies.map((atributoEspecie) {
                          final atributo = _atributos.firstWhere(
                            (a) => a['id'] == atributoEspecie['id_atributo'],
                            orElse: () => {'nombre': 'N/A'},
                          );
                          final especie = _especies.firstWhere(
                            (e) => e['id'] == atributoEspecie['id_especie'],
                            orElse: () => {'nombre': 'N/A'},
                          );
                          
                          return DataRow(
                            cells: [
                              DataCell(Text(atributo['nombre'] ?? 'N/A')),
                              DataCell(Text(especie['nombre'] ?? 'N/A')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _mostrarFormulario(atributoEspecie),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _eliminarAtributoEspecie(atributoEspecie['id']),
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
