import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:data_table_2/data_table_2.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../config/api_config.dart';
import '../services/http_interceptor.dart';

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
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _sucursales = [];
  List<Map<String, dynamic>> _apps = [];
  List<Map<String, dynamic>> _permisos = [];
  
  int _currentPage = 1;
  int _usersPerPage = 20;
  int _totalPages = 1;
  
  String _sortColumn = 'usuario';
  bool _sortAscending = true;
  
  bool _isLoading = false;
  bool _isCreatingUser = false;
  bool _isEditingUser = false;
  
  Map<String, dynamic>? _selectedUser;
  Map<String, dynamic>? _editingUser;

  int? _filtroPerfil;
  int? _filtroRol;
  int? _filtroSucursal;
  int? _filtroEstado;
  bool _showFilters = false;
  
  Set<String> _selectedUserIds = {};
  bool _isMultiSelectMode = false;
  
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
      await Future.wait([
        _cargarUsuarios(),
        _cargarPerfiles(),
        _cargarSucursales(),
        _cargarApps(),
        _cargarPermisos(),
      ]);
    } catch (e) {
      _mostrarError('Error cargando datos', detalle: e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarUsuarios() async {
    try {
      final response = await HttpInterceptor.get(
        context,
        Uri.parse('${ApiConfig.usuariosUrl}/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> usuariosData = jsonDecode(response.body);
        setState(() {
          _usuarios = usuariosData.map((u) => Map<String, dynamic>.from(u)).toList();
          _usuariosFiltrados = List.from(_usuarios);
          _totalPages = (_usuariosFiltrados.length / _usersPerPage).ceil();
          final rolesMap = <int, String>{};
          for (var usuario in _usuarios) {
            if (usuario['id_rol'] != null && usuario['rol_nombre'] != null) {
              rolesMap[usuario['id_rol'] as int] = usuario['rol_nombre'] as String;
            }
          }
          _roles = rolesMap.entries.map((e) => {'id': e.key, 'nombre': e.value}).toList();
        });
      }
    } catch (e) {
      _usuarios = [];
    }
  }

  Future<void> _cargarPerfiles() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/perfiles'),
        headers: {'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> perfilesData = jsonDecode(response.body);
        setState(() {
          _perfiles = perfilesData.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      }
    } catch (e) {
      _perfiles = [];
    }
  }

  Future<void> _cargarSucursales() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.sucursalesUrl}'),
        headers: {'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final List<dynamic> sucursalesData = responseData['data']['sucursales'];
          setState(() {
            _sucursales = sucursalesData.map((s) => Map<String, dynamic>.from(s)).toList();
          });
        }
      }
    } catch (e) {
      _sucursales = [];
    }
  }

  Future<void> _cargarApps() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/aplicaciones'),
        headers: {'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> appsData = jsonDecode(response.body);
        setState(() {
          _apps = appsData.map((a) => Map<String, dynamic>.from(a)).toList();
        });
      }
    } catch (e) {
      _apps = [];
    }
  }

  Future<void> _cargarPermisos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/permisos'),
        headers: {'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> permisosData = jsonDecode(response.body);
        setState(() {
          _permisos = permisosData.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      }
    } catch (e) {
      _permisos = [];
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                if (_isMultiSelectMode) _buildBulkActionsBar(),
                _buildToolbar(),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTable(),
                  ),
                ),
                _buildPagination(),
              ],
          ),
    );
  }

  Widget _buildHeader() {
    final total = _usuarios.length;
    final filtrados = _usuariosFiltrados.length;
        
        return Container(
      padding: const EdgeInsets.fromLTRB(0, 24, 32, 24),
      alignment: Alignment.centerLeft,
      child: Row(
                  children: [
                    Expanded(
                      child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                  'Usuarios',
                                    style: TextStyle(
                    fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[900],
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                const SizedBox(height: 8),
                                  Text(
                  filtrados == total
                      ? '$total usuarios en total'
                      : '$filtrados de $total usuarios',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
          ),
          _buildHeaderActionButton(
            icon: Icons.person_add_outlined,
            label: 'Nuevo Usuario',
            onPressed: () => _abrirFormularioUsuario(),
            primary: true,
          ),
          const SizedBox(width: 12),
          _buildHeaderActionButton(
            icon: Icons.group_add_outlined,
            label: 'Nuevo Perfil',
                            onPressed: _mostrarFormularioPerfil,
                          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? AppTheme.primaryColor : Colors.white,
        foregroundColor: primary ? Colors.white : Colors.grey[700],
        elevation: primary ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: primary ? Colors.transparent : Colors.grey[300]!,
            width: 1,
                            ),
                          ),
                        ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 32, 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
                                child: Row(
                                  children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                              Text(
            '${_selectedUserIds.length} seleccionado${_selectedUserIds.length > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedUserIds.isEmpty ? null : _accionMasivaActivar,
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Activar'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _selectedUserIds.isEmpty ? null : _accionMasivaDesactivar,
            icon: const Icon(Icons.block_outlined, size: 18),
            label: const Text('Desactivar'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _cancelarSeleccion,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Cancelar'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
                    ),
                  ],
                ),
    );
  }

  Widget _buildToolbar() {
    final hasFilters = _filtroPerfil != null || _filtroRol != null || _filtroSucursal != null || _filtroEstado != null;
        
        return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 32, 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
      child: Row(
                  children: [
                    Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                  hintText: 'Buscar usuarios...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            _filtrarUsuarios('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                      onChanged: (value) {
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (_searchController.text == value) {
                      _filtrarUsuarios(value);
                    }
                  });
                },
              ),
            ),
                    ),
                    const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => setState(() => _showFilters = !_showFilters),
            icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined, size: 18),
            label: Text(_showFilters ? 'Ocultar' : 'Filtros'),
            style: OutlinedButton.styleFrom(
              foregroundColor: hasFilters ? AppTheme.primaryColor : Colors.grey[700],
              side: BorderSide(
                color: hasFilters ? AppTheme.primaryColor : Colors.grey[300]!,
                width: hasFilters ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_showFilters) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
          _buildFiltersPanel(),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildDataTable(),
            ),
          ),
        ],
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: _buildDataTable(),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
                      children: [
          _buildFilterDropdown(
            label: 'Perfil',
                          value: _filtroPerfil,
            items: _perfiles,
                          onChanged: (value) {
                            setState(() => _filtroPerfil = value);
                            _filtrarUsuarios(_searchController.text);
                          },
                        ),
          _buildFilterDropdown(
            label: 'Rol',
            value: _filtroRol,
            items: _roles,
            onChanged: (value) {
              setState(() => _filtroRol = value);
              _filtrarUsuarios(_searchController.text);
            },
          ),
          _buildFilterDropdown(
            label: 'Sucursal',
            value: _filtroSucursal,
            items: _sucursales,
                          onChanged: (value) {
                            setState(() => _filtroSucursal = value);
                            _filtrarUsuarios(_searchController.text);
                          },
                        ),
          _buildFilterDropdown(
            label: 'Estado',
                          value: _filtroEstado,
            items: [
              {'id': 1, 'nombre': 'Activo'},
              {'id': 0, 'nombre': 'Inactivo'},
                          ],
                          onChanged: (value) {
                            setState(() => _filtroEstado = value);
                            _filtrarUsuarios(_searchController.text);
                          },
                        ),
          if (_filtroPerfil != null || _filtroRol != null || _filtroSucursal != null || _filtroEstado != null)
            TextButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Limpiar filtros'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> items,
    required Function(int?) onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<int?>(
          value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text('Todos')),
          ...items.map((item) => DropdownMenuItem<int?>(
                value: item['id'] as int,
                child: Text(item['nombre'] ?? ''),
              )),
        ],
          onChanged: onChanged,
      ),
    );
  }

  Widget _buildDataTable() {
    final paginatedUsers = _getPaginatedUsers();
    
    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
      child: DataTable2(
        columnSpacing: 24,
        horizontalMargin: 0,
        checkboxHorizontalMargin: 0,
        minWidth: 800,
        headingRowHeight: 56,
        dataRowHeight: 64,
                headingRowDecoration: BoxDecoration(
          color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
              return AppTheme.primaryColor.withOpacity(0.08);
            }
            if (states.contains(MaterialState.hovered)) {
              return Colors.grey[50];
            }
            return Colors.transparent;
          },
        ),
        columns: [
          DataColumn2(
            label: const Text('Usuario', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            fixedWidth: 120,
            onSort: (columnIndex, ascending) => _sortUsers('usuario'),
          ),
          DataColumn2(
            label: const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            fixedWidth: 200,
            onSort: (columnIndex, ascending) => _sortUsers('nombre_completo'),
          ),
          DataColumn2(
            label: const Text('Correo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      fixedWidth: 200,
                    ),
          DataColumn2(
            label: const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            fixedWidth: 120,
          ),
          DataColumn2(
            label: const Text('Rol', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            fixedWidth: 120,
          ),
          DataColumn2(
            label: const Text('Sucursal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          fixedWidth: 150,
                        ),
          DataColumn2(
            label: const Text('Estado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            fixedWidth: 100,
          ),
                        const DataColumn2(
            label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            fixedWidth: 140,
                        ),
                      ],
            rows: paginatedUsers.map((usuario) {
          final isSelected = _selectedUserIds.contains(usuario['id'].toString());
                return DataRow2(
            selected: isSelected,
            onSelectChanged: (selected) {
              setState(() {
                final userId = usuario['id'].toString();
                if (selected == true) {
                  _selectedUserIds.add(userId);
              } else {
                  _selectedUserIds.remove(userId);
                }
                _isMultiSelectMode = _selectedUserIds.isNotEmpty;
              });
            },
                  cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    usuario['usuario'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ),
              DataCell(Text(
                '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''} ${usuario['apellido_materno'] ?? ''}'.trim(),
                style: const TextStyle(fontSize: 13),
              )),
              DataCell(Text(usuario['correo'] ?? '', style: const TextStyle(fontSize: 13))),
              DataCell(Text(usuario['perfil_nombre'] ?? '', style: const TextStyle(fontSize: 13))),
              DataCell(Text(usuario['rol_nombre'] ?? '', style: const TextStyle(fontSize: 13))),
              DataCell(Text(usuario['sucursal_activa_nombre'] ?? '', style: const TextStyle(fontSize: 13))),
              DataCell(_buildEstadoBadge(usuario['id_estado'] == 1)),
              DataCell(_buildActionButtons(usuario)),
            ],
          );
            }).toList(),
      ),
    );
  }

  Widget _buildEstadoBadge(bool activo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? AppTheme.successColor.withOpacity(0.1) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: activo ? AppTheme.successColor : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            activo ? 'Activo' : 'Inactivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: activo ? AppTheme.successColor : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> usuario) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          color: AppTheme.primaryColor,
          tooltip: 'Editar',
          onPressed: () => _editarUsuario(usuario),
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: Icons.security_outlined,
          color: AppTheme.infoColor,
          tooltip: 'Permisos',
          onPressed: () => _asignarPermisos(usuario),
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          icon: usuario['id_estado'] == 1 ? Icons.block_outlined : Icons.check_circle_outline,
          color: usuario['id_estado'] == 1 ? AppTheme.warningColor : AppTheme.successColor,
          tooltip: usuario['id_estado'] == 1 ? 'Desactivar' : 'Activar',
          onPressed: () => _cambiarEstadoUsuario(usuario),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 16, 32, 16),
          decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
                  children: [
                    Text(
            'Mostrando ${_getPaginatedUsers().length} de ${_usuariosFiltrados.length}',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const Spacer(),
                    Row(
                      children: [
                        IconButton(
                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                icon: const Icon(Icons.chevron_left, size: 20),
                color: Colors.grey[700],
              ),
              Text(
                            '$_currentPage / $_totalPages',
                style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        IconButton(
                onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
                icon: const Icon(Icons.chevron_right, size: 20),
                color: Colors.grey[700],
                        ),
                      ],
                    ),
                  ],
      ),
    );
  }

  void _filtrarUsuarios(String query) {
                                  setState(() {
      final queryLower = query.toLowerCase();
      _usuariosFiltrados = _usuarios.where((usuario) {
        final nombre = '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''} ${usuario['apellido_materno'] ?? ''}'.toLowerCase();
        final usuarioName = (usuario['usuario'] ?? '').toLowerCase();
        final correo = (usuario['correo'] ?? '').toLowerCase();
        final matchesText = query.isEmpty || nombre.contains(queryLower) || usuarioName.contains(queryLower) || correo.contains(queryLower);
        final matchesPerfil = _filtroPerfil == null || usuario['id_perfil'] == _filtroPerfil;
        final matchesRol = _filtroRol == null || usuario['id_rol'] == _filtroRol;
        final matchesSucursal = _filtroSucursal == null || usuario['id_sucursalactiva'] == _filtroSucursal;
        final matchesEstado = _filtroEstado == null || usuario['id_estado'] == _filtroEstado;
        return matchesText && matchesPerfil && matchesRol && matchesSucursal && matchesEstado;
      }).toList();
                                    _currentPage = 1;
                                    _totalPages = (_usuariosFiltrados.length / _usersPerPage).ceil();
                                  });
                                }

  List<Map<String, dynamic>> _getPaginatedUsers() {
    final sortedUsers = _getSortedUsers();
    final startIndex = (_currentPage - 1) * _usersPerPage;
    final endIndex = startIndex + _usersPerPage;
    return sortedUsers.sublist(
      startIndex,
      endIndex > sortedUsers.length ? sortedUsers.length : endIndex,
    );
  }

  List<Map<String, dynamic>> _getSortedUsers() {
    final users = List<Map<String, dynamic>>.from(_usuariosFiltrados);
    users.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'usuario':
          comparison = (a['usuario'] ?? '').toString().compareTo((b['usuario'] ?? '').toString());
          break;
        case 'nombre_completo':
          final nombreA = '${a['nombre'] ?? ''} ${a['apellido_paterno'] ?? ''} ${a['apellido_materno'] ?? ''}';
          final nombreB = '${b['nombre'] ?? ''} ${b['apellido_paterno'] ?? ''} ${b['apellido_materno'] ?? ''}';
          comparison = nombreA.compareTo(nombreB);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    return users;
  }

  void _sortUsers(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroPerfil = null;
      _filtroRol = null;
      _filtroSucursal = null;
      _filtroEstado = null;
      _searchController.clear();
    });
    _filtrarUsuarios('');
  }

  void _cancelarSeleccion() {
    setState(() {
      _selectedUserIds.clear();
      _isMultiSelectMode = false;
    });
  }

  Future<void> _accionMasivaActivar() async {
    if (_selectedUserIds.isEmpty) return;
    try {
      int successCount = 0;
      for (final userId in _selectedUserIds) {
        try {
          await _cambiarEstadoUsuarioAPI(userId, 1);
          successCount++;
        } catch (e) {
          print('Error activando usuario $userId: $e');
        }
      }
      _mostrarExito('$successCount usuario${successCount > 1 ? 's' : ''} activado${successCount > 1 ? 's' : ''}');
      await _cargarDatos();
      _cancelarSeleccion();
    } catch (e) {
      _mostrarError('Error activando usuarios', detalle: e.toString());
    }
  }

  Future<void> _accionMasivaDesactivar() async {
    if (_selectedUserIds.isEmpty) return;
    try {
      int successCount = 0;
      for (final userId in _selectedUserIds) {
        try {
          await _cambiarEstadoUsuarioAPI(userId, 0);
          successCount++;
        } catch (e) {
          print('Error desactivando usuario $userId: $e');
        }
      }
      _mostrarExito('$successCount usuario${successCount > 1 ? 's' : ''} desactivado${successCount > 1 ? 's' : ''}');
      await _cargarDatos();
      _cancelarSeleccion();
    } catch (e) {
      _mostrarError('Error desactivando usuarios', detalle: e.toString());
    }
  }

  Future<void> _cambiarEstadoUsuarioAPI(dynamic usuarioId, int nuevoEstado) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'id_estado': nuevoEstado}),
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error cambiando estado');
    }
  }

  void _cambiarEstadoUsuario(Map<String, dynamic> usuario) async {
    final nuevoEstado = usuario['id_estado'] == 1 ? 0 : 1;
    final accion = nuevoEstado == 1 ? 'activar' : 'desactivar';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Estás seguro de que quieres $accion al usuario ${usuario['usuario']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado == 1 ? AppTheme.successColor : AppTheme.warningColor,
            ),
            child: Text(accion == 'activar' ? 'Activar' : 'Desactivar'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _cambiarEstadoUsuarioAPI(usuario['id'].toString(), nuevoEstado);
        _mostrarExito('Estado del usuario cambiado exitosamente');
        await _cargarDatos();
      } catch (e) {
        _mostrarError('Error: $e');
      }
    }
  }

  void _abrirFormularioUsuario() {
    _isCreatingUser = true;
    _editingUser = null;
    _limpiarFormulario();
    _mostrarFormularioUsuario();
  }

  void _editarUsuario(Map<String, dynamic> usuario) {
    _isCreatingUser = false;
    _editingUser = usuario;
    _usuarioController.text = usuario['usuario'] ?? '';
    _nombreController.text = usuario['nombre'] ?? '';
    _apellidoPaternoController.text = usuario['apellido_paterno'] ?? '';
    _apellidoMaternoController.text = usuario['apellido_materno'] ?? '';
    _correoController.text = usuario['correo'] ?? '';
    _selectedPerfil = usuario['id_perfil'];
    _selectedRol = usuario['id_rol'];
    _selectedSucursal = usuario['id_sucursalactiva'];
    _cargarAppsUsuario(usuario['id'].toString());
    _mostrarFormularioUsuario();
  }

  void _mostrarFormularioUsuario() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32),
            child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Text(
                      _isCreatingUser ? 'Nuevo Usuario' : 'Editar Usuario',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                    controller: _usuarioController,
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      enabled: _isCreatingUser,
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                Expanded(
                  child: TextFormField(
                    controller: _nombreController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _apellidoPaternoController,
                            decoration: InputDecoration(
                              labelText: 'Apellido Paterno',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                    controller: _apellidoMaternoController,
                      decoration: InputDecoration(
                      labelText: 'Apellido Materno',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                    ),
            ),
            const SizedBox(height: 16),
                    TextFormField(
                    controller: _correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    if (_isCreatingUser)
                      TextFormField(
                    controller: _claveController,
                    decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[50],
                    ),
                    obscureText: true,
                        validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                    if (!_isCreatingUser) ...[
                      TextFormField(
                        controller: _claveController,
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña (opcional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        obscureText: true,
                      ),
                    ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                          child: DropdownButtonFormField<int?>(
                    value: _selectedPerfil,
                            decoration: InputDecoration(
                              labelText: 'Perfil',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Seleccionar')),
                              ..._perfiles.map((p) => DropdownMenuItem<int?>(
                                    value: p['id'] as int,
                                    child: Text(p['nombre'] ?? ''),
                                  )),
                            ],
                            onChanged: (value) => setState(() => _selectedPerfil = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _selectedRol,
                            decoration: InputDecoration(
                              labelText: 'Rol',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: [
                              const DropdownMenuItem<int?>(value: null, child: Text('Seleccionar')),
                              ..._roles.map((r) => DropdownMenuItem<int?>(
                                    value: r['id'] as int,
                                    child: Text(r['nombre'] ?? ''),
                                  )),
                            ],
                            onChanged: (value) => setState(() => _selectedRol = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      value: _selectedSucursal,
                      decoration: InputDecoration(
                        labelText: 'Sucursal',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('Seleccionar')),
                        ..._sucursales.map((s) => DropdownMenuItem<int?>(
                              value: s['id'] as int,
                              child: Text(s['nombre'] ?? ''),
                            )),
                      ],
                      onChanged: (value) => setState(() => _selectedSucursal = value),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _limpiarFormulario();
                          },
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _guardarUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Guardar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cargarAppsUsuario(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId'),
        headers: {'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> apps;
        if (data is Map && data['apps_permitidas'] != null) {
          apps = data['apps_permitidas'];
        } else if (data is Map && data['data'] != null && data['data']['apps_permitidas'] != null) {
          apps = data['data']['apps_permitidas'];
        } else {
          apps = [];
        }
        setState(() {
          _selectedApps = apps.map<int>((a) {
            if (a is Map && a['id'] != null) return (a['id'] as num).toInt();
            if (a is num) return a.toInt();
            return -1;
          }).where((id) => id != -1).toList();
        });
      }
    } catch (e) {}
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      setState(() => _isLoading = true);
      String usuarioId;
      if (_isCreatingUser) {
        usuarioId = await _crearUsuarioAPI();
        _mostrarExito('Usuario creado exitosamente');
      } else {
        await _actualizarUsuario();
        usuarioId = _editingUser!['id'].toString();
        _mostrarExito('Usuario actualizado exitosamente');
      }
      await _asignarAplicaciones(usuarioId, _selectedApps);
      Navigator.pop(context);
      _limpiarFormulario();
      await _cargarDatos();
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _crearUsuarioAPI() async {
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
    final response = await HttpInterceptor.post(
      context,
      Uri.parse('${ApiConfig.usuariosUrl}/'),
      body: datosUsuario,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error creando usuario');
    }
    try {
      final usuarioCreado = jsonDecode(response.body);
      if (usuarioCreado is Map && usuarioCreado['id'] != null) {
        return usuarioCreado['id'].toString();
      }
    } catch (_) {}
    final listado = await http.get(
      Uri.parse('${ApiConfig.usuariosUrl}/'),
      headers: {'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}'},
    );
    if (listado.statusCode == 200) {
      final arr = jsonDecode(listado.body);
      if (arr is List) {
        final found = arr.cast<Map>().firstWhere(
          (u) => (u['usuario'] ?? '').toString() == _usuarioController.text.trim(),
          orElse: () => {},
        );
        if (found.isNotEmpty && found['id'] != null) {
          return found['id'].toString();
        }
      }
    }
    throw Exception('No se pudo obtener ID del usuario creado');
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
    if (_claveController.text.trim().isNotEmpty) {
      datosActualizacion['clave'] = _claveController.text.trim();
    }
    final response = await HttpInterceptor.put(
      context,
      Uri.parse('${ApiConfig.usuariosUrl}/${_editingUser!['id']}'),
      body: datosActualizacion,
    );
    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error actualizando usuario');
    }
  }

  Future<void> _asignarAplicaciones(String usuarioId, List<int> appsIds) async {
    try {
      await HttpInterceptor.post(
        context,
        Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId/aplicaciones'),
        body: {'apps_ids': appsIds},
      );
    } catch (e) {
      print('Error asignando aplicaciones: $e');
    }
  }

  void _asignarPermisos(Map<String, dynamic> usuario) {
    _mostrarDialogoPermisos(usuario);
  }

  void _mostrarDialogoPermisos(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permisos - ${usuario['usuario']}'),
        content: const Text('Funcionalidad de permisos en desarrollo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioPerfil() {
    final _nombreController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Perfil'),
        content: TextField(
          controller: _nombreController,
          decoration: InputDecoration(
            labelText: 'Nombre del perfil',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              if (_nombreController.text.trim().isEmpty) return;
                Navigator.pop(context);
                try {
                  await _crearPerfil(_nombreController.text.trim());
                  _mostrarExito('Perfil creado exitosamente');
                  await _cargarDatos();
                } catch (e) {
                  _mostrarError('Error creando perfil: $e');
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
      Uri.parse('${ApiConfig.usuariosUrl}/perfiles'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'nombre': nombre}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error creando perfil');
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
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarError(String mensaje, {String? detalle}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(mensaje)),
              ],
            ),
            if (detalle != null) ...[
              const SizedBox(height: 4),
              Text(detalle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
            ],
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
