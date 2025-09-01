import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _usuarios = [];
  List<Map<String, dynamic>> _usuariosFiltrados = [];
  List<Map<String, dynamic>> _perfiles = [];
  List<Map<String, dynamic>> _sucursales = [];
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _permisos = [];
  
  // Variables de paginación
  int _currentPage = 1;
  int _usersPerPage = 20;
  int _totalPages = 1;
  
  // Variables de ordenamiento
  String _sortColumn = 'usuario';
  bool _sortAscending = true;
  
  bool _isLoading = false;
  bool _isCreatingUser = false;
  bool _isEditingUser = false;
  
  Map<String, dynamic>? _selectedUser;
  Map<String, dynamic>? _editingUser;
  
  // Controllers para el formulario
  final _usuarioController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _correoController = TextEditingController();
  final _claveController = TextEditingController();
  
  int? _selectedPerfil;
  int? _selectedSucursal;
  int? _selectedRol;
  List<int> _selectedApps = [];
  List<String> _selectedPermisos = [];
  
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _usuarioController.dispose();
    _nombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _correoController.dispose();
    _claveController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar todos los datos en paralelo
      await Future.wait([
        _cargarUsuarios(),
        _cargarPerfiles(),
        _cargarSucursales(),
        _cargarApps(),
        _cargarPermisos(),
      ]);
      
    } catch (e) {
      _mostrarError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/usuarios/'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> usuariosData = jsonDecode(response.body);
        setState(() {
          _usuarios = usuariosData.map((u) => Map<String, dynamic>.from(u)).toList();
          _usuariosFiltrados = List.from(_usuarios);
        });
      } else {
        throw Exception('Error cargando usuarios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando usuarios: $e');
      // Mantener datos de ejemplo en caso de error
      _usuarios = [
        {
          'id': '1',
          'usuario': 'admin',
          'nombre': 'Administrador',
          'apellido_paterno': 'Sistema',
          'apellido_materno': '',
          'correo': 'admin@sistema.com',
          'id_perfil': 1,
          'id_rol': 1,
          'id_sucursalactiva': 1,
          'id_estado': 1,
          'perfil_nombre': 'Administrador',
          'sucursal_activa_nombre': 'Principal',
          'rol_nombre': 'Admin'
        }
      ];
    }
  }

  Future<void> _cargarPerfiles() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/usuarios/perfiles'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> perfilesData = jsonDecode(response.body);
        setState(() {
          _perfiles = perfilesData.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      } else {
        throw Exception('Error cargando perfiles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando perfiles: $e');
      // Mantener datos de ejemplo
      _perfiles = [
        {'id': 1, 'nombre': 'Usuario Básico'},
        {'id': 2, 'nombre': 'Supervisor'},
        {'id': 3, 'nombre': 'Administrador'}
      ];
    }
  }

  Future<void> _cargarSucursales() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/sucursales'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> sucursalesData = responseData['data']['sucursales'];
          setState(() {
            _sucursales = sucursalesData.map((s) => Map<String, dynamic>.from(s)).toList();
          });
        }
      } else {
        throw Exception('Error cargando sucursales: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando sucursales: $e');
      // Mantener datos de ejemplo
      _sucursales = [
        {'id': 103, 'nombre': 'SANTA VICTORIA'},
        {'id': 104, 'nombre': 'SAN MANUEL'},
        {'id': 105, 'nombre': 'CULLIPEUMO'}
      ];
    }
  }

  Future<void> _cargarApps() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/usuarios/aplicaciones'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> appsData = jsonDecode(response.body);
        setState(() {
          _apps = appsData.map((a) => Map<String, dynamic>.from(a)).toList();
        });
      } else {
        throw Exception('Error cargando aplicaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando aplicaciones: $e');
      // Mantener datos de ejemplo
      _apps = [
        {'id': 1, 'nombre': 'Portal Web', 'descripcion': 'Sistema principal de gestión agrícola'},
        {'id': 2, 'nombre': 'App Móvil', 'descripcion': 'Aplicación móvil para campo'}
      ];
    }
  }

  Future<void> _cargarPermisos() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/usuarios/permisos'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> permisosData = jsonDecode(response.body);
        setState(() {
          _permisos = permisosData.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      } else {
        throw Exception('Error cargando permisos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando permisos: $e');
      // Mantener datos de ejemplo
      _permisos = [
        {'id': 'perm-001', 'nombre': 'ver_cuarteles', 'id_app': 1, 'app_nombre': 'Portal Web'},
        {'id': 'perm-002', 'nombre': 'crear_cuarteles', 'id_app': 1, 'app_nombre': 'Portal Web'},
        {'id': 'perm-003', 'nombre': 'ver_plantas', 'id_app': 1, 'app_nombre': 'Portal Web'}
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Administración de Usuarios',
      currentRoute: '/admin-usuarios',
      onRefresh: _cargarDatos,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildHeader(),
              _buildSearchAndActions(),
              Expanded(child: _buildUsuariosTable()),
            ],
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Usuarios del Sistema',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lightGreen.withOpacity(0.3)),
                ),
                child: Text(
                  '${_usuariosFiltrados.length} de ${_usuarios.length} usuarios',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Crear, editar y administrar usuarios del sistema',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Barra de búsqueda
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                _filtrarUsuarios(value);
              },
            ),
          ),
          const SizedBox(width: 16),
          // Botón crear usuario
          ElevatedButton.icon(
            onPressed: _mostrarFormularioUsuario,
            icon: const Icon(Icons.person_add),
            label: const Text('Crear Usuario'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // Botón crear perfil
          ElevatedButton.icon(
            onPressed: _mostrarFormularioPerfil,
            icon: const Icon(Icons.badge),
            label: const Text('Crear Perfil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          // Botón crear aplicación
          ElevatedButton.icon(
            onPressed: _mostrarFormularioApp,
            icon: const Icon(Icons.apps),
            label: const Text('Crear App'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuariosTable() {
    if (_usuariosFiltrados.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _usuarios.isEmpty ? 'No hay usuarios en el sistema' : 'No se encontraron usuarios',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              if (_usuarios.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros términos de búsqueda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex: _getSortColumnIndex(),
          sortAscending: _sortAscending,
          columns: [
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Usuario'),
                  if (_sortColumn == 'usuario') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('usuario'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nombre Completo'),
                  if (_sortColumn == 'nombre_completo') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('nombre_completo'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Correo'),
                  if (_sortColumn == 'correo') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('correo'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Perfil'),
                  if (_sortColumn == 'perfil_nombre') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('perfil_nombre'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Rol'),
                  if (_sortColumn == 'rol_nombre') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('rol_nombre'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sucursal'),
                  if (_sortColumn == 'sucursal_activa_nombre') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('sucursal_activa_nombre'),
            ),
            DataColumn(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Estado'),
                  if (_sortColumn == 'id_estado') ...[
                    const SizedBox(width: 4),
                    Icon(
                      _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
              onSort: (columnIndex, ascending) => _sortUsers('id_estado'),
            ),
            const DataColumn(label: Text('Acciones')),
          ],
                     rows: _getPaginatedUsers().map((usuario) {
            return DataRow(
              cells: [
                DataCell(Text(usuario['usuario'] ?? '')),
                DataCell(Text(
                  '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''} ${usuario['apellido_materno'] ?? ''}'
                )),
                DataCell(Text(usuario['correo'] ?? '')),
                DataCell(Text(usuario['perfil_nombre'] ?? '')),
                DataCell(Text(usuario['rol_nombre'] ?? '')),
                                 DataCell(Text(usuario['sucursal_activa_nombre'] ?? '')),
                 DataCell(
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: (usuario['id_estado'] == 1) 
                         ? AppTheme.successColor 
                         : AppTheme.errorColor,
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       (usuario['id_estado'] == 1) ? 'Activo' : 'Inactivo',
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 12,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ),
                 ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _editarUsuario(usuario),
                        icon: const Icon(Icons.edit, color: AppTheme.infoColor),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => _cambiarEstadoUsuario(usuario),
                        icon: Icon(
                          (usuario['id_estado'] == 1) 
                            ? Icons.block 
                            : Icons.check_circle,
                          color: (usuario['id_estado'] == 1) 
                            ? AppTheme.warningColor 
                            : AppTheme.successColor,
                        ),
                        tooltip: (usuario['id_estado'] == 1) 
                          ? 'Desactivar' 
                          : 'Activar',
                      ),
                                             IconButton(
                         onPressed: () => _asignarPermisos(usuario),
                         icon: const Icon(Icons.security, color: AppTheme.primaryColor),
                         tooltip: 'Permisos',
                       ),
                       IconButton(
                         onPressed: () => _eliminarUsuario(usuario),
                         icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                         tooltip: 'Eliminar',
                       ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Información de página
          Text(
            'Página $_currentPage de $_totalPages - '
            'Mostrando ${_getPaginatedUsers().length} de ${_usuariosFiltrados.length} usuarios',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          // Selector de usuarios por página y controles de ordenamiento
          Row(
            children: [
              Text(
                'Usuarios por página: ',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _usersPerPage,
                items: [10, 20, 50, 100].map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _usersPerPage = value;
                      _currentPage = 1;
                      _totalPages = (_usuariosFiltrados.length / _usersPerPage).ceil();
                    });
                  }
                },
              ),
              const SizedBox(width: 24),
              // Botón para limpiar ordenamiento
              if (_sortColumn != 'usuario' || !_sortAscending)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _sortColumn = 'usuario';
                      _sortAscending = true;
                      _currentPage = 1;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpiar ordenamiento'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                ),
            ],
          ),
          // Controles de navegación
          Row(
            children: [
              // Botón primera página
              IconButton(
                onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Primera página',
              ),
              // Botón página anterior
              IconButton(
                onPressed: _currentPage > 1 ? _previousPage : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
              ),
              // Números de página
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: _buildPageNumbers(),
                ),
              ),
              // Botón página siguiente
              IconButton(
                onPressed: _currentPage < _totalPages ? _nextPage : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Página siguiente',
              ),
              // Botón última página
              IconButton(
                onPressed: _currentPage < _totalPages ? () => _goToPage(_totalPages) : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Última página',
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pageNumbers = [];
    final int maxVisiblePages = 5;
    
    if (_totalPages <= maxVisiblePages) {
      // Mostrar todas las páginas si hay pocas
      for (int i = 1; i <= _totalPages; i++) {
        pageNumbers.add(_buildPageNumber(i));
      }
    } else {
      // Mostrar páginas con elipsis
      if (_currentPage <= 3) {
        // Páginas iniciales
        for (int i = 1; i <= 4; i++) {
          pageNumbers.add(_buildPageNumber(i));
        }
        pageNumbers.add(const Text('...'));
        pageNumbers.add(_buildPageNumber(_totalPages));
      } else if (_currentPage >= _totalPages - 2) {
        // Páginas finales
        pageNumbers.add(_buildPageNumber(1));
        pageNumbers.add(const Text('...'));
        for (int i = _totalPages - 3; i <= _totalPages; i++) {
          pageNumbers.add(_buildPageNumber(i));
        }
        pageNumbers.add(const Text('...'));
        pageNumbers.add(_buildPageNumber(_totalPages));
      } else {
        // Páginas del medio
        pageNumbers.add(_buildPageNumber(1));
        pageNumbers.add(const Text('...'));
        for (int i = _currentPage - 1; i <= _currentPage + 1; i++) {
          pageNumbers.add(_buildPageNumber(i));
        }
        pageNumbers.add(const Text('...'));
        pageNumbers.add(_buildPageNumber(_totalPages));
      }
    }
    
    return pageNumbers;
  }

  Widget _buildPageNumber(int page) {
    final isCurrentPage = page == _currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isCurrentPage ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrentPage ? AppTheme.primaryColor : Colors.grey[300]!,
            ),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              color: isCurrentPage ? Colors.white : Colors.grey[700],
              fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioUsuario() {
    _limpiarFormulario();
    setState(() {
      _isCreatingUser = true;
      _isEditingUser = false;
    });
    _mostrarDialogoUsuario();
  }

  void _editarUsuario(Map<String, dynamic> usuario) {
    _editingUser = usuario;
    _usuarioController.text = usuario['usuario'] ?? '';
    _nombreController.text = usuario['nombre'] ?? '';
    _apellidoPaternoController.text = usuario['apellido_paterno'] ?? '';
    _apellidoMaternoController.text = usuario['apellido_materno'] ?? '';
    _correoController.text = usuario['correo'] ?? '';
    _selectedPerfil = usuario['id_perfil'];
    _selectedSucursal = usuario['id_sucursalactiva'];
    _selectedRol = usuario['id_rol'];
    
    setState(() {
      _isCreatingUser = false;
      _isEditingUser = true;
    });
    _mostrarDialogoUsuario();
  }

  void _mostrarDialogoUsuario() {
         showDialog(
       context: context,
       barrierDismissible: false,
       builder: (context) => AlertDialog(
        title: Text(_isCreatingUser ? 'Crear Usuario' : 'Editar Usuario'),
        content: SizedBox(
          width: 500,
          child: _buildFormularioUsuario(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _limpiarFormulario();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _guardarUsuario,
            child: Text(_isCreatingUser ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioUsuario() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Primera fila
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _usuarioController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Segunda fila
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _apellidoPaternoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido Paterno *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _apellidoMaternoController,
                    decoration: const InputDecoration(
                      labelText: 'Apellido Materno',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tercera fila
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _correoController,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo requerido';
                      }
                      if (!value.contains('@')) {
                        return 'Correo inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _claveController,
                                         decoration: InputDecoration(
                       labelText: _isCreatingUser ? 'Contraseña *' : 'Nueva Contraseña',
                       border: const OutlineInputBorder(),
                     ),
                    obscureText: true,
                    validator: (value) {
                      if (_isCreatingUser && (value == null || value.isEmpty)) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Cuarta fila
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedPerfil,
                    decoration: const InputDecoration(
                      labelText: 'Perfil *',
                      border: OutlineInputBorder(),
                    ),
                                         items: _perfiles.map((perfil) {
                       return DropdownMenuItem<int>(
                         value: perfil['id'] as int,
                         child: Text(perfil['nombre']),
                       );
                     }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPerfil = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedSucursal,
                    decoration: const InputDecoration(
                      labelText: 'Sucursal *',
                      border: OutlineInputBorder(),
                    ),
                                         items: _sucursales.map((sucursal) {
                       return DropdownMenuItem<int>(
                         value: sucursal['id'] as int,
                         child: Text(sucursal['nombre']),
                       );
                     }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSucursal = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Quinta fila
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedRol,
                    decoration: const InputDecoration(
                      labelText: 'Rol *',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: 1, child: Text('Administrador')),
                      const DropdownMenuItem(value: 2, child: Text('Usuario')),
                      const DropdownMenuItem(value: 3, child: Text('Supervisor')),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedRol = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Campo requerido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(), // Espacio vacío para mantener alineación
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Aplicaciones disponibles
            const Text(
              'Aplicaciones Disponibles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _apps.map((app) {
                final isSelected = _selectedApps.contains(app['id']);
                return FilterChip(
                  label: Text(app['nombre']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedApps.add(app['id']);
                      } else {
                        _selectedApps.remove(app['id']);
                      }
                    });
                  },
                  selectedColor: AppTheme.lightGreen,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isLoading = true);
      
      if (_isCreatingUser) {
        await _crearUsuario();
        _mostrarExito('Usuario creado exitosamente');
      } else {
        await _actualizarUsuario();
        _mostrarExito('Usuario actualizado exitosamente');
      }
      
      Navigator.pop(context);
      _limpiarFormulario();
      await _cargarDatos();
      
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _crearUsuario() async {
    final datosUsuario = {
      'usuario': _usuarioController.text.trim(),
      'nombre': _nombreController.text.trim(),
      'apellido_paterno': _apellidoPaternoController.text.trim(),
      'apellido_materno': _apellidoMaternoController.text.trim(),
      'clave': _claveController.text.trim(),
      'correo': _correoController.text.trim(),
      'id_estado': 1,
      'id_rol': _selectedRol,
      'id_perfil': _selectedPerfil,
      'id_sucursalactiva': _selectedSucursal,
    };

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/usuarios/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode(datosUsuario),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error creando usuario');
    }

    // Asignar aplicaciones si se seleccionaron
    if (_selectedApps.isNotEmpty) {
      final usuarioCreado = jsonDecode(response.body);
      await _asignarAplicaciones(usuarioCreado['id'], _selectedApps);
    }
  }

  Future<void> _actualizarUsuario() async {
    if (_editingUser == null) return;

    final datosActualizacion = {
      'nombre': _nombreController.text.trim(),
      'apellido_paterno': _apellidoPaternoController.text.trim(),
      'apellido_materno': _apellidoMaternoController.text.trim(),
      'correo': _correoController.text.trim(),
      'id_perfil': _selectedPerfil,
      'id_rol': _selectedRol,
      'id_sucursalactiva': _selectedSucursal,
    };

    // Agregar contraseña solo si se proporcionó una nueva
    if (_claveController.text.trim().isNotEmpty) {
      datosActualizacion['clave'] = _claveController.text.trim();
    }

    final response = await http.put(
      Uri.parse('http://localhost:5000/api/usuarios/${_editingUser!['id']}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode(datosActualizacion),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error actualizando usuario');
    }
  }

  Future<void> _asignarAplicaciones(String usuarioId, List<int> appsIds) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/usuarios/$usuarioId/aplicaciones'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
        body: jsonEncode({'apps_ids': appsIds}),
      );

      if (response.statusCode != 200) {
        print('Error asignando aplicaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error asignando aplicaciones: $e');
    }
  }

  Future<void> _cambiarEstadoUsuarioAPI(String usuarioId, int nuevoEstado) async {
    final response = await http.patch(
      Uri.parse('http://localhost:5000/api/usuarios/$usuarioId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'id_estado': nuevoEstado}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error cambiando estado del usuario');
    }
  }

  void _cambiarEstadoUsuario(Map<String, dynamic> usuario) {
    final nuevoEstado = usuario['id_estado'] == 1 ? 0 : 1;
    final accion = nuevoEstado == 1 ? 'activar' : 'desactivar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Acción'),
        content: Text('¿Estás seguro de que quieres $accion al usuario ${usuario['usuario']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
                      ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await _cambiarEstadoUsuarioAPI(usuario['id'], nuevoEstado);
                  _mostrarExito('Estado del usuario cambiado exitosamente');
                  await _cargarDatos();
                } catch (e) {
                  _mostrarError('Error: $e');
                }
              },
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado == 1 
                ? AppTheme.successColor 
                : AppTheme.warningColor,
            ),
            child: Text(accion == 'activar' ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );
  }

  void _asignarPermisos(Map<String, dynamic> usuario) {
    _mostrarDialogoPermisos(usuario);
  }

  void _mostrarDialogoPermisos(Map<String, dynamic> usuario) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Cargando permisos del usuario...'),
          ],
        ),
      ),
    );
    
    // Cargar permisos existentes
    final permisosExistentes = await _cargarPermisosUsuario(usuario['id']);
    
    // Cerrar diálogo de carga
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Estado local del diálogo
          List<String> permisosAsignados = List.from(permisosExistentes);
          List<String> permisosDisponibles = _permisos
              .where((p) => !permisosAsignados.contains(p['id']))
              .map((p) => p['id'].toString())
              .toList();
          
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.security, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text('Gestionar Permisos - ${usuario['usuario']}'),
              ],
            ),
            content: SizedBox(
              width: 700,
              height: 450,
              child: Column(
                children: [

                  
                  // Contenido principal - Dos columnas
                  Expanded(
                    child: Row(
                      children: [
                        // Columna izquierda - Permisos Asignados
                        Expanded(
                          child: _buildPermisosColumn(
                            'Permisos Asignados',
                            permisosAsignados,
                            _permisos.where((p) => permisosAsignados.contains(p['id'])).toList(),
                            Colors.green,
                            (permisoId) {
                              setDialogState(() {
                                permisosAsignados.remove(permisoId);
                                permisosDisponibles.add(permisoId);
                              });
                            },
                            'Quitar',
                            Icons.remove_circle,
                          ),
                        ),
                        
                        // Flechas de navegación
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: permisosDisponibles.isNotEmpty ? () {
                                  setDialogState(() {
                                    if (permisosDisponibles.isNotEmpty) {
                                      final permisoId = permisosDisponibles.first;
                                      permisosDisponibles.remove(permisoId);
                                      permisosAsignados.add(permisoId);
                                    }
                                  });
                                } : null,
                                icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                                tooltip: 'Agregar permiso',
                              ),
                              IconButton(
                                onPressed: permisosAsignados.isNotEmpty ? () {
                                  setDialogState(() {
                                    if (permisosAsignados.isNotEmpty) {
                                      final permisoId = permisosAsignados.first;
                                      permisosAsignados.remove(permisoId);
                                      permisosDisponibles.add(permisoId);
                                    }
                                  });
                                } : null,
                                icon: const Icon(Icons.arrow_back, color: Colors.red),
                                tooltip: 'Quitar permiso',
                              ),
                            ],
                          ),
                        ),
                        
                        // Columna derecha - Permisos Disponibles
                        Expanded(
                          child: _buildPermisosColumn(
                            'Permisos Disponibles',
                            permisosDisponibles,
                            _permisos.where((p) => permisosDisponibles.contains(p['id'])).toList(),
                            Colors.blue,
                            (permisoId) {
                              setDialogState(() {
                                permisosDisponibles.remove(permisoId);
                                permisosAsignados.add(permisoId);
                              });
                            },
                            'Agregar',
                            Icons.add_circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _asignarPermisosAPI(usuario['id'], permisosAsignados);
                    _mostrarExito('Permisos asignados correctamente');
                    await _cargarDatos();
                  } catch (e) {
                    _mostrarError('Error asignando permisos: $e');
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildPermisosColumn(
    String title,
    List<String> permisosIds,
    List<Map<String, dynamic>> permisosData,
    Color color,
    Function(String) onAction,
    String actionText,
    IconData actionIcon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header de la columna
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    permisosIds.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de permisos
          Expanded(
            child: permisosData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: color.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay permisos',
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: permisosData.length,
                    itemBuilder: (context, index) {
                      final permiso = permisosData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    permiso['nombre'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'App: ${permiso['app_nombre']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => onAction(permiso['id'].toString()),
                              icon: Icon(actionIcon, color: color),
                              tooltip: actionText,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarPermisosAPI(String usuarioId, List<String> permisosIds) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/usuarios/$usuarioId/permisos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'permisos_ids': permisosIds}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error asignando permisos');
    }
  }

  Future<List<String>> _cargarPermisosUsuario(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/usuarios/$usuarioId'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('Datos del usuario cargados: $userData'); // Debug
        
        // Intentar diferentes estructuras de datos
        List permisosAsignados = [];
        
        if (userData['permisos_asignados'] != null) {
          permisosAsignados = userData['permisos_asignados'];
        } else if (userData['permisos'] != null) {
          permisosAsignados = userData['permisos'];
        } else if (userData['data'] != null && userData['data']['permisos_asignados'] != null) {
          permisosAsignados = userData['data']['permisos_asignados'];
        }
        
        print('Permisos encontrados: $permisosAsignados'); // Debug
        
        if (permisosAsignados.isNotEmpty) {
          return permisosAsignados.map<String>((permiso) {
            // Manejar diferentes formatos de ID
            if (permiso is Map) {
              return permiso['id']?.toString() ?? '';
            } else if (permiso is String) {
              return permiso;
            }
            return '';
          }).where((id) => id.isNotEmpty).toList();
        }
      }
      
      print('No se encontraron permisos para el usuario $usuarioId');
      return [];
    } catch (e) {
      print('Error cargando permisos del usuario: $e');
      return [];
    }
  }

  void _filtrarUsuarios(String query) {
    if (query.isEmpty) {
      setState(() {
        _usuariosFiltrados = List.from(_usuarios);
        _currentPage = 1;
        _totalPages = (_usuarios.length / _usersPerPage).ceil();
      });
    } else {
      setState(() {
        _usuariosFiltrados = _usuarios.where((usuario) {
          final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''} ${usuario['apellido_materno'] ?? ''}'.toLowerCase();
          final usuarioName = (usuario['usuario'] ?? '').toLowerCase();
          final correo = (usuario['correo'] ?? '').toLowerCase();
          final queryLower = query.toLowerCase();
          
          return nombre.contains(queryLower) || 
                 usuarioName.contains(queryLower) || 
                 correo.contains(queryLower);
        }).toList();
        _currentPage = 1;
        _totalPages = (_usuariosFiltrados.length / _usersPerPage).ceil();
      });
    }
  }

  List<Map<String, dynamic>> _getPaginatedUsers() {
    final sortedUsers = _getSortedUsers();
    final startIndex = (_currentPage - 1) * _usersPerPage;
    final endIndex = startIndex + _usersPerPage;
    return sortedUsers.sublist(
      startIndex, 
      endIndex > sortedUsers.length ? sortedUsers.length : endIndex
    );
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _goToPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _goToPage(_currentPage - 1);
    }
  }

  void _sortUsers(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 1; // Volver a la primera página al ordenar
    });
  }

  List<Map<String, dynamic>> _getSortedUsers() {
    final sortedUsers = List<Map<String, dynamic>>.from(_usuariosFiltrados);
    
    sortedUsers.sort((a, b) {
      dynamic aValue = a[_sortColumn] ?? '';
      dynamic bValue = b[_sortColumn] ?? '';
      
      // Manejar casos especiales
      if (_sortColumn == 'nombre_completo') {
        aValue = '${a['nombre'] ?? ''} ${a['apellido_paterno'] ?? ''} ${a['apellido_materno'] ?? ''}';
        bValue = '${b['nombre'] ?? ''} ${b['apellido_paterno'] ?? ''} ${b['apellido_materno'] ?? ''}';
      }
      
      if (aValue is String && bValue is String) {
        return _sortAscending 
          ? aValue.toLowerCase().compareTo(bValue.toLowerCase())
          : bValue.toLowerCase().compareTo(aValue.toLowerCase());
      } else if (aValue is num && bValue is num) {
        return _sortAscending 
          ? aValue.compareTo(bValue)
          : bValue.compareTo(aValue);
      }
      
      return 0;
    });
    
    return sortedUsers;
  }

  int? _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'usuario':
        return 0;
      case 'nombre_completo':
        return 1;
      case 'correo':
        return 2;
      case 'perfil_nombre':
        return 3;
      case 'rol_nombre':
        return 4;
      case 'sucursal_activa_nombre':
        return 5;
      case 'id_estado':
        return 6;
      default:
        return null;
    }
  }

  void _eliminarUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar al usuario "${usuario['usuario']}"?\n\n'
          'Esta acción desactivará el usuario (soft delete).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _eliminarUsuarioAPI(usuario['id']);
                _mostrarExito('Usuario eliminado exitosamente');
                await _cargarDatos();
              } catch (e) {
                _mostrarError('Error eliminando usuario: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuarioAPI(String usuarioId) async {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/api/usuarios/$usuarioId'),
      headers: {
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error eliminando usuario');
    }
  }

  void _mostrarFormularioPerfil() {
    final _nombreController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Perfil'),
        content: TextField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Perfil',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nombreController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _crearPerfil(_nombreController.text.trim());
                  _mostrarExito('Perfil creado exitosamente');
                  await _cargarDatos();
                } catch (e) {
                  _mostrarError('Error creando perfil: $e');
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearPerfil(String nombre) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/usuarios/perfiles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'nombre': nombre}),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error creando perfil');
    }
  }

  void _mostrarFormularioApp() {
    final _nombreController = TextEditingController();
    final _descripcionController = TextEditingController();
    final _urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Aplicación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la App',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nombreController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                try {
                  await _crearApp(
                    _nombreController.text.trim(),
                    _descripcionController.text.trim(),
                    _urlController.text.trim(),
                  );
                  _mostrarExito('Aplicación creada exitosamente');
                  await _cargarDatos();
                } catch (e) {
                  _mostrarError('Error creando aplicación: $e');
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _crearApp(String nombre, String descripcion, String url) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/usuarios/aplicaciones'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({
        'nombre': nombre,
        'descripcion': descripcion,
        'URL': url.isNotEmpty ? url : null,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error creando aplicación');
    }
  }

  void _limpiarFormulario() {
    _usuarioController.clear();
    _nombreController.clear();
    _apellidoPaternoController.clear();
    _apellidoMaternoController.clear();
    _correoController.clear();
    _claveController.clear();
    _selectedPerfil = null;
    _selectedSucursal = null;
    _selectedRol = null;
    _selectedApps.clear();
    _selectedPermisos.clear();
    _editingUser = null;
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppTheme.infoColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
