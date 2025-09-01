import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sidebar_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../screens/parametros_screen.dart';
import '../screens/cambiar_clave_screen.dart';
import '../screens/cambiar_sucursal_screen.dart';

class PersistentSidebar extends StatelessWidget {
  final Widget child;
  final String currentRoute;

  const PersistentSidebar({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SidebarProvider>(
      builder: (context, sidebarProvider, _) {
        return Row(
          children: [
            // Sidebar con ancho fijo para evitar overflow
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: sidebarProvider.isExpanded ? 240 : 80,
              child: _buildSidebar(context, sidebarProvider),
            ),
            // Contenido principal
            Expanded(
              child: child,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, SidebarProvider sidebarProvider) {
    return Container(
      color: AppTheme.mediumGreen,
      child: Column(
        children: [
          // Header del sidebar
          _buildSidebarHeader(context, sidebarProvider),
          // Menú items
          Expanded(
            child: _buildMenuItems(context, sidebarProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, SidebarProvider sidebarProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Logo redondo clickeable
          InkWell(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/lh.jpg',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Título (solo visible cuando está expandido)
          if (sidebarProvider.isExpanded) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'agroLh',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          // Botón de toggle (asegurado que esté dentro del sidebar)
          Container(
            margin: const EdgeInsets.only(right: 2),
            child: IconButton(
              onPressed: () => sidebarProvider.toggleSidebar(),
              icon: Icon(
                sidebarProvider.isExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: Colors.white,
                size: 18,
              ),
              tooltip: sidebarProvider.isExpanded ? 'Colapsar menú' : 'Expandir menú',
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, SidebarProvider sidebarProvider) {
    final menuItems = [
      {
        'icon': Icons.home,
        'title': 'Inicio',
        'route': '/',
        'isActive': currentRoute == '/',
      },
      {
        'icon': Icons.settings,
        'title': 'Configuración',
        'route': '/parametros',
        'isActive': currentRoute == '/parametros',
      },
      {
        'icon': Icons.lock,
        'title': 'Cambiar Clave',
        'route': '/cambiar-clave',
        'isActive': currentRoute == '/cambiar-clave',
      },
      {
        'icon': Icons.business,
        'title': 'Sucursal',
        'route': '/cambiar-sucursal',
        'isActive': currentRoute == '/cambiar-sucursal',
      },
      {
        'icon': Icons.logout,
        'title': 'Cerrar Sesión',
        'route': '/logout',
        'isActive': false,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return _buildMenuItem(context, item, sidebarProvider);
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    Map<String, dynamic> item,
    SidebarProvider sidebarProvider,
  ) {
    final isActive = item['isActive'] as bool;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleMenuTap(context, item),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  item['icon'] as IconData,
                  color: Colors.white,
                  size: 20,
                ),
                if (sidebarProvider.isExpanded) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuTap(BuildContext context, Map<String, dynamic> item) {
    final route = item['route'] as String;
    
    switch (route) {
      case '/':
        Navigator.pushReplacementNamed(context, '/');
        break;
      case '/parametros':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ParametrosScreen()),
        );
        break;
      case '/cambiar-clave':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CambiarClaveScreen()),
        );
        break;
      case '/cambiar-sucursal':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CambiarSucursalScreen()),
        );
        break;
      case '/logout':
        _handleLogout(context);
        break;
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}
