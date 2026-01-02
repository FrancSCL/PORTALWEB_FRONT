import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/navigation_service.dart';

class ManejoParametrosConteoScreen extends StatefulWidget {
  const ManejoParametrosConteoScreen({super.key});

  @override
  State<ManejoParametrosConteoScreen> createState() => _ManejoParametrosConteoScreenState();
}

class _ManejoParametrosConteoScreenState extends State<ManejoParametrosConteoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Atributos de Cultivo
  List<Map<String, dynamic>> _atributosCultivo = [];
  bool _isLoadingAtributos = false;
  String? _errorAtributos;
  
  // Labores de Conteo
  List<Map<String, dynamic>> _laboresConteo = [];
  bool _isLoadingLabores = false;
  String? _errorLabores;
  
  // Formularios
  final _formKeyAtributo = GlobalKey<FormState>();
  final _formKeyLabor = GlobalKey<FormState>();
  final _nombreAtributoController = TextEditingController();
  final _nombreLaborController = TextEditingController();
  
  // Estados de edición
  int? _editingAtributoId;
  int? _editingLaborId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreAtributoController.dispose();
    _nombreLaborController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarAtributosCultivo(),
      _cargarLaboresConteo(),
    ]);
  }

  Future<void> _cargarAtributosCultivo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingAtributos = true;
      _errorAtributos = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributos-cultivo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _atributosCultivo = List<Map<String, dynamic>>.from(data['data']['atributos']);
          });
        } else {
          setState(() {
            _errorAtributos = data['message'] ?? 'Error al cargar atributos';
          });
        }
      } else {
        setState(() {
          _errorAtributos = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorAtributos = 'Error al cargar atributos: $e';
      });
    } finally {
      setState(() {
        _isLoadingAtributos = false;
      });
    }
  }

  Future<void> _cargarLaboresConteo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingLabores = true;
      _errorLabores = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labores-conteo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _laboresConteo = List<Map<String, dynamic>>.from(data['data']['labores']);
          });
        } else {
          setState(() {
            _errorLabores = data['message'] ?? 'Error al cargar labores';
          });
        }
      } else {
        setState(() {
          _errorLabores = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorLabores = 'Error al cargar labores: $e';
      });
    } finally {
      setState(() {
        _isLoadingLabores = false;
      });
    }
  }

  Future<void> _crearAtributoCultivo() async {
    if (!_formKeyAtributo.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributos-cultivo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': _nombreAtributoController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Atributo creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _nombreAtributoController.clear();
          _cargarAtributosCultivo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al crear atributo'),
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
          content: Text('Error al crear atributo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _crearLaborConteo() async {
    if (!_formKeyLabor.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labores-conteo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': _nombreLaborController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Labor creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _nombreLaborController.clear();
          _cargarLaboresConteo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al crear labor'),
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
          content: Text('Error al crear labor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarAtributoCultivo(int id) async {
    if (!_formKeyAtributo.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributos-cultivo/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': _nombreAtributoController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Atributo actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _nombreAtributoController.clear();
          _editingAtributoId = null;
          _cargarAtributosCultivo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al actualizar atributo'),
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
          content: Text('Error al actualizar atributo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _actualizarLaborConteo(int id) async {
    if (!_formKeyLabor.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labores-conteo/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'nombre': _nombreLaborController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Labor actualizada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _nombreLaborController.clear();
          _editingLaborId = null;
          _cargarLaboresConteo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al actualizar labor'),
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
          content: Text('Error al actualizar labor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarAtributoCultivo(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributos-cultivo/$id'),
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
              content: Text(data['message'] ?? 'Atributo eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarAtributosCultivo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al eliminar atributo'),
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
          content: Text('Error al eliminar atributo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarLaborConteo(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labores-conteo/$id'),
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
              content: Text(data['message'] ?? 'Labor eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarLaboresConteo();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al eliminar labor'),
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
          content: Text('Error al eliminar labor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editarAtributo(Map<String, dynamic> atributo) {
    setState(() {
      _editingAtributoId = atributo['id'];
      _nombreAtributoController.text = atributo['nombre'];
    });
  }

  void _editarLabor(Map<String, dynamic> labor) {
    setState(() {
      _editingLaborId = labor['id'];
      _nombreLaborController.text = labor['nombre'];
    });
  }

  void _cancelarEdicion() {
    setState(() {
      _editingAtributoId = null;
      _editingLaborId = null;
      _nombreAtributoController.clear();
      _nombreLaborController.clear();
    });
  }

  Widget _buildFormularioAtributo() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKeyAtributo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingAtributoId != null ? 'Editar Atributo de Cultivo' : 'Nuevo Atributo de Cultivo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreAtributoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Atributo',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: PESO, FRUTOS, CARGADORES',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del atributo es requerido';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _editingAtributoId != null ? () => _actualizarAtributoCultivo(_editingAtributoId!) : _crearAtributoCultivo,
                    icon: Icon(_editingAtributoId != null ? Icons.update : Icons.add),
                    label: Text(_editingAtributoId != null ? 'Actualizar' : 'Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_editingAtributoId != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _cancelarEdicion,
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

  Widget _buildFormularioLabor() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKeyLabor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingLaborId != null ? 'Editar Labor de Conteo' : 'Nueva Labor de Conteo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreLaborController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Labor',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: RALEO, PODA, CONTEO',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de la labor es requerido';
                  }
                  if (value.trim().length < 2) {
                    return 'El nombre debe tener al menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _editingLaborId != null ? () => _actualizarLaborConteo(_editingLaborId!) : _crearLaborConteo,
                    icon: Icon(_editingLaborId != null ? Icons.update : Icons.add),
                    label: Text(_editingLaborId != null ? 'Actualizar' : 'Crear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_editingLaborId != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _cancelarEdicion,
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

  Widget _buildListaAtributos() {
    if (_isLoadingAtributos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAtributos != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar atributos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorAtributos!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarAtributosCultivo,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_atributosCultivo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay atributos de cultivo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea el primer atributo usando el formulario de arriba',
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
      itemCount: _atributosCultivo.length,
      itemBuilder: (context, index) {
        final atributo = _atributosCultivo[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.category,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              atributo['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID: ${atributo['id']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarAtributo(atributo),
                  tooltip: 'Editar atributo',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Atributo'),
                        content: Text('¿Estás seguro de que quieres eliminar el atributo "${atributo['nombre']}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarAtributoCultivo(atributo['id']);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Eliminar atributo',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaLabores() {
    if (_isLoadingLabores) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLabores != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar labores',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorLabores!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarLaboresConteo,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_laboresConteo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay labores de conteo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera labor usando el formulario de arriba',
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
      itemCount: _laboresConteo.length,
      itemBuilder: (context, index) {
        final labor = _laboresConteo[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.work,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              labor['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('ID: ${labor['id']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editarLabor(labor),
                  tooltip: 'Editar labor',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Labor'),
                        content: Text('¿Estás seguro de que quieres eliminar la labor "${labor['nombre']}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarLaborConteo(labor['id']);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Eliminar labor',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manejo de Parámetros de Conteo'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: NavigationHelper.buildBackButton(context),
        actions: [
          NavigationHelper.buildHomeButton(context),
        ],
      ),
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
                  icon: Icon(Icons.category),
                  text: 'Atributos de Cultivo',
                ),
                Tab(
                  icon: Icon(Icons.work),
                  text: 'Labores de Conteo',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Atributos de Cultivo
                Column(
                  children: [
                    _buildFormularioAtributo(),
                    Expanded(child: _buildListaAtributos()),
                  ],
                ),
                // Tab de Labores de Conteo
                Column(
                  children: [
                    _buildFormularioLabor(),
                    Expanded(child: _buildListaLabores()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
