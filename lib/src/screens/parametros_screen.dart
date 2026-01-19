import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/navigation_service.dart';
import '../config/app_routes.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
      child: Row(
        children: [
          const Text(
            'Configuración General',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = _getCategories();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 columnas fijas
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 4.5, // Más ancho y compacto
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(category);
        },
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return CategoryCard(category: category, onTap: () {
      if (category['name'] == 'Mapeo') {
        NavigationHelper.navigateTo(context, AppRoutes.mapeo);
      } else if (category['name'] == 'Usuarios') {
        NavigationHelper.navigateTo(context, AppRoutes.adminUsuarios);
      } else {
        _showCategoryDetails(category);
      }
    });
  }

  void _showCategoryDetails(Map<String, dynamic> category) {
    // Si es Estimaciones, mostrar directamente sus subcategorías
    if (category['name'] == 'Estimaciones') {
      _showEstimacionesSubcategories(category['color'] as Color);
      return;
    }

    // Si es Conteo, mostrar directamente sus subcategorías
    if (category['name'] == 'Conteo') {
      _showConteoSubcategories(category['color'] as Color);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  category['icon'] as IconData,
                  color: category['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona una categoría para configurar los parámetros',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: 600, // Ancho fijo para mejor control
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: (category['subcategories'] as List).length,
                  itemBuilder: (context, index) {
                    final subcategory = (category['subcategories'] as List)[index];
                    return _buildImprovedSubcategoryCard(subcategory, category['color'] as Color);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryCard(Map<String, dynamic> subcategory, Color categoryColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Reducido de 12 a 8
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Reducido de 12 a 8
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
          borderRadius: BorderRadius.circular(8), // Reducido de 12 a 8
          child: Padding(
            padding: const EdgeInsets.all(8), // Reducido de 12 a 8
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  subcategory['icon'] as IconData,
                  color: categoryColor,
                  size: 20, // Reducido de 24 a 20
                ),
                const SizedBox(height: 6), // Reducido de 8 a 6
                Text(
                  subcategory['name'],
                  style: const TextStyle(
                    fontSize: 12, // Reducido de 14 a 12
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

  Widget _buildImprovedSubcategoryCard(Map<String, dynamic> subcategory, Color categoryColor) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Card(
              elevation: isHovered ? 8 : 4,
              shadowColor: categoryColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isHovered ? categoryColor : Colors.grey[300]!,
                  width: isHovered ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _showSubcategoryDetails(subcategory, categoryColor);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isHovered
                          ? [
                              categoryColor.withOpacity(0.1),
                              categoryColor.withOpacity(0.05),
                            ]
                          : [
                              Colors.white,
                              Colors.grey[50]!,
                            ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icono con fondo
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(isHovered ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isHovered
                                ? [
                                    BoxShadow(
                                      color: categoryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            subcategory['icon'] as IconData,
                            color: categoryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Título
                        Text(
                          subcategory['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isHovered ? categoryColor : Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Descripción
                        Text(
                          subcategory['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Indicador de acción
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isHovered ? categoryColor : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_forward,
                                size: 12,
                                color: isHovered ? Colors.white : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Acceder',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isHovered ? Colors.white : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSubcategoryDetails(Map<String, dynamic> subcategory, Color categoryColor) {
    // Si es la subcategoría de Mapeo, navegar directamente a la pantalla de mapeo
    if (subcategory['name'] == 'Configuración de Mapas' || subcategory['name'] == 'Capas de Información') {
      Navigator.pop(context);
      NavigationHelper.navigateTo(context, AppRoutes.mapeo);
      return;
    }

    // Para las nuevas subcategorías de Conteo
    if (subcategory['name'] == 'Pauta') {
      Navigator.pop(context);
      NavigationHelper.navigateTo(context, AppRoutes.pautasGestion);
      return;
    }

    if (subcategory['name'] == 'Manejo de parámetros de conteo') {
      Navigator.pop(context);
      NavigationHelper.navigateTo(context, AppRoutes.manejoParametrosConteo);
      return;
    }

    if (subcategory['name'] == 'Configuración conteo-pauta') {
      Navigator.pop(context);
      NavigationHelper.navigateTo(context, AppRoutes.pautasConfiguracion);
      return;
    }

    if (subcategory['name'] == 'Asociaciones Labor-Especie') {
      Navigator.pop(context);
      NavigationHelper.navigateTo(context, AppRoutes.configuracionAsociaciones);
      return;
    }

    // Para las nuevas subcategorías de Estimaciones
    if (subcategory['name'] == 'Estimaciones. Rendimientos Packing') {
      Navigator.pop(context);
      NavigationHelper.navigateTo(context, AppRoutes.estimaciones);
      return;
    }

    if (subcategory['name'] == 'Frutos x ramilla historico') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Frutos x ramilla historico - Funcionalidad en desarrollo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (subcategory['name'] == 'Calibres historicos') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibres historicos - Funcionalidad en desarrollo'),
          backgroundColor: Colors.orange,
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    backgroundColor: Colors.grey[200],
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: ElevatedButton(
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
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Icon(Icons.check, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEstimacionesSubcategories(Color categoryColor) {
    List<Map<String, dynamic>> subcategories = [
      {
        'name': 'Estimaciones. Rendimientos Packing',
        'description': 'Configuración de estimaciones de rendimientos para packing',
        'icon': Icons.inventory,
        'parameters': ['Rendimientos por Packing', 'Parámetros de Calidad', 'Estimaciones de Producción'],
      },
      {
        'name': 'Frutos x ramilla historico',
        'description': 'Histórico de frutos por ramilla para análisis',
        'icon': Icons.history,
        'parameters': ['Datos Históricos', 'Tendencias', 'Análisis Comparativo'],
      },
      {
        'name': 'Calibres historicos',
        'description': 'Histórico de calibres para análisis de calidad',
        'icon': Icons.analytics,
        'parameters': ['Calibres Históricos', 'Distribución de Tamaños', 'Tendencias de Calidad'],
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimaciones',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona una opción para configurar los parámetros de estimaciones',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: 600,
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    return _buildImprovedSubcategoryCard(subcategory, categoryColor);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showConteoSubcategories(Color categoryColor) {
    List<Map<String, dynamic>> subcategories = [
      {
        'name': 'Pauta',
        'description': 'Configuración de pautas de conteo',
        'icon': Icons.assignment,
        'parameters': ['Pautas de Trabajo', 'Estándares de Calidad', 'Procedimientos'],
      },
      {
        'name': 'Manejo de parámetros de conteo',
        'description': 'Gestión de parámetros para conteo',
        'icon': Icons.settings,
        'parameters': ['Parámetros de Conteo', 'Configuración de Equipos', 'Ajustes del Sistema'],
      },
      {
        'name': 'Configuración conteo-pauta',
        'description': 'Configuración específica de conteo y pautas',
        'icon': Icons.tune,
        'parameters': ['Configuración Conteo', 'Configuración Pauta', 'Integración de Sistemas'],
      },
      {
        'name': 'Asociaciones Labor-Especie',
        'description': 'Configurar asociaciones entre labores y especies',
        'icon': Icons.link,
        'parameters': ['Labor-Especie', 'Atributo-Especie', 'Configuración Pivot'],
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calculate,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conteo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selecciona una opción para configurar los parámetros de conteo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: 600,
          constraints: const BoxConstraints(
            minHeight: 200,
            maxHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    return _buildImprovedSubcategoryCard(subcategory, categoryColor);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      backgroundColor: Colors.grey[200],
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ],
            ),
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
      {
        'name': 'Conteo',
        'color': const Color(0xFF9C27B0), // Púrpura distintivo para conteo
        'icon': Icons.calculate,
        'subcategories': [
          {
            'name': 'Pauta',
            'description': 'Configuración de pautas de conteo',
            'icon': Icons.assignment,
            'parameters': ['Pautas de Trabajo', 'Estándares de Calidad', 'Procedimientos'],
          },
          {
            'name': 'Manejo de parámetros de conteo',
            'description': 'Gestión de parámetros para conteo',
            'icon': Icons.settings,
            'parameters': ['Parámetros de Conteo', 'Configuración de Equipos', 'Ajustes del Sistema'],
          },
          {
            'name': 'Configuración conteo-pauta',
            'description': 'Configuración específica de conteo y pautas',
            'icon': Icons.tune,
            'parameters': ['Configuración Conteo', 'Configuración Pauta', 'Integración de Sistemas'],
          },
        ],
      },
      {
        'name': 'Estimaciones',
        'color': const Color(0xFF4CAF50), // Verde para estimaciones
        'icon': Icons.analytics,
        'subcategories': [
          {
            'name': 'Estimaciones. Rendimientos Packing',
            'description': 'Configuración de estimaciones de rendimientos para packing',
            'icon': Icons.inventory,
            'parameters': ['Rendimientos por Packing', 'Parámetros de Calidad', 'Estimaciones de Producción'],
          },
          {
            'name': 'Frutos x ramilla historico',
            'description': 'Histórico de frutos por ramilla para análisis',
            'icon': Icons.history,
            'parameters': ['Datos Históricos', 'Tendencias', 'Análisis Comparativo'],
          },
          {
            'name': 'Calibres historicos',
            'description': 'Histórico de calibres para análisis de calidad',
            'icon': Icons.analytics,
            'parameters': ['Calibres Históricos', 'Distribución de Tamaños', 'Tendencias de Calidad'],
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
            color: (widget.category['color'] as Color).withOpacity(0.1),
            border: Border.all(
              color: (widget.category['color'] as Color).withOpacity(0.3),
              width: 1,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (widget.category['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.category['icon'] as IconData,
                      color: (widget.category['color'] as Color),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.category['name'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: (widget.category['color'] as Color),
                      ),
                    ),
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
