import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/navigation_service.dart';
import '../config/app_routes.dart';
import 'pautas_formulario_dinamico_screen.dart';
import 'pautas_crear_nueva_screen.dart';

class PautasGestionScreen extends StatefulWidget {
  const PautasGestionScreen({super.key});

  @override
  State<PautasGestionScreen> createState() => _PautasGestionScreenState();
}

class _PautasGestionScreenState extends State<PautasGestionScreen> {
  List<Map<String, dynamic>> _pautas = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _pautaDetalle;
  String? _pautaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarPautas();
  }

  Future<void> _cargarPautas() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/pautas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _pautas = List<Map<String, dynamic>>.from(data['data']['pautas']);
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Error al cargar pautas';
          });
        }
      } else {
        setState(() {
          _error = 'Error ${response.statusCode}: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error al cargar pautas: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarDetallePauta(String pautaId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pautas/pautas/$pautaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _pautaDetalle = data['data'];
            _pautaSeleccionada = pautaId;
          });
        }
      }
    } catch (e) {
      print('Error cargando detalle de pauta: $e');
    }
  }

  Future<void> _eliminarPauta(String pautaId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/pautas/pautas/$pautaId'),
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
              content: Text(data['message'] ?? 'Pauta eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _cargarPautas();
          if (_pautaSeleccionada == pautaId) {
            setState(() {
              _pautaDetalle = null;
              _pautaSeleccionada = null;
            });
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Error al eliminar pauta'),
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
          content: Text('Error al eliminar pauta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _nuevaPauta() {
    NavigationHelper.navigateTo(
      context, 
      AppRoutes.pautasCrear,
    ).then((_) {
      // Recargar pautas cuando regrese de crear una nueva
      _cargarPautas();
    });
  }

  Widget _buildListaPautas() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error al cargar pautas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarPautas,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_pautas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay pautas registradas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera pauta usando el botón de arriba',
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
      itemCount: _pautas.length,
      itemBuilder: (context, index) {
        final pauta = _pautas[index];
        final isSelected = _pautaSeleccionada == pauta['id'];
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          elevation: isSelected ? 4 : 1,
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.description,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(
              '${pauta['nombre_labor']} - ${pauta['nombre_especie']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${pauta['nombre_temporada']} - ${pauta['nombre_cuartel']}'),
                Text(
                  '${pauta['fecha']} ${pauta['hora_registro']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.visibility,
                    color: isSelected ? AppTheme.primaryColor : Colors.blue,
                  ),
                  onPressed: () => _cargarDetallePauta(pauta['id']),
                  tooltip: 'Ver detalles',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar Pauta'),
                        content: Text('¿Estás seguro de que quieres eliminar esta pauta?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _eliminarPauta(pauta['id']);
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  tooltip: 'Eliminar pauta',
                ),
              ],
            ),
            onTap: () => _cargarDetallePauta(pauta['id']),
          ),
        );
      },
    );
  }

  Widget _buildDetallePauta() {
    if (_pautaDetalle == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Selecciona una pauta',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Haz clic en una pauta para ver sus detalles',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final pauta = _pautaDetalle!['pauta'];
    final detalles = _pautaDetalle!['detalles'] as List<dynamic>;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Detalles de la Pauta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Información general
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Labor', pauta['nombre_labor']),
                  _buildInfoRow('Especie', pauta['nombre_especie']),
                  _buildInfoRow('Temporada', pauta['nombre_temporada']),
                  _buildInfoRow('Cuartel', pauta['nombre_cuartel']),
                  _buildInfoRow('Fecha', '${pauta['fecha']} ${pauta['hora_registro']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Detalles de atributos
            Text(
              'Atributos Medidos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            if (detalles.isEmpty)
              Text(
                'No hay detalles registrados',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...detalles.map((detalle) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      detalle['valor_atributo'].toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  title: Text(
                    detalle['nombre_atributo'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: detalle['nombre_tipo_planta'] != null
                      ? Text('Tipo: ${detalle['nombre_tipo_planta']}')
                      : null,
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pautas'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        leading: NavigationHelper.buildBackButton(context),
        actions: [
          NavigationHelper.buildHomeButton(context),
        ],
      ),
      body: Column(
        children: [
          // Botón para nueva pauta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _nuevaPauta,
              icon: const Icon(Icons.add),
              label: const Text('Nueva Pauta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Row(
              children: [
                // Lista de pautas
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(Icons.list, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Pautas Registradas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildListaPautas()),
                    ],
                  ),
                ),
                
                // Detalle de pauta
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Detalles',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildDetallePauta()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}