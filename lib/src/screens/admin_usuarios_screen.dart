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

  // Filtros de tabla
  int? _filtroPerfil;
  int? _filtroSucursal;
  int? _filtroEstado;
  
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
        });
      } else {
        throw Exception('Error cargando usuarios: ${response.statusCode}');
      }
    } catch (e) {
      print('Error cargando usuarios: $e');
      _usuarios = [];
    }
  }

  Future<void> _cargarPerfiles() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/perfiles'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> perfilesData = jsonDecode(response.body);
        setState(() {
          _perfiles = perfilesData.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      }
    } catch (e) {
      print('Error cargando perfiles: $e');
      _perfiles = [];
    }
  }

  Future<void> _cargarSucursales() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.sucursalesUrl}'),
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
      }
    } catch (e) {
      print('Error cargando sucursales: $e');
      _sucursales = [];
    }
  }

  Future<void> _cargarApps() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/aplicaciones'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> appsData = jsonDecode(response.body);
        setState(() {
          _apps = appsData.map((a) => Map<String, dynamic>.from(a)).toList();
        });
      }
    } catch (e) {
      print('Error cargando aplicaciones: $e');
      _apps = [];
    }
  }

  Future<void> _cargarPermisos() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/permisos'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> permisosData = jsonDecode(response.body);
        setState(() {
          _permisos = permisosData.map((p) => Map<String, dynamic>.from(p)).toList();
        });
      }
    } catch (e) {
      print('Error cargando permisos: $e');
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
        : Container(
            color: Colors.grey[50],
            child: Column(
              children: [
                _buildModernHeader(),
                _buildFiltersSection(),
                Expanded(child: _buildUsuariosTable()),
                _buildPaginationControls(),
              ],
            ),
          ),
    );
  }

  Widget _buildModernHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;
        
        return Container(
          padding: EdgeInsets.fromLTRB(
            isWideScreen ? 24 : 16,
            20,
            isWideScreen ? 24 : 16,
            16,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: isWideScreen
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.people,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestión de Usuarios del Sistema',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[900],
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Administra usuarios, perfiles y permisos del sistema',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Botones de acción
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMediumScreen) ...[
                          _buildSecondaryButton(
                            icon: Icons.badge_outlined,
                            label: 'Crear Perfil',
                            color: AppTheme.infoColor,
                            onPressed: _mostrarFormularioPerfil,
                          ),
                          const SizedBox(width: 8),
                          _buildSecondaryButton(
                            icon: Icons.vpn_key_outlined,
                            label: 'Crear Permiso',
                            color: AppTheme.successColor,
                            onPressed: _mostrarFormularioPermiso,
                          ),
                          const SizedBox(width: 8),
                          _buildSecondaryButton(
                            icon: Icons.apps_outlined,
                            label: 'Crear App',
                            color: AppTheme.warningColor,
                            onPressed: _mostrarFormularioApp,
                          ),
                          const SizedBox(width: 12),
                        ],
                        ElevatedButton.icon(
                          onPressed: _mostrarFormularioUsuario,
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text('Crear Usuario'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMediumScreen ? 20 : 16,
                              vertical: 14,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (!isMediumScreen) ...[
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              switch (value) {
                                case 'perfil':
                                  _mostrarFormularioPerfil();
                                  break;
                                case 'permiso':
                                  _mostrarFormularioPermiso();
                                  break;
                                case 'app':
                                  _mostrarFormularioApp();
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'perfil',
                                child: Row(
                                  children: [
                                    Icon(Icons.badge_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Crear Perfil'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'permiso',
                                child: Row(
                                  children: [
                                    Icon(Icons.vpn_key_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Crear Permiso'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'app',
                                child: Row(
                                  children: [
                                    Icon(Icons.apps_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text('Crear App'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.people,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gestión de Usuarios',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Administra usuarios del sistema',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _mostrarFormularioUsuario,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Crear Usuario'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.more_vert, size: 18),
                            label: const Text('Más'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'perfil':
                                _mostrarFormularioPerfil();
                                break;
                              case 'permiso':
                                _mostrarFormularioPermiso();
                                break;
                              case 'app':
                                _mostrarFormularioApp();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'perfil',
                              child: Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Crear Perfil'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'permiso',
                              child: Row(
                                children: [
                                  Icon(Icons.vpn_key_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Crear Permiso'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'app',
                              child: Row(
                                children: [
                                  Icon(Icons.apps_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Crear App'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1000;
        final isMediumScreen = constraints.maxWidth > 700;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 24 : 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: isWideScreen
              ? Row(
                  children: [
                    // Búsqueda
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, usuario o correo...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) => _filtrarUsuarios(value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Filtro Perfil
                    _buildFilterDropdown<int?>(
                      value: _filtroPerfil,
                      hint: 'Perfil',
                      width: isMediumScreen ? 160 : 140,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ..._perfiles.map((p) => DropdownMenuItem<int?>(
                          value: p['id'] as int,
                          child: Text(p['nombre'] ?? ''),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroPerfil = value);
                        _filtrarUsuarios(_searchController.text);
                      },
                    ),
                    const SizedBox(width: 12),
                    // Filtro Sucursal
                    _buildFilterDropdown<int?>(
                      value: _filtroSucursal,
                      hint: 'Sucursal',
                      width: isMediumScreen ? 160 : 140,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ..._sucursales.map((s) => DropdownMenuItem<int?>(
                          value: s['id'] as int,
                          child: Text(s['nombre'] ?? ''),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroSucursal = value);
                        _filtrarUsuarios(_searchController.text);
                      },
                    ),
                    const SizedBox(width: 12),
                    // Filtro Estado
                    _buildFilterDropdown<int?>(
                      value: _filtroEstado,
                      hint: 'Estado',
                      width: isMediumScreen ? 160 : 140,
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 1,
                          child: Text('Activos'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 0,
                          child: Text('Inactivos'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _filtroEstado = value);
                        _filtrarUsuarios(_searchController.text);
                      },
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Búsqueda
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) => _filtrarUsuarios(value),
                    ),
                    const SizedBox(height: 12),
                    // Filtros en fila
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildFilterDropdown<int?>(
                          value: _filtroPerfil,
                          hint: 'Perfil',
                          width: (constraints.maxWidth - 36) / 3,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            ..._perfiles.map((p) => DropdownMenuItem<int?>(
                              value: p['id'] as int,
                              child: Text(p['nombre'] ?? ''),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _filtroPerfil = value);
                            _filtrarUsuarios(_searchController.text);
                          },
                        ),
                        _buildFilterDropdown<int?>(
                          value: _filtroSucursal,
                          hint: 'Sucursal',
                          width: (constraints.maxWidth - 36) / 3,
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ..._sucursales.map((s) => DropdownMenuItem<int?>(
                              value: s['id'] as int,
                              child: Text(s['nombre'] ?? ''),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() => _filtroSucursal = value);
                            _filtrarUsuarios(_searchController.text);
                          },
                        ),
                        _buildFilterDropdown<int?>(
                          value: _filtroEstado,
                          hint: 'Estado',
                          width: (constraints.maxWidth - 36) / 3,
                          items: const [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('Todos'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 1,
                              child: Text('Activos'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 0,
                              child: Text('Inactivos'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _filtroEstado = value);
                            _filtrarUsuarios(_searchController.text);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildFilterDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    double? width,
  }) {
    return Container(
      width: width ?? 160,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildUsuariosTable() {
    if (_usuariosFiltrados.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                _usuarios.isEmpty
                    ? 'No hay usuarios en el sistema'
                    : 'No se encontraron usuarios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              if (_usuarios.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Intenta con otros términos de búsqueda o filtros',
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

    final paginatedUsers = _getPaginatedUsers();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 1200;
        final isMediumScreen = constraints.maxWidth > 800;
        
        // Calcular el ancho total exacto de las columnas
        final totalColumnWidth = isWideScreen
            ? 150.0 + 200.0 + 200.0 + 150.0 + 120.0 + 150.0 + 100.0 + 200.0 + (24.0 * 7) + 32.0
            : isMediumScreen
                ? 120.0 + 180.0 + 180.0 + 120.0 + 100.0 + 150.0 + (12.0 * 5) + 32.0
                : 100.0 + 150.0 + 80.0 + 120.0 + (12.0 * 3) + 32.0;
        
        return Padding(
          padding: EdgeInsets.only(
            left: isWideScreen ? 20 : 16,
            top: 16,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: totalColumnWidth,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DataTable2(
                columnSpacing: isWideScreen ? 24 : 12,
                horizontalMargin: 0,
                minWidth: 0,
                dividerThickness: 0,
                sortColumnIndex: _getSortColumnIndex(),
                sortAscending: _sortAscending,
                headingRowHeight: isWideScreen ? 56 : 52,
                dataRowHeight: isWideScreen ? 64 : 60,
                headingRowDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                  (Set<MaterialState> states) {
                    if (states.contains(MaterialState.selected)) {
                      return AppTheme.primaryColor.withOpacity(0.1);
                    }
                    return Colors.white;
                  },
                ),
            columns: isWideScreen
                ? [
                    _buildDataColumn('Usuario', 'usuario', 150),
                    _buildDataColumn('Nombre Completo', 'nombre_completo', 200),
                    _buildDataColumn('Correo', 'correo', 200),
                    _buildDataColumn('Perfil', 'perfil_nombre', 150),
                    _buildDataColumn('Rol', 'rol_nombre', 120),
                    _buildDataColumn('Sucursal', 'sucursal_activa_nombre', 150),
                    _buildDataColumn('Estado', 'id_estado', 100),
                    const DataColumn2(
                      label: Text(
                        'Acciones',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      fixedWidth: 200,
                    ),
                  ]
                : isMediumScreen
                    ? [
                        _buildDataColumn('Usuario', 'usuario', 120),
                        _buildDataColumn('Nombre', 'nombre_completo', 180),
                        _buildDataColumn('Correo', 'correo', 180),
                        _buildDataColumn('Perfil', 'perfil_nombre', 120),
                        _buildDataColumn('Estado', 'id_estado', 100),
                        const DataColumn2(
                          label: Text(
                            'Acciones',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          fixedWidth: 150,
                        ),
                      ]
                    : [
                        _buildDataColumn('Usuario', 'usuario', 100),
                        _buildDataColumn('Nombre', 'nombre_completo', 150),
                        _buildDataColumn('Estado', 'id_estado', 80),
                        const DataColumn2(
                          label: Text(
                            'Acciones',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          fixedWidth: 120,
                        ),
                      ],
            rows: paginatedUsers.map((usuario) {
              if (isWideScreen) {
                return DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        usuario['usuario'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''} ${usuario['apellido_materno'] ?? ''}'
                            .trim(),
                      ),
                    ),
                    DataCell(Text(usuario['correo'] ?? '')),
                    DataCell(Text(usuario['perfil_nombre'] ?? '')),
                    DataCell(Text(usuario['rol_nombre'] ?? '')),
                    DataCell(Text(usuario['sucursal_activa_nombre'] ?? '')),
                    DataCell(
                      _buildEstadoBadge(usuario['id_estado'] == 1),
                    ),
                    DataCell(
                      _buildActionButtons(usuario),
                    ),
                  ],
                );
              } else if (isMediumScreen) {
                return DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        usuario['usuario'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''}'
                            .trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        usuario['correo'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(Text(usuario['perfil_nombre'] ?? '')),
                    DataCell(
                      _buildEstadoBadge(usuario['id_estado'] == 1),
                    ),
                    DataCell(
                      _buildActionButtons(usuario, compact: true),
                    ),
                  ],
                );
              } else {
                return DataRow2(
                  cells: [
                    DataCell(
                      Text(
                        usuario['usuario'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        '${usuario['nombre'] ?? ''} ${usuario['apellido_paterno'] ?? ''}'
                            .trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      _buildEstadoBadge(usuario['id_estado'] == 1),
                    ),
                    DataCell(
                      _buildActionButtons(usuario, compact: true),
                    ),
                  ],
                );
              }
            }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataColumn2 _buildDataColumn(String label, String columnKey, double width) {
    return DataColumn2(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (_sortColumn == columnKey) ...[
            const SizedBox(width: 8),
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: AppTheme.primaryColor,
            ),
          ],
        ],
      ),
      onSort: (columnIndex, ascending) => _sortUsers(columnKey),
      fixedWidth: width,
    );
  }

  Widget _buildEstadoBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive 
          ? AppTheme.successColor.withOpacity(0.1)
          : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
            ? AppTheme.successColor.withOpacity(0.3)
            : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.successColor : Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Activo' : 'Inactivo',
            style: TextStyle(
              color: isActive ? AppTheme.successColor : Colors.grey[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> usuario, {bool compact = false}) {
    if (compact) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 18),
        onSelected: (value) {
          switch (value) {
            case 'edit':
              _editarUsuario(usuario);
              break;
            case 'apps':
              _mostrarDialogoApps(usuario);
              break;
            case 'status':
              _cambiarEstadoUsuario(usuario);
              break;
            case 'perms':
              _asignarPermisos(usuario);
              break;
            case 'delete':
              _eliminarUsuario(usuario);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: const [
                Icon(Icons.edit_outlined, size: 18, color: AppTheme.infoColor),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'apps',
            child: Row(
              children: const [
                Icon(Icons.apps_outlined, size: 18, color: AppTheme.warningColor),
                SizedBox(width: 8),
                Text('Aplicaciones'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'status',
            child: Row(
              children: [
                Icon(
                  usuario['id_estado'] == 1
                      ? Icons.block_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: usuario['id_estado'] == 1
                      ? AppTheme.warningColor
                      : AppTheme.successColor,
                ),
                const SizedBox(width: 8),
                Text(usuario['id_estado'] == 1 ? 'Desactivar' : 'Activar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'perms',
            child: Row(
              children: const [
                Icon(Icons.security_outlined, size: 18, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text('Permisos'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: const [
                Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                SizedBox(width: 8),
                Text('Eliminar'),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionIconButton(
          icon: Icons.edit_outlined,
          color: AppTheme.infoColor,
          tooltip: 'Editar',
          onPressed: () => _editarUsuario(usuario),
        ),
        const SizedBox(width: 4),
        _buildActionIconButton(
          icon: Icons.apps_outlined,
          color: AppTheme.warningColor,
          tooltip: 'Aplicaciones',
          onPressed: () => _mostrarDialogoApps(usuario),
        ),
        const SizedBox(width: 4),
        _buildActionIconButton(
          icon: usuario['id_estado'] == 1
              ? Icons.block_outlined
              : Icons.check_circle_outline,
          color: usuario['id_estado'] == 1
              ? AppTheme.warningColor
              : AppTheme.successColor,
          tooltip: usuario['id_estado'] == 1 ? 'Desactivar' : 'Activar',
          onPressed: () => _cambiarEstadoUsuario(usuario),
        ),
        const SizedBox(width: 4),
        _buildActionIconButton(
          icon: Icons.security_outlined,
          color: AppTheme.primaryColor,
          tooltip: 'Permisos',
          onPressed: () => _asignarPermisos(usuario),
        ),
        const SizedBox(width: 4),
        _buildActionIconButton(
          icon: Icons.delete_outline,
          color: AppTheme.errorColor,
          tooltip: 'Eliminar',
          onPressed: () => _eliminarUsuario(usuario),
        ),
      ],
    );
  }

  Widget _buildActionIconButton({
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

  Widget _buildPaginationControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 24 : 16,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              top: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          width: double.infinity,
          child: isWideScreen
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mostrando ${_getPaginatedUsers().length} de ${_usuariosFiltrados.length} usuarios',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Por página: ',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
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
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                          icon: const Icon(Icons.first_page),
                          tooltip: 'Primera página',
                        ),
                        IconButton(
                          onPressed: _currentPage > 1 ? _previousPage : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Página anterior',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_currentPage / $_totalPages',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          onPressed: _currentPage < _totalPages ? _nextPage : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Página siguiente',
                        ),
                        IconButton(
                          onPressed: _currentPage < _totalPages
                              ? () => _goToPage(_totalPages)
                              : null,
                          icon: const Icon(Icons.last_page),
                          tooltip: 'Última página',
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Mostrando ${_getPaginatedUsers().length} de ${_usuariosFiltrados.length} usuarios',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _currentPage > 1 ? () => _goToPage(1) : null,
                          icon: const Icon(Icons.first_page),
                          tooltip: 'Primera página',
                        ),
                        IconButton(
                          onPressed: _currentPage > 1 ? _previousPage : null,
                          icon: const Icon(Icons.chevron_left),
                          tooltip: 'Página anterior',
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '$_currentPage / $_totalPages',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          onPressed: _currentPage < _totalPages ? _nextPage : null,
                          icon: const Icon(Icons.chevron_right),
                          tooltip: 'Página siguiente',
                        ),
                        IconButton(
                          onPressed: _currentPage < _totalPages
                              ? () => _goToPage(_totalPages)
                              : null,
                          icon: const Icon(Icons.last_page),
                          tooltip: 'Última página',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Por página: ',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
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
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ... (mantener todos los métodos existentes desde _mostrarFormularioUsuario hasta _mostrarInfo)
  // Por brevedad, incluyo solo los métodos principales que cambian

  void _mostrarFormularioUsuario() {
    _limpiarFormulario();
    setState(() {
      _isCreatingUser = true;
      _isEditingUser = false;
    });
    _mostrarDialogoUsuario();
  }

  Future<void> _editarUsuario(Map<String, dynamic> usuario) async {
    _editingUser = usuario;
    _usuarioController.text = usuario['usuario'] ?? '';
    _nombreController.text = usuario['nombre'] ?? '';
    _apellidoPaternoController.text = usuario['apellido_paterno'] ?? '';
    _apellidoMaternoController.text = usuario['apellido_materno'] ?? '';
    _correoController.text = usuario['correo'] ?? '';
    _selectedPerfil = usuario['id_perfil'];
    _selectedSucursal = usuario['id_sucursalactiva'];
    _selectedRol = usuario['id_rol'];
    await _cargarAppsUsuario(usuario['id']);
    
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
            DropdownButtonFormField<int>(
              value: _selectedRol,
              decoration: const InputDecoration(
                labelText: 'Rol *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Administrador')),
                DropdownMenuItem(value: 2, child: Text('Usuario')),
                DropdownMenuItem(value: 3, child: Text('Supervisor')),
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
          ],
        ),
      ),
    );
  }

  // Métodos auxiliares que se mantienen igual
  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      setState(() => _isLoading = true);
      String usuarioId;
      if (_isCreatingUser) {
        usuarioId = await _crearUsuario();
        _mostrarExito('Usuario creado exitosamente');
      } else {
        await _actualizarUsuario();
        usuarioId = _editingUser!['id'];
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

  Future<String> _crearUsuario() async {
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
      headers: {
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
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
      final response = await HttpInterceptor.post(
        context,
        Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId/aplicaciones'),
        body: {'apps_ids': appsIds},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Error asignando aplicaciones: ${response.statusCode}');
      }
    } catch (e) {
      print('Error asignando aplicaciones: $e');
    }
  }

  Future<void> _cargarAppsUsuario(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
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
    } catch (e) {
      // Silencioso
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

  Future<void> _cambiarEstadoUsuarioAPI(String usuarioId, int nuevoEstado) async {
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
      throw Exception(errorData['message'] ?? 'Error cambiando estado del usuario');
    }
  }

  void _asignarPermisos(Map<String, dynamic> usuario) {
    _mostrarDialogoPermisos(usuario);
  }

  Future<void> _mostrarDialogoApps(Map<String, dynamic> usuario) async {
    List<int> appsAsignadas = [];
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/${usuario['id']}'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['apps_permitidas'] ?? data['data']?['apps_permitidas'] ?? []) as List;
        appsAsignadas = list.map<int>((a) {
          if (a is Map && a['id'] != null) return (a['id'] as num).toInt();
          if (a is num) return a.toInt();
          return -1;
        }).where((id) => id != -1).toList();
      }
    } catch (_) {}

    final idsTodas = _apps.map<int>((a) => (a['id'] as num).toInt()).toSet();
    List<int> asignadas = appsAsignadas.toSet().toList()..sort();
    List<int> disponibles = idsTodas.difference(asignadas.toSet()).toList()..sort();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void moverAAsignadas(int id) {
            setDialogState(() {
              disponibles.remove(id);
              if (!asignadas.contains(id)) asignadas.add(id);
              asignadas.sort();
            });
          }

          void moverADisponibles(int id) {
            setDialogState(() {
              asignadas.remove(id);
              if (!disponibles.contains(id)) disponibles.add(id);
              disponibles.sort();
            });
          }

          List<Map<String, dynamic>> appsByIds(List<int> ids) {
            final map = {for (var a in _apps) (a['id'] as num).toInt(): a};
            return ids.map((id) => map[id] as Map<String, dynamic>).where((e) => e != null).toList();
          }

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.apps, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Text('Aplicaciones - ${usuario['usuario']}'),
              ],
            ),
            content: SizedBox(
              width: 720,
              height: 420,
              child: Row(
                children: [
                  Expanded(
                    child: _buildDualListColumn(
                      title: 'Asignadas',
                      color: AppTheme.warningColor,
                      items: appsByIds(asignadas),
                      actionText: 'Quitar',
                      actionIcon: Icons.remove_circle,
                      onAction: (id) => moverADisponibles(id),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: disponibles.isNotEmpty ? () => moverAAsignadas(disponibles.first) : null,
                          icon: const Icon(Icons.arrow_forward, color: AppTheme.warningColor),
                          tooltip: 'Agregar',
                        ),
                        IconButton(
                          onPressed: asignadas.isNotEmpty ? () => moverADisponibles(asignadas.first) : null,
                          icon: const Icon(Icons.arrow_back, color: AppTheme.warningColor),
                          tooltip: 'Quitar',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildDualListColumn(
                      title: 'Disponibles',
                      color: Colors.blueGrey,
                      items: appsByIds(disponibles),
                      actionText: 'Agregar',
                      actionIcon: Icons.add_circle,
                      onAction: (id) => moverAAsignadas(id),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _asignarAplicaciones(
                      usuario['id'],
                      asignadas,
                    );
                    _mostrarExito('Aplicaciones actualizadas');
                    await _cargarDatos();
                  } catch (e) {
                    _mostrarError('Error actualizando aplicaciones: $e');
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDualListColumn({
    required String title,
    required Color color,
    required List<Map<String, dynamic>> items,
    required String actionText,
    required IconData actionIcon,
    required void Function(int) onAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
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
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    items.length.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Sin elementos',
                      style: TextStyle(color: color.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final id = (item['id'] as num).toInt();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nombre'] ?? 'App',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  if ((item['descripcion'] ?? '').toString().isNotEmpty)
                                    Text(
                                      item['descripcion'],
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => onAction(id),
                              icon: Icon(actionIcon, color: color),
                              label: Text(actionText),
                              style: TextButton.styleFrom(foregroundColor: color),
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

  void _mostrarDialogoPermisos(Map<String, dynamic> usuario) async {
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
    
    final permisosExistentes = await _cargarPermisosUsuario(usuario['id']);
    Navigator.pop(context);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
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
              child: Row(
                children: [
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
      Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId/permisos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'permisos_ids': permisosIds}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error asignando permisos');
    }
  }

  Future<List<String>> _cargarPermisosUsuario(String usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId'),
        headers: {
          'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        List permisosAsignados = [];
        
        if (userData['permisos_asignados'] != null) {
          permisosAsignados = userData['permisos_asignados'];
        } else if (userData['permisos'] != null) {
          permisosAsignados = userData['permisos'];
        } else if (userData['data'] != null && userData['data']['permisos_asignados'] != null) {
          permisosAsignados = userData['data']['permisos_asignados'];
        }
        
        if (permisosAsignados.isNotEmpty) {
          return permisosAsignados.map<String>((permiso) {
            if (permiso is Map) {
              return permiso['id']?.toString() ?? '';
            } else if (permiso is String) {
              return permiso;
            }
            return '';
          }).where((id) => id.isNotEmpty).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error cargando permisos del usuario: $e');
      return [];
    }
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
        final matchesSucursal = _filtroSucursal == null || usuario['id_sucursalactiva'] == _filtroSucursal;
        final matchesEstado = _filtroEstado == null || usuario['id_estado'] == _filtroEstado;
        return matchesText && matchesPerfil && matchesSucursal && matchesEstado;
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
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> _getSortedUsers() {
    final sortedUsers = List<Map<String, dynamic>>.from(_usuariosFiltrados);
    
    sortedUsers.sort((a, b) {
      dynamic aValue = a[_sortColumn] ?? '';
      dynamic bValue = b[_sortColumn] ?? '';
      
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
    final response = await HttpInterceptor.delete(
      context,
      Uri.parse('${ApiConfig.usuariosUrl}/$usuarioId'),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
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

  void _mostrarFormularioPermiso() {
    final _nombreController = TextEditingController();
    int? _idApp;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Crear Nuevo Permiso'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del Permiso',
                    hintText: 'EJ: VER_USUARIOS',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _idApp,
                  decoration: const InputDecoration(
                    labelText: 'Aplicación',
                    border: OutlineInputBorder(),
                  ),
                  items: _apps.map((a) => DropdownMenuItem<int>(
                    value: a['id'] as int,
                    child: Text(a['nombre']),
                  )).toList(),
                  onChanged: (value) => setStateDialog(() => _idApp = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_nombreController.text.trim().isEmpty || _idApp == null) return;
                Navigator.pop(context);
                try {
                  await _crearPermiso(_nombreController.text.trim(), _idApp!);
                  _mostrarExito('Permiso creado exitosamente');
                  await _cargarDatos();
                } catch (e) {
                  _mostrarError('Error creando permiso: $e');
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearPermiso(String nombre, int idApp) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.usuariosUrl}/permisos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Provider.of<AuthProvider>(context, listen: false).token}',
      },
      body: jsonEncode({'nombre': nombre, 'id_app': idApp}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Error creando permiso');
    }
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
      Uri.parse('${ApiConfig.usuariosUrl}/aplicaciones'),
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

    if (response.statusCode != 201 && response.statusCode != 200) {
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
