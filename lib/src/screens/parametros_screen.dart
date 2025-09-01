import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import 'mapeo_screen.dart';
import 'admin_usuarios_screen.dart';

class ParametrosScreen extends StatefulWidget {
  const ParametrosScreen({super.key});

  @override
  State<ParametrosScreen> createState() => _ParametrosScreenState();
}

class _ParametrosScreenState extends State<ParametrosScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'Administración de Parámetros',
      currentRoute: '/parametros',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildCategoriesGrid(),
          ),
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
          const Text(
            'Configuración General',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configuración General',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = _getCategories();
    
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200), // Contenedor centralizado
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280, // Ancho máximo de 280px por tarjeta
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0, // Más cuadrado como en la imagen de referencia
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryCard(category);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return CategoryCard(category: category, onTap: () {
      if (category['name'] == 'Mapeo') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapeoScreen()),
        );
      } else if (category['name'] == 'Usuarios') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminUsuariosScreen()),
        );
      } else {
        _showCategoryDetails(category);
      }
    });
  }

  void _showCategoryDetails(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              category['icon'] as IconData,
              color: category['color'] as Color,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(category['name']),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: (category['subcategories'] as List).length,
            itemBuilder: (context, index) {
              final subcategory = (category['subcategories'] as List)[index];
              return _buildSubcategoryCard(subcategory, category['color'] as Color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory, Color categoryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: categoryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _showSubcategoryDetails(subcategory, categoryColor);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  subcategory['icon'] as IconData,
                  color: categoryColor,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  subcategory['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSubcategoryDetails(Map<String, dynamic> subcategory, Color categoryColor) {
                // Si es la subcategoría de Mapeo, navegar directamente a la pantalla de mapeo
            if (subcategory['name'] == 'Configuración de Mapas' || subcategory['name'] == 'Capas de Información') {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapeoScreen()),
              );
              return;
            }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              subcategory['icon'] as IconData,
              color: categoryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(subcategory['name']),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subcategory['description']),
            const SizedBox(height: 16),
            Text(
              'Parámetros disponibles:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(subcategory['parameters'] as List).map((param) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 16, color: categoryColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(param)),
                  ],
                ),
              ),
            ).toList(),
          ],
        ),
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
                  content: Text('Accediendo a ${subcategory['name']}'),
                  backgroundColor: categoryColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: categoryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Acceder'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getCategories() {
    return [
      {
        'name': 'General',
        'color': AppTheme.lightGreen,
        'icon': Icons.settings,
        'subcategories': [
          {
            'name': 'Información Empresarial',
            'description': 'Datos básicos de la empresa',
            'icon': Icons.business,
            'parameters': ['Nombre de la Empresa', 'CUIT', 'Dirección', 'Teléfono', 'Email'],
          },
          {
            'name': 'Configuración Sistema',
            'description': 'Ajustes del sistema',
            'icon': Icons.tune,
            'parameters': ['Idioma', 'Zona Horaria', 'Moneda', 'Unidad de Medida'],
          },
          {
            'name': 'Responsables',
            'description': 'Personal responsable',
            'icon': Icons.people,
            'parameters': ['Responsable Técnico', 'Encargado de Producción'],
          },
        ],
      },
      {
        'name': 'Mapeo',
        'color': AppTheme.mediumGreen,
        'icon': Icons.map,
        'subcategories': [
          {
            'name': 'Configuración de Mapas',
            'description': 'Ajustes de visualización',
            'icon': Icons.map_outlined,
            'parameters': ['Escala del Mapa', 'Zoom Mínimo', 'Zoom Máximo'],
          },
          {
            'name': 'Capas de Información',
            'description': 'Capas disponibles en mapas',
            'icon': Icons.layers,
            'parameters': ['Capas de Cultivos', 'Capas de Riego', 'Capas de Suelo'],
          },
        ],
      },
      {
        'name': 'Riegos',
        'color': const Color(0xFF1976D2), // Azul más armónico con la paleta verde
        'icon': Icons.water_drop,
        'subcategories': [
          {
            'name': 'Configuración de Riego',
            'description': 'Parámetros de riego automático',
            'icon': Icons.water,
            'parameters': ['Frecuencia de Riego', 'Presión Mínima', 'Duración Máxima'],
          },
          {
            'name': 'Zonas de Riego',
            'description': 'Gestión de zonas de riego',
            'icon': Icons.location_on,
            'parameters': ['Zonas Activas', 'Horarios de Riego', 'Consumo de Agua'],
          },
        ],
      },
      {
        'name': 'Cecos',
        'color': AppTheme.primaryColor,
        'icon': Icons.account_balance,
        'subcategories': [
          {
            'name': 'Centros de Costo',
            'description': 'Gestión de centros de costo',
            'icon': Icons.account_balance_wallet,
            'parameters': ['Ceco Principal', 'Ceco Producción', 'Ceco Mantenimiento'],
          },
          {
            'name': 'Asignación de Costos',
            'description': 'Distribución de costos',
            'icon': Icons.attach_money,
            'parameters': ['Distribución por Hectárea', 'Costos por Cultivo'],
          },
        ],
      },
      {
        'name': 'Cuarteles',
        'color': AppTheme.warningColor,
        'icon': Icons.grid_on,
        'subcategories': [
          {
            'name': 'Configuración de Cuarteles',
            'description': 'Parámetros de diseño de cuarteles',
            'icon': Icons.grid_4x4,
            'parameters': ['Distancia entre Hileras', 'Distancia entre Plantas', 'Plantas por Hectárea'],
          },
          {
            'name': 'Gestión de Hileras',
            'description': 'Configuración de hileras',
            'icon': Icons.view_column,
            'parameters': ['Ancho de Hileras', 'Espaciado', 'Orientación'],
          },
        ],
      },
      {
        'name': 'Usuarios',
        'color': AppTheme.infoColor,
        'icon': Icons.people,
        'subcategories': [
          {
            'name': 'Administración de Usuarios',
            'description': 'Gestión completa de usuarios del sistema',
            'icon': Icons.person_add,
            'parameters': ['Crear Usuarios', 'Editar Usuarios', 'Asignar Permisos', 'Gestionar Perfiles'],
          },
          {
            'name': 'Gestión de Perfiles',
            'description': 'Configuración de perfiles y roles',
            'icon': Icons.security,
            'parameters': ['Perfiles de Usuario', 'Roles del Sistema', 'Jerarquía de Permisos'],
          },
        ],
      },
    ];
  }
}

// Widget individual para cada tarjeta de categoría
class CategoryCard extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHovered ? 1.02 : 1.0, // Solo esta tarjeta se escala
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: _isHovered ? 8 : 6, // Sombra más notoria en hover
        shadowColor: Colors.black.withOpacity(_isHovered ? 0.2 : 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Reducido de 16 a 12
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (widget.category['color'] as Color).withOpacity(_isHovered ? 0.12 : 0.08), // Más intenso en hover
                (widget.category['color'] as Color).withOpacity(_isHovered ? 0.05 : 0.03), // Más intenso en hover
              ],
            ),
            border: Border.all(
              color: (widget.category['color'] as Color).withOpacity(_isHovered ? 0.35 : 0.25), // Más intenso en hover
              width: _isHovered ? 1.5 : 1, // Borde más grueso en hover
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(12),
            onHover: (isHovered) {
              setState(() {
                _isHovered = isHovered;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20), // Aumentado para mejor balance
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16), // Aumentado para mejor balance
                    decoration: BoxDecoration(
                      color: (widget.category['color'] as Color).withOpacity(_isHovered ? 0.2 : 0.15), // Más intenso en hover
                      borderRadius: BorderRadius.circular(12), // Aumentado para mejor balance
                    ),
                    child: Icon(
                      widget.category['icon'] as IconData,
                      color: (widget.category['color'] as Color).withOpacity(0.9), // Más contraste
                      size: _isHovered ? 32 : 30, // Ligeramente más grande para mejor balance
                    ),
                  ),
                  const SizedBox(height: 16), // Aumentado para mejor balance sin subcategorías
                  Text(
                    widget.category['name'],
                    style: TextStyle(
                      fontSize: 16, // Reducido de 18 a 16 (11% menos)
                      fontWeight: FontWeight.w600, // Cambiado de bold a w600
                      color: (widget.category['color'] as Color).withOpacity(0.9), // Más contraste
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
