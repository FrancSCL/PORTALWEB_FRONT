import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';
import '../config/app_routes.dart';
import 'login_screen.dart';
import '../widgets/sucursal_selector.dart';
import '../widgets/main_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, String routeName) {
    NavigationHelper.navigateTo(context, routeName);
  }

  Future<void> _confirmarCerrarSesion(BuildContext context, AuthProvider authProvider) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: AppTheme.errorColor,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Cerrar Sesión'),
            ],
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        NavigationHelper.navigateToAndRemoveUntil(context, AppRoutes.login);
      }
    }
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Buscar en el menú...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        prefixIcon: Icon(Icons.search, color: Colors.black54),
      ),
      style: const TextStyle(color: Colors.black),
      onChanged: (value) {
        // No hacer nada aquí para evitar SnackBars molestos
      },
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Búsqueda completada: $value'),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        setState(() => _isSearching = false);
      },
    );
  }

  List<Widget> _buildAppBarActions(ThemeProvider themeProvider, AuthProvider authProvider) {
    if (_isSearching) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchController.text.isEmpty) {
              setState(() => _isSearching = false);
            } else {
              _searchController.clear();
            }
          },
        ),
      ];
    }

    return [
      // Botón de búsqueda
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearching = true),
      ),
      // Selector de sucursal global
      const SucursalSelector(),
      // Botón de tema
      IconButton(
        icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
        onPressed: () => themeProvider.toggleTheme(),
      ),
      // Botón de cerrar sesión
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.white),
        onPressed: () => _confirmarCerrarSesion(context, authProvider),
      ),
    ];
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de bienvenida
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.agriculture,
                        size: 32,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Plataforma de Reportería Agrícola',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Monitoreo y gestión integral de operaciones agrícolas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // KPIs Principales
          const Text(
            'Indicadores Clave de Rendimiento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Primera fila de KPIs
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Hectáreas Cultivadas',
                  '1,250',
                  'ha',
                  Icons.agriculture,
                  AppTheme.primaryColor,
                  '+5.2% vs mes anterior',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Producción Total',
                  '2,450',
                  'ton',
                  Icons.grain,
                  AppTheme.successColor,
                  '+8.1% vs mes anterior',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Segunda fila de KPIs
          Row(
            children: [
              Expanded(
                child: _buildKPICard(
                  'Eficiencia de Riego',
                  '87',
                  '%',
                  Icons.water_drop,
                  AppTheme.infoColor,
                  '+2.3% vs mes anterior',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKPICard(
                  'Personal Activo',
                  '45',
                  'personas',
                  Icons.people,
                  AppTheme.warningColor,
                  '3 en licencia médica',
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Menú de Módulos tipo Windows
          const Text(
            'Módulos del Sistema',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildModuleCard(
                'General',
                Icons.dashboard,
                AppTheme.primaryColor,
                'Gestión general y reportes',
                () => _showModuleInfo('General'),
              ),
              _buildModuleCard(
                'Producción',
                Icons.grain,
                AppTheme.successColor,
                'Control de cultivos y cosechas',
                () => _showModuleInfo('Producción'),
              ),
              _buildModuleCard(
                'Riegos',
                Icons.water_drop,
                AppTheme.infoColor,
                'Sistemas de riego y humedad',
                () => _showModuleInfo('Riegos'),
              ),
              _buildModuleCard(
                'Cecos',
                Icons.account_balance,
                AppTheme.successColor,
                'Centros de costo y contabilidad',
                () => _showModuleInfo('Cecos'),
              ),
              _buildModuleCard(
                'Cuarteles',
                Icons.grid_on,
                AppTheme.warningColor,
                'Gestión de hileras y plantas',
                () => _showModuleInfo('Cuarteles'),
              ),
              _buildModuleCard(
                'Mapeo',
                Icons.map,
                AppTheme.accentColor,
                'Visualización geográfica',
                () => _showModuleInfo('Mapeo'),
              ),
              _buildModuleCard(
                'RRHH',
                Icons.people,
                AppTheme.warningColor,
                'Gestión de personal',
                () => _showModuleInfo('RRHH'),
              ),
              _buildModuleCard(
                'Actividades',
                Icons.assignment,
                AppTheme.accentColor,
                'Planificación y seguimiento',
                () => _showModuleInfo('Actividades'),
              ),
              _buildModuleCard(
                'Parámetros',
                Icons.settings,
                AppTheme.errorColor,
                'Configuración del sistema',
                () => _showModuleInfo('Parámetros'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Actividades Recientes
          const Text(
            'Actividades Recientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildRecentActivities(),
        ],
      ),
    );
  }

  Widget _buildKPICard(String title, String value, String unit, IconData icon, Color color, String trend) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                color: trend.contains('+') ? AppTheme.successColor : AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(String title, IconData icon, Color color, String description, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'icon': Icons.grain, 'title': 'Cosecha de trigo completada', 'time': 'Hace 2 horas', 'color': AppTheme.successColor},
      {'icon': Icons.water_drop, 'title': 'Riego automático activado', 'time': 'Hace 4 horas', 'color': AppTheme.infoColor},
      {'icon': Icons.people, 'title': 'Nuevo empleado registrado', 'time': 'Hace 6 horas', 'color': AppTheme.warningColor},
      {'icon': Icons.assignment, 'title': 'Planificación semanal actualizada', 'time': 'Hace 1 día', 'color': AppTheme.accentColor},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: (activity['color'] as Color).withOpacity(0.1),
              child: Icon(
                activity['icon'] as IconData,
                color: activity['color'] as Color,
                size: 20,
              ),
            ),
            title: Text(
              activity['title'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              activity['time'] as String,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ver detalles: ${activity['title']}'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showModuleInfo(String module) {
    final moduleInfo = {
      'General': 'Dashboard principal con indicadores generales y reportes consolidados',
      'Producción': 'Gestión de cultivos, cosechas, rendimientos y planificación agrícola',
      'Riego': 'Control de sistemas de riego, monitoreo de humedad y eficiencia hídrica',
      'RRHH': 'Gestión de personal, horarios, capacitaciones y recursos humanos',
      'Actividades': 'Planificación, seguimiento y control de actividades diarias',
      'Parámetros': 'Configuración del sistema, parámetros técnicos y ajustes',
    };

    // Navegar directamente a las pantallas correspondientes
    switch (module) {
      case 'Producción':
        _navigateTo(context, AppRoutes.produccion);
        break;
      case 'Riegos':
        _navigateTo(context, AppRoutes.riego);
        break;
      case 'Cecos':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Módulo: Cecos'),
            content: const Text('Gestión de centros de costo y contabilidad - En desarrollo'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Accediendo al módulo: Cecos'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
                child: const Text('Acceder'),
              ),
            ],
          ),
        );
        break;
      case 'Cuarteles':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Módulo: Cuarteles'),
            content: const Text('Gestión de hileras y plantas de cuarteles - En desarrollo'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Accediendo al módulo: Cuarteles'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                },
                child: const Text('Acceder'),
              ),
            ],
          ),
        );
        break;
      case 'Mapeo':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Módulo: Mapeo'),
            content: const Text('Visualización geográfica y mapas - En desarrollo'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Accediendo al módulo: Mapeo'),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                },
                child: const Text('Acceder'),
              ),
            ],
          ),
        );
        break;
      case 'Actividades':
        _navigateTo(context, AppRoutes.actividades);
        break;
      case 'Parámetros':
        _navigateTo(context, AppRoutes.parametros);
        break;
      default:
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Módulo: $module'),
            content: Text(moduleInfo[module] ?? 'Información no disponible'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Accediendo al módulo: $module'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                child: const Text('Acceder'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'Plataforma Agrícola',
      currentRoute: AppRoutes.home,
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      body: Column(
        children: [
          Expanded(
            child: _isSearching
                ? _buildSearchField()
                : _buildDashboardContent(),
          ),
        ],
      ),
    );
  }


} 