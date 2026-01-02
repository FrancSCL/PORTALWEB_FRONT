import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/navigation_service.dart';

class ConfiguracionAsociacionesScreen extends StatefulWidget {
  const ConfiguracionAsociacionesScreen({super.key});

  @override
  State<ConfiguracionAsociacionesScreen> createState() => _ConfiguracionAsociacionesScreenState();
}

class _ConfiguracionAsociacionesScreenState extends State<ConfiguracionAsociacionesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Labor-Especie
  List<Map<String, dynamic>> _laborEspecies = [];
  List<Map<String, dynamic>> _labores = [];
  List<Map<String, dynamic>> _especies = [];
  bool _isLoadingLaborEspecie = false;
  String? _errorLaborEspecie;
  
  // Atributo-Especie
  List<Map<String, dynamic>> _atributosEspecie = [];
  List<Map<String, dynamic>> _atributos = [];
  List<Map<String, dynamic>> _especiesAtributo = [];
  bool _isLoadingAtributoEspecie = false;
  String? _errorAtributoEspecie;
  
  // Formularios
  final _formKeyLaborEspecie = GlobalKey<FormState>();
  final _formKeyAtributoEspecie = GlobalKey<FormState>();
  
  // Estados de formulario Labor-Especie
  int? _selectedLabor;
  int? _selectedEspecie;
  int _selectedEstado = 1;
  
  // Estados de formulario Atributo-Especie
  int? _selectedAtributo;
  int? _selectedEspecieAtributo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    await Future.wait([
      _cargarLaborEspecies(),
      _cargarAtributosEspecie(),
      _cargarLabores(),
      _cargarEspecies(),
      _cargarAtributos(),
    ]);
  }

  Future<void> _cargarLaborEspecies() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingLaborEspecie = true;
      _errorLaborEspecie = null;
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
            _errorLaborEspecie = data['message'] ?? 'Error al cargar labor-especie';
          });
        }
      } else {
        setState(() {
          _errorLaborEspecie = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorLaborEspecie = 'Error al cargar labor-especie: $e';
      });
    } finally {
      setState(() {
        _isLoadingLaborEspecie = false;
      });
    }
  }

  Future<void> _cargarAtributosEspecie() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoadingAtributoEspecie = true;
      _errorAtributoEspecie = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributo-especie'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _atributosEspecie = List<Map<String, dynamic>>.from(data['data']['atributos_especie']);
          });
        } else {
          setState(() {
            _errorAtributoEspecie = data['message'] ?? 'Error al cargar atributo-especie';
          });
        }
      } else {
        setState(() {
          _errorAtributoEspecie = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorAtributoEspecie = 'Error al cargar atributo-especie: $e';
      });
    } finally {
      setState(() {
        _isLoadingAtributoEspecie = false;
      });
    }
  }

  Future<void> _cargarLabores() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

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
            _labores = List<Map<String, dynamic>>.from(data['data']['labores']);
          });
        }
      }
    } catch (e) {
      print('Error cargando labores: $e');
    }
  }

  Future<void> _cargarEspecies() async {
    // TODO: Implementar endpoint de especies
    // Por ahora usamos datos mock
    setState(() {
      _especies = [
        {'id': 1, 'nombre': 'NECTARIN'},
        {'id': 2, 'nombre': 'MANZANA'},
        {'id': 3, 'nombre': 'PERA'},
      ];
      _especiesAtributo = List.from(_especies);
    });
  }

  Future<void> _cargarAtributos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

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
            _atributos = List<Map<String, dynamic>>.from(data['data']['atributos']);
          });
        }
      }
    } catch (e) {
      print('Error cargando atributos: $e');
    }
  }

  Future<void> _crearLaborEspecie() async {
    if (!_formKeyLaborEspecie.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labor-especie'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_labor': _selectedLabor,
          'id_especie': _selectedEspecie,
          'id_estado': _selectedEstado,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Asociación labor-especie creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _limpiarFormularioLaborEspecie();
          _cargarLaborEspecies();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al crear asociación'),
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
          content: Text('Error al crear asociación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _crearAtributoEspecie() async {
    if (!_formKeyAtributoEspecie.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributo-especie'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_atributo': _selectedAtributo,
          'id_especie': _selectedEspecieAtributo,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Asociación atributo-especie creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _limpiarFormularioAtributoEspecie();
          _cargarAtributosEspecie();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al crear asociación'),
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
          content: Text('Error al crear asociación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarLaborEspecie(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/labor-especie/$id'),
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
              content: Text(data['message'] ?? 'Asociación eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarLaborEspecies();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al eliminar asociación'),
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
          content: Text('Error al eliminar asociación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _eliminarAtributoEspecie(int id) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/atributo-especie/$id'),
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
              content: Text(data['message'] ?? 'Asociación eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarAtributosEspecie();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al eliminar asociación'),
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
          content: Text('Error al eliminar asociación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiarFormularioLaborEspecie() {
    setState(() {
      _selectedLabor = null;
      _selectedEspecie = null;
      _selectedEstado = 1;
    });
  }

  void _limpiarFormularioAtributoEspecie() {
    setState(() {
      _selectedAtributo = null;
      _selectedEspecieAtributo = null;
    });
  }

  Widget _buildFormularioLaborEspecie() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKeyLaborEspecie,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Asociación Labor-Especie',
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
                      value: _selectedLabor,
                      decoration: const InputDecoration(
                        labelText: 'Labor',
                        border: OutlineInputBorder(),
                      ),
                      items: _labores.map((labor) {
                        return DropdownMenuItem<int>(
                          value: labor['id'],
                          child: Text(labor['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLabor = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una labor';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedEspecie,
                      decoration: const InputDecoration(
                        labelText: 'Especie',
                        border: OutlineInputBorder(),
                      ),
                      items: _especies.map((especie) {
                        return DropdownMenuItem<int>(
                          value: especie['id'],
                          child: Text(especie['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEspecie = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una especie';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                value: _selectedEstado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('Activo'),
                  ),
                  DropdownMenuItem<int>(
                    value: 0,
                    child: Text('Inactivo'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedEstado = value ?? 1;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _crearLaborEspecie,
                icon: const Icon(Icons.add),
                label: const Text('Crear Asociación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioAtributoEspecie() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKeyAtributoEspecie,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Asociación Atributo-Especie',
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
                      value: _selectedAtributo,
                      decoration: const InputDecoration(
                        labelText: 'Atributo',
                        border: OutlineInputBorder(),
                      ),
                      items: _atributos.map((atributo) {
                        return DropdownMenuItem<int>(
                          value: atributo['id'],
                          child: Text(atributo['nombre']),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedEspecieAtributo,
                      decoration: const InputDecoration(
                        labelText: 'Especie',
                        border: OutlineInputBorder(),
                      ),
                      items: _especiesAtributo.map((especie) {
                        return DropdownMenuItem<int>(
                          value: especie['id'],
                          child: Text(especie['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEspecieAtributo = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Selecciona una especie';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _crearAtributoEspecie,
                icon: const Icon(Icons.add),
                label: const Text('Crear Asociación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaLaborEspecie() {
    if (_isLoadingLaborEspecie) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorLaborEspecie != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar asociaciones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorLaborEspecie!,
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

    if (_laborEspecies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay asociaciones labor-especie',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera asociación usando el formulario de arriba',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupar por especie
    Map<String, List<Map<String, dynamic>>> agrupadoPorEspecie = {};
    for (var item in _laborEspecies) {
      String especie = item['nombre_especie'];
      if (!agrupadoPorEspecie.containsKey(especie)) {
        agrupadoPorEspecie[especie] = [];
      }
      agrupadoPorEspecie[especie]!.add(item);
    }

    // Ordenar especies alfabéticamente
    var especiesOrdenadas = agrupadoPorEspecie.keys.toList()..sort();

    return ListView.builder(
      itemCount: especiesOrdenadas.length,
      itemBuilder: (context, index) {
        String especie = especiesOrdenadas[index];
        List<Map<String, dynamic>> labores = agrupadoPorEspecie[especie]!;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                especie.substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            title: Text(
              especie,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${labores.length} labor${labores.length != 1 ? 'es' : ''} asociada${labores.length != 1 ? 's' : ''}'),
            children: labores.map((item) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: item['id_estado'] == 1 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  child: Icon(
                    Icons.work,
                    color: item['id_estado'] == 1 ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['nombre_labor'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  item['id_estado'] == 1 ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    color: item['id_estado'] == 1 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Asociación'),
                        content: Text('¿Estás seguro de que quieres eliminar la asociación "${item['nombre_labor']} - ${item['nombre_especie']}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarLaborEspecie(item['id']);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Eliminar asociación',
                ),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildListaAtributoEspecie() {
    if (_isLoadingAtributoEspecie) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorAtributoEspecie != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar asociaciones',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorAtributoEspecie!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarAtributosEspecie,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_atributosEspecie.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay asociaciones atributo-especie',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea la primera asociación usando el formulario de arriba',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupar por especie
    Map<String, List<Map<String, dynamic>>> agrupadoPorEspecie = {};
    for (var item in _atributosEspecie) {
      String especie = item['nombre_especie'];
      if (!agrupadoPorEspecie.containsKey(especie)) {
        agrupadoPorEspecie[especie] = [];
      }
      agrupadoPorEspecie[especie]!.add(item);
    }

    // Ordenar especies alfabéticamente
    var especiesOrdenadas = agrupadoPorEspecie.keys.toList()..sort();

    return ListView.builder(
      itemCount: especiesOrdenadas.length,
      itemBuilder: (context, index) {
        String especie = especiesOrdenadas[index];
        List<Map<String, dynamic>> atributos = agrupadoPorEspecie[especie]!;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                especie.substring(0, 1),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            title: Text(
              especie,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${atributos.length} atributo${atributos.length != 1 ? 's' : ''} asociado${atributos.length != 1 ? 's' : ''}'),
            children: atributos.map((item) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.category,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  item['nombre_atributo'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Caja equivalente: ${item['caja_equivalente']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Asociación'),
                        content: Text('¿Estás seguro de que quieres eliminar la asociación "${item['nombre_atributo']} - ${item['nombre_especie']}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarAtributoEspecie(item['id']);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Eliminar asociación',
                ),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Asociaciones'),
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
                  icon: Icon(Icons.work),
                  text: 'Labor-Especie',
                ),
                Tab(
                  icon: Icon(Icons.category),
                  text: 'Atributo-Especie',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab de Labor-Especie
                Column(
                  children: [
                    _buildFormularioLaborEspecie(),
                    Expanded(child: _buildListaLaborEspecie()),
                  ],
                ),
                // Tab de Atributo-Especie
                Column(
                  children: [
                    _buildFormularioAtributoEspecie(),
                    Expanded(child: _buildListaAtributoEspecie()),
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
