import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class HistorialCuartelScreen extends StatefulWidget {
  final Map<String, dynamic> cuartel;

  const HistorialCuartelScreen({
    super.key,
    required this.cuartel,
  });

  @override
  State<HistorialCuartelScreen> createState() => _HistorialCuartelScreenState();
}

class _HistorialCuartelScreenState extends State<HistorialCuartelScreen> {
  List<Map<String, dynamic>> _historial = [];
  Map<String, dynamic>? _estadisticas;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estimaciones/historial-cuartel/${widget.cuartel['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        // Datos disponibles
        setState(() {
          _historial = List<Map<String, dynamic>>.from(data['data']['historial']);
          _estadisticas = data['data']['estadisticas'];
          _errorMessage = null;
        });
      } else if (response.statusCode == 404 && data['success'] == false) {
        // Sin datos disponibles
        setState(() {
          _historial = [];
          _estadisticas = null;
          _errorMessage = data['message'] ?? 'No hay datos disponibles';
        });
      } else {
        // Error del servidor
        throw Exception(data['message'] ?? 'Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar el historial: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'N/A';
    final date = DateTime.tryParse(fecha);
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Historial de ${widget.cuartel['nombre']}',
      currentRoute: '/estimaciones',
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _historial.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGreen.withOpacity(0.1),
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
              color: AppTheme.mediumGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: AppTheme.mediumGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.cuartel['nombre'] ?? 'Cuartel ${widget.cuartel['id']}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mediumGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.cuartel['descripcion'] ?? 'Sin descripción',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (_estadisticas != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.mediumGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_estadisticas!['total_estimaciones'] ?? 0} estimaciones',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando historial...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _cargarHistorial,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mediumGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay estimaciones registradas',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las estimaciones aparecerán aquí cuando se registren datos para este cuartel',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crear nueva estimación - Funcionalidad en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Nueva Estimación'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mediumGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (_estadisticas != null) _buildEstadisticas(),
          _buildHistorialTable(),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas del Cuartel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.mediumGreen,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Estimaciones',
                  '${_estadisticas!['total_estimaciones'] ?? 0}',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Cajas',
                  '${_estadisticas!['total_cajas'] ?? 0}',
                  Icons.inventory,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Kg Embalaje',
                  '${_estadisticas!['total_kg_embalaje'] ?? 0} kg',
                  Icons.scale,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Kg Industria',
                  '${_estadisticas!['total_kg_industria'] ?? 0} kg',
                  Icons.factory,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Promedio Cajas',
                  '${_estadisticas!['promedio_cajas'] ?? 0}',
                  Icons.trending_up,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Última Estimación',
                  _formatearFecha(_estadisticas!['ultima_estimacion']),
                  Icons.schedule,
                  Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialTable() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Historial de Estimaciones (${_historial.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mediumGreen,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Crear nueva estimación - Funcionalidad en desarrollo'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva Estimación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mediumGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          // Tabla
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 16,
              columns: const [
                DataColumn(
                  label: Text('ID'),
                  numeric: false,
                ),
                DataColumn(
                  label: Text('Tipo'),
                  numeric: false,
                ),
                DataColumn(
                  label: Text('Fecha'),
                  numeric: false,
                ),
                DataColumn(
                  label: Text('Usuario'),
                  numeric: false,
                ),
                DataColumn(
                  label: Text('Cajas'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Kg Embalaje'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Kg Industria'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('Acciones'),
                  numeric: false,
                ),
              ],
              rows: _historial.map((estimacion) {
                final fecha = DateTime.tryParse(estimacion['hora_registro'] ?? '');
                final fechaFormateada = fecha != null
                    ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                    : 'N/A';

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        estimacion['id'] ?? 'N/A',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          estimacion['nombre_tipo_estimacion'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mediumGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        fechaFormateada,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${estimacion['nombre_usuario'] ?? ''} ${estimacion['apellido_usuario'] ?? ''}'.trim(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${estimacion['embalaje_cajas'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${estimacion['embalaje_kg'] ?? 0} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${estimacion['industria_kg'] ?? 0} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _verDetalle(estimacion),
                            icon: const Icon(Icons.visibility, size: 18),
                            tooltip: 'Ver detalle',
                            color: AppTheme.mediumGreen,
                          ),
                          IconButton(
                            onPressed: () => _editarEstimacion(estimacion),
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Editar',
                            color: Colors.blue,
                          ),
                          IconButton(
                            onPressed: () => _eliminarEstimacion(estimacion),
                            icon: const Icon(Icons.delete, size: 18),
                            tooltip: 'Eliminar',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _verDetalle(Map<String, dynamic> estimacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle de Estimación ${estimacion['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('ID:', estimacion['id']),
            _buildDetailRow('Tipo:', estimacion['nombre_tipo_estimacion']),
            _buildDetailRow('Fecha:', _formatearFecha(estimacion['hora_registro'])),
            _buildDetailRow('Usuario:', '${estimacion['nombre_usuario']} ${estimacion['apellido_usuario']}'),
            _buildDetailRow('Cajas:', '${estimacion['embalaje_cajas'] ?? 0}'),
            _buildDetailRow('Kg Embalaje:', '${estimacion['embalaje_kg'] ?? 0} kg'),
            _buildDetailRow('Kg Industria:', '${estimacion['industria_kg'] ?? 0} kg'),
          ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _editarEstimacion(Map<String, dynamic> estimacion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar estimación ${estimacion['id']} - Funcionalidad en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _eliminarEstimacion(Map<String, dynamic> estimacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la estimación ${estimacion['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Eliminar estimación ${estimacion['id']} - Funcionalidad en desarrollo'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
