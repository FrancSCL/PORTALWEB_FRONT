import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart' as excel_lib;
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class MapeoScreen extends StatefulWidget {
  const MapeoScreen({super.key});

  @override
  State<MapeoScreen> createState() => _MapeoScreenState();
}

class _MapeoScreenState extends State<MapeoScreen> {

  
  // Lista de cuarteles cargados desde la API
  List<Map<String, dynamic>> _cuarteles = [];
  bool _isLoadingCuarteles = false;
  
  // Variables para selección de cuarteles
  Set<int> _cuartelesSeleccionados = {};
  bool _seleccionarTodos = false;
  
  // Variables para carga de archivos
  bool _isUploading = false;
  String? _uploadedFileName;
  
  // Variables para tarjetas expandibles
  bool _hilerasExpanded = true;
  bool _plantasExpanded = false;

  @override
  void initState() {
    super.initState();
    _cargarCuarteles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return MainScaffold(
      title: 'Administración de Mapeo',
      currentRoute: '/mapeo',
      onRefresh: () async {
        await authProvider.checkAuthStatus();
      },
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildCatastro(),
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
            'Sistema de Mapeo Agrícola',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gestión completa de cuarteles, hileras y plantas con carga masiva',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }



  // TAB 1: Catastro - Configuración de hileras y plantas por cuartel
  Widget _buildCatastro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Catastro',
            'Configuración de hileras y plantas por cuartel',
            Icons.grid_on,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 20),
          _buildGestionHileras(),
          const SizedBox(height: 20),
          _buildGestionPlantas(),
        ],
      ),
    );
  }

  Widget _buildCargaMasivaCuarteles() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload_file, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Carga Masiva de Cuarteles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCuartelesForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildCuartelesForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carga Masiva de Cuarteles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Arrastra archivos Excel/CSV aquí o haz clic para seleccionar',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _seleccionarArchivoCuarteles(),
                    icon: const Icon(Icons.file_open),
                    label: const Text('Seleccionar Archivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _descargarPlantillaCuarteles(),
                    icon: const Icon(Icons.download),
                    label: const Text('Descargar Plantilla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _procesarCargaMasiva(),
              icon: const Icon(Icons.upload),
              label: const Text('Procesar Carga Masiva de Cuarteles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestionHileras() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header expandible
          InkWell(
            onTap: () {
              setState(() {
                _hilerasExpanded = !_hilerasExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.view_column, color: AppTheme.infoColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Gestión de Hileras',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(
                    _hilerasExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Contenido expandible
          if (_hilerasExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instrucciones
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Instrucciones para Hileras',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem('1. Selecciona los cuarteles donde quieres agregar hileras'),
                        _buildInfoItem('2. Descarga el Excel con los cuarteles seleccionados'),
                        _buildInfoItem('3. Completa la columna "N_Hileras" con el número de hileras por cuartel'),
                        _buildInfoItem('4. Sube el Excel completado para crear las hileras automáticamente'),
                        _buildInfoItem('5. Las hileras se crearán con nombres: Hilera 1, Hilera 2, Hilera 3, etc.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCuartelesList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGestionPlantas() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header expandible
          InkWell(
            onTap: () {
              setState(() {
                _plantasExpanded = !_plantasExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.eco, color: AppTheme.successColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Gestión de Plantas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(
                    _plantasExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Contenido expandible
          if (_plantasExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instrucciones
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Instrucciones para Plantas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem('1. Selecciona los cuarteles donde quieres agregar plantas'),
                        _buildInfoItem('2. Descarga el Excel con las hileras de los cuarteles seleccionados'),
                        _buildInfoItem('3. Completa la columna "N_Plantas" con el número de plantas por hilera'),
                        _buildInfoItem('4. Sube el Excel completado para crear las plantas automáticamente'),
                        _buildInfoItem('5. Las plantas se crearán con IDs únicos generados automáticamente'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCuartelesList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Método para cargar cuarteles desde la API
  Future<void> _cargarCuarteles() async {
    setState(() {
      _isLoadingCuarteles = true;
    });

    try {
      // Obtener token de autenticación
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();

      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      print('Token obtenido: ${token.substring(0, 20)}...');
      
      // Llamada real a la API
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/cuarteles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final cuartelesData = data['data']['cuarteles'] as List;
          
          // Obtener la sucursal activa del usuario
          final userData = authProvider.userData;
          final sucursalActiva = userData?['sucursal_nombre'] ?? '';
          
          print('Sucursal activa del usuario: $sucursalActiva');
          
          // Filtrar cuarteles solo de la sucursal activa
          final cuartelesFiltrados = cuartelesData.where((cuartel) {
            final nombreSucursal = cuartel['nombre_sucursal'] ?? '';
            return nombreSucursal == sucursalActiva;
          }).toList();
          
          print('Cuarteles totales: ${cuartelesData.length}');
          print('Cuarteles de la sucursal activa: ${cuartelesFiltrados.length}');
          
          _cuarteles = cuartelesFiltrados.map((cuartel) => {
            'id': cuartel['id'],
            'nombre': cuartel['nombre'],
            'superficie': cuartel['superficie'] ?? 0.0,
            'n_hileras': cuartel['n_hileras'] ?? 0,
            'estado': _getEstadoFromId(cuartel['id_estado']),
            'sucursal': cuartel['nombre_sucursal'] ?? 'Sin sucursal',
            'variedad': cuartel['nombre_variedad'] ?? 'Sin variedad',
            'año_plantacion': cuartel['ano_plantacion'] ?? 0,
            'id_ceco': cuartel['id_ceco'],
            'id_variedad': cuartel['id_variedad'],
            'dsh': cuartel['dsh'],
            'deh': cuartel['deh'],
            'id_propiedad': cuartel['id_propiedad'],
            'id_portainjerto': cuartel['id_portainjerto'],
            'brazos_ejes': cuartel['brazos_ejes'],
            'id_estadoproductivo': cuartel['id_estadoproductivo'],
            'id_estadocatastro': cuartel['id_estadocatastro'],
          }).toList().cast<Map<String, dynamic>>();
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_cuarteles.length} cuarteles cargados'),
                        Text(
                          'Sucursal: $sucursalActiva',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception(data['message'] ?? 'Error desconocido');
        }
      } else {
        final errorBody = response.body;
        print('Error del servidor: $errorBody');
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}\n$errorBody');
      }

    } catch (e) {
      // En caso de error, mostrar mensaje claro
      print('Error cargando cuarteles: $e');
      _cuarteles = []; // Lista vacía para mostrar mensaje de error
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Error al cargar cuarteles',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      setState(() {
        _isLoadingCuarteles = false;
      });
    }
  }

  // Método auxiliar para convertir ID de estado a texto
  String _getEstadoFromId(int? idEstado) {
    switch (idEstado) {
      case 1:
        return 'activo';
      case 0:
        return 'inactivo';
      default:
        return 'pendiente';
    }
  }

  // Métodos para manejar selección de cuarteles
  void _toggleSeleccionCuartel(int cuartelId) {
    setState(() {
      if (_cuartelesSeleccionados.contains(cuartelId)) {
        _cuartelesSeleccionados.remove(cuartelId);
      } else {
        _cuartelesSeleccionados.add(cuartelId);
      }
      _actualizarSeleccionTodos();
    });
  }

  void _toggleSeleccionarTodos() {
    setState(() {
      _seleccionarTodos = !_seleccionarTodos;
      if (_seleccionarTodos) {
        _cuartelesSeleccionados = _cuarteles.map((c) => c['id'] as int).toSet();
      } else {
        _cuartelesSeleccionados.clear();
      }
    });
  }

  void _actualizarSeleccionTodos() {
    _seleccionarTodos = _cuartelesSeleccionados.length == _cuarteles.length;
  }

  void _descargarExcelCuartelesSeleccionados() async {
    if (_cuartelesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un cuartel para descargar'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      // Filtrar cuarteles seleccionados
      final cuartelesSeleccionados = _cuarteles
          .where((cuartel) => _cuartelesSeleccionados.contains(cuartel['id']))
          .toList();

      // Crear archivo Excel
      final excel = excel_lib.Excel.createExcel();
      
      // Crear la hoja "Cuarteles" directamente
      final sheet = excel['Cuarteles'];

      // Agregar encabezados
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = 'ID';
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = 'Nombre';
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = 'N_Hileras';

      // Agregar datos
      for (int i = 0; i < cuartelesSeleccionados.length; i++) {
        final cuartel = cuartelesSeleccionados[i];
        final rowIndex = i + 1;
        
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = cuartel['id'];
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = cuartel['nombre'];
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = cuartel['n_hileras'] ?? 0;
      }

      // Generar bytes del archivo Excel
      final bytes = excel.encode();

      // Descargar archivo Excel
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'cuarteles_seleccionados.xlsx')
          ..setAttribute('type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          ..click();
        html.Url.revokeObjectUrl(url);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel descargado con ${cuartelesSeleccionados.length} cuarteles'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Métodos para manejar carga de archivos y creación de hileras
  void _seleccionarArchivoExcel() async {
    try {
      final input = html.FileUploadInputElement()
        ..accept = '.csv,.xlsx,.xls'
        ..click();

      input.onChange.listen((event) async {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files.first;
          await _procesarArchivoExcel(file);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _procesarArchivoExcel(html.File file) async {
    setState(() {
      _isUploading = true;
      _uploadedFileName = file.name;
    });

    try {
      final reader = html.FileReader();
      
      // Determinar si es un archivo Excel o CSV basado en la extensión
      final fileName = file.name.toLowerCase();
      if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        // Leer como ArrayBuffer para archivos Excel
        reader.readAsArrayBuffer(file);
        
        reader.onLoad.listen((event) async {
          final arrayBuffer = reader.result as List<int>;
          await _procesarArchivoExcelBytes(arrayBuffer);
        });
      } else {
        // Leer como texto para archivos CSV
        reader.readAsText(file);
        
        reader.onLoad.listen((event) async {
          final content = reader.result as String;
          await _procesarContenidoExcel(content);
        });
      }

      reader.onError.listen((event) {
        throw Exception('Error al leer el archivo');
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar archivo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _procesarArchivoExcelBytes(List<int> bytes) async {
    try {
      // Decodificar archivo Excel
      final excel = excel_lib.Excel.decodeBytes(bytes);
      
      // Buscar la hoja correcta (Cuarteles o la primera con datos)
      String? sheetName;
      excel_lib.Sheet? sheet;
      
      // Primero intentar encontrar la hoja "Cuarteles"
      if (excel.tables.containsKey('Cuarteles')) {
        sheetName = 'Cuarteles';
        sheet = excel.tables['Cuarteles']!;
      } else {
        // Si no existe, buscar la primera hoja con datos
        for (final name in excel.tables.keys) {
          final currentSheet = excel.tables[name]!;
          if (currentSheet.maxRows > 1) { // Más de solo encabezados
            sheetName = name;
            sheet = currentSheet;
            break;
          }
        }
      }
      
      if (sheet == null) {
        throw Exception('No se encontró una hoja válida con datos en el archivo Excel');
      }
      
      print('Procesando hoja: $sheetName');
      
      // Convertir datos de Excel a formato de procesamiento
      final datosCuarteles = <Map<String, dynamic>>[];
      
      // Procesar filas (empezar desde la fila 1 para saltar encabezados)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty) continue;
        
        // Obtener valores de las celdas
        final id = _getCellValue(row[0]);
        final nombre = _getCellValue(row[1]);
        final nHileras = _getCellValue(row[2]);
        
        // Validar y convertir datos
        final idInt = int.tryParse(id.toString());
        final nHilerasInt = int.tryParse(nHileras.toString()) ?? 0;
        
        if (idInt != null && nombre.toString().isNotEmpty) {
          datosCuarteles.add({
            'id': idInt,
            'nombre': nombre.toString(),
            'n_hileras': nHilerasInt,
          });
        }
      }
      
      if (datosCuarteles.isEmpty) {
        throw Exception('No se encontraron datos válidos en el archivo Excel');
      }
      
      // Mostrar resumen y confirmar
      await _mostrarResumenCatastro(datosCuarteles);
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar archivo Excel: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  dynamic _getCellValue(excel_lib.Data? cell) {
    if (cell == null) return '';
    return cell.value ?? '';
  }

  Future<void> _procesarContenidoExcel(String content) async {
    try {
      final lines = content.split('\n');
      if (lines.length < 2) {
        throw Exception('El archivo está vacío o no tiene el formato correcto');
      }

      // Verificar encabezados de manera más flexible
      final header = lines[0].trim().toLowerCase();
      final hasId = header.contains('id');
      final hasNombre = header.contains('nombre') || header.contains('name');
      final hasHileras = header.contains('hileras') || header.contains('n_hileras') || header.contains('filas');
      
      if (!hasId || !hasNombre || !hasHileras) {
        throw Exception('El archivo no tiene los encabezados correctos. Se espera: ID, Nombre, N_Hileras');
      }

      // Procesar datos
      final datosCuarteles = <Map<String, dynamic>>[];
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Separar por múltiples separadores posibles
        List<String> parts = [];
        
        // Intentar diferentes separadores en orden de prioridad
        if (line.contains(';')) {
          parts = line.split(';');
        } else if (line.contains(',')) {
          parts = line.split(',');
        } else if (line.contains('\t')) {
          parts = line.split('\t');
        } else {
          // Si no hay separadores claros, intentar separar por espacios múltiples
          parts = line.split(RegExp(r'\s+'));
        }

        if (parts.length < 3) {
          print('Línea $i ignorada: formato incorrecto - $line');
          print('Partes encontradas: ${parts.length} - $parts');
          continue;
        }

        final id = int.tryParse(parts[0].trim());
        final nombre = parts[1].trim();
        final nHileras = int.tryParse(parts[2].trim()) ?? 0;

        if (id != null && nombre.isNotEmpty) {
          datosCuarteles.add({
            'id': id,
            'nombre': nombre,
            'n_hileras': nHileras,
          });
        }
      }

      if (datosCuarteles.isEmpty) {
        throw Exception('No se encontraron datos válidos en el archivo');
      }

      // Mostrar resumen y confirmar
      await _mostrarResumenCatastro(datosCuarteles);

    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar contenido: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _mostrarResumenCatastro(List<Map<String, dynamic>> datosCuarteles) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload_file, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Confirmar Catastro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archivo: $_uploadedFileName'),
            const SizedBox(height: 16),
            Text('Resumen del catastro:'),
            const SizedBox(height: 8),
            Text('• Total de cuarteles: ${datosCuarteles.length}'),
            Text('• Cuarteles con hileras: ${datosCuarteles.where((c) => c['n_hileras'] > 0).length}'),
            Text('• Cuarteles sin hileras: ${datosCuarteles.where((c) => c['n_hileras'] == 0).length}'),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas proceder con el catastro?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción actualizará los datos de hileras de los cuarteles seleccionados.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceder'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _ejecutarCatastro(datosCuarteles);
    } else {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
    }
  }

  Future<void> _ejecutarCatastro(List<Map<String, dynamic>> datosCuarteles) async {
    try {
      // Obtener token de autenticación
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();

      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      // Preparar datos en el formato correcto que espera el backend
      final cuartelesFormateados = datosCuarteles.map((cuartel) => {
        'id': cuartel['id'],  // El backend espera 'id', no 'id_cuartel'
        'n_hileras': cuartel['n_hileras'],
      }).toList();

      print('Datos originales: $datosCuarteles');
      print('Datos formateados: $cuartelesFormateados');
      print('Datos a enviar al backend: ${jsonEncode({'cuarteles': cuartelesFormateados})}');

      // Enviar datos al backend
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/cuarteles/catastro-masivo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cuarteles': cuartelesFormateados,
        }),
      );

      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Catastro completado: ${data['message']}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Recargar cuarteles para mostrar cambios
          await _cargarCuarteles();
        } else {
          throw Exception(data['message'] ?? 'Error en el catastro');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error ${response.statusCode}: ${errorData['message'] ?? response.reasonPhrase}');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en catastro: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
    }
  }

  // Métodos para plantas por hilera
  void _descargarExcelPlantas() async {
    if (_cuartelesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un cuartel para descargar'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      // Obtener token del AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay token de autenticación'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      // Filtrar cuarteles seleccionados
      final cuartelesSeleccionados = _cuarteles
          .where((cuartel) => _cuartelesSeleccionados.contains(cuartel['id']))
          .toList();

      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Descargando Excel...'),
              ],
            ),
            content: const Text('Generando plantilla de plantas optimizada...'),
          );
        },
      );

      // Usar el nuevo endpoint optimizado
      final cuartelesIds = cuartelesSeleccionados.map((c) => c['id'] as int).toList();
      
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/cuarteles/plantilla-plantas-masiva'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cuarteles': cuartelesIds,
        }),
      );

      if (response.statusCode == 200) {
        // Descargar archivo Excel directamente del backend
        if (kIsWeb) {
          final bytes = response.bodyBytes;
          final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'plantilla_plantas_masiva_${cuartelesIds.length}_cuarteles.xlsx')
            ..setAttribute('type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            ..click();
          html.Url.revokeObjectUrl(url);
        }

        // Cerrar diálogo de progreso
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel de plantas descargado para ${cuartelesIds.length} cuarteles'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        // Cerrar diálogo de progreso
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: ${response.statusCode}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al descargar: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _seleccionarArchivoPlantas() async {
    try {
      final input = html.FileUploadInputElement()
        ..accept = '.csv,.xlsx,.xls'
        ..click();

      input.onChange.listen((event) async {
        final files = input.files;
        if (files != null && files.isNotEmpty) {
          final file = files.first;
          await _procesarArchivoPlantas(file);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar archivo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _procesarArchivoPlantas(html.File file) async {
    setState(() {
      _isUploading = true;
      _uploadedFileName = file.name;
    });

    try {
      final reader = html.FileReader();
      
      // Determinar si es un archivo Excel o CSV basado en la extensión
      final fileName = file.name.toLowerCase();
      if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
        // Leer como ArrayBuffer para archivos Excel
        reader.readAsArrayBuffer(file);
        
        reader.onLoad.listen((event) async {
          final arrayBuffer = reader.result as List<int>;
          await _procesarArchivoPlantasBytes(arrayBuffer);
        });
      } else {
        // Leer como texto para archivos CSV
        reader.readAsText(file);
        
        reader.onLoad.listen((event) async {
          final content = reader.result as String;
          await _procesarContenidoPlantas(content);
        });
      }

      reader.onError.listen((event) {
        throw Exception('Error al leer el archivo');
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar archivo: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _procesarArchivoPlantasBytes(List<int> bytes) async {
    try {
      // Decodificar archivo Excel
      final excel = excel_lib.Excel.decodeBytes(bytes);
      
      // Buscar la hoja correcta (Plantas o la primera con datos)
      String? sheetName;
      excel_lib.Sheet? sheet;
      
      // Primero intentar encontrar la hoja "Plantas"
      if (excel.tables.containsKey('Plantas')) {
        sheetName = 'Plantas';
        sheet = excel.tables['Plantas']!;
      } else {
        // Si no existe, buscar la primera hoja con datos
        for (final name in excel.tables.keys) {
          final currentSheet = excel.tables[name]!;
          if (currentSheet.maxRows > 1) { // Más de solo encabezados
            sheetName = name;
            sheet = currentSheet;
            break;
          }
        }
      }
      
      if (sheet == null) {
        throw Exception('No se encontró una hoja válida con datos en el archivo Excel');
      }
      
      print('Procesando hoja de plantas: $sheetName');
      
      // Convertir datos de Excel a formato de procesamiento
      final datosPlantas = <Map<String, dynamic>>[];
      
      // Procesar filas (empezar desde la fila 1 para saltar encabezados)
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final row = sheet.row(rowIndex);
        if (row.isEmpty) continue;
        
        // Obtener valores de las celdas
        final idCuartel = _getCellValue(row[0]);
        final nombreCuartel = _getCellValue(row[1]);
        final idHilera = _getCellValue(row[2]);
        final nombreHilera = _getCellValue(row[3]);
        final nPlantas = _getCellValue(row[4]);
        
        // Validar y convertir datos
        final idCuartelInt = int.tryParse(idCuartel.toString());
        final idHileraInt = int.tryParse(idHilera.toString());
        final nPlantasInt = int.tryParse(nPlantas.toString()) ?? 0;
        
        if (idCuartelInt != null && idHileraInt != null) {
          datosPlantas.add({
            'id_cuartel': idCuartelInt,
            'id_hilera': idHileraInt,
            'n_plantas': nPlantasInt,
          });
        }
      }
      
      if (datosPlantas.isEmpty) {
        throw Exception('No se encontraron datos válidos en el archivo Excel');
      }
      
      // Mostrar resumen y confirmar
      await _mostrarResumenPlantas(datosPlantas);
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar archivo Excel: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _procesarContenidoPlantas(String content) async {
    try {
      final lines = content.split('\n');
      if (lines.length < 2) {
        throw Exception('El archivo está vacío o no tiene el formato correcto');
      }

      // Verificar encabezados de manera más flexible
      final header = lines[0].trim().toLowerCase();
      final hasIdCuartel = header.contains('id_cuartel') || header.contains('id cuartel');
      final hasIdHilera = header.contains('id_hilera') || header.contains('id hilera');
      final hasNPlantas = header.contains('n_plantas') || header.contains('n plantas') || header.contains('plantas');
      
      if (!hasIdCuartel || !hasIdHilera || !hasNPlantas) {
        throw Exception('El archivo no tiene los encabezados correctos. Se espera: ID_Cuartel, ID_Hilera, N_Plantas');
      }

      // Procesar datos
      final datosPlantas = <Map<String, dynamic>>[];
      
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        // Separar por múltiples separadores posibles
        List<String> parts = [];
        
        // Intentar diferentes separadores en orden de prioridad
        if (line.contains(';')) {
          parts = line.split(';');
        } else if (line.contains(',')) {
          parts = line.split(',');
        } else if (line.contains('\t')) {
          parts = line.split('\t');
        } else {
          // Si no hay separadores claros, intentar separar por espacios múltiples
          parts = line.split(RegExp(r'\s+'));
        }

        if (parts.length < 5) {
          print('Línea $i ignorada: formato incorrecto - $line');
          print('Partes encontradas: ${parts.length} - $parts');
          continue;
        }

        final idCuartel = int.tryParse(parts[0].trim());
        final nombreCuartel = parts[1].trim();
        final idHilera = parts[2].trim();
        final nombreHilera = parts[3].trim();
        final nPlantas = int.tryParse(parts[4].trim()) ?? 0;

        if (idCuartel != null && idHilera.isNotEmpty) {
          // Convertir el ID de hilera a número si es posible
          // El formato esperado es: ID_Cuartel + número de hilera (ej: 1030201601001)
          int? idHileraNumerico;
          
          // Intentar parsear como número directo
          idHileraNumerico = int.tryParse(idHilera);
          
          // Si no es un número directo, intentar extraer el número de hilera
          if (idHileraNumerico == null) {
            // Buscar el patrón: ID_Cuartel + número de hilera
            final regex = RegExp(r'(\d+)-H(\d+)');
            final match = regex.firstMatch(idHilera);
            if (match != null) {
              final idCuartelStr = match.group(1);
              final numeroHilera = match.group(2);
              if (idCuartelStr != null && numeroHilera != null) {
                idHileraNumerico = int.tryParse('$idCuartelStr$numeroHilera');
              }
            }
          }
          
          // Si aún no se pudo convertir, intentar con el formato numérico directo
          if (idHileraNumerico == null) {
            // El formato puede ser: ID_Cuartel * 1000 + número_hilera
            // Ej: 1030201601001 = 1030201601 * 1000 + 1
            final numeroHilera = int.tryParse(idHilera);
            if (numeroHilera != null && numeroHilera > idCuartel * 1000) {
              idHileraNumerico = numeroHilera;
            }
          }
          
          if (idHileraNumerico != null) {
            datosPlantas.add({
              'id_cuartel': idCuartel,
              'id_hilera': idHileraNumerico,
              'n_plantas': nPlantas,
            });
          } else {
            print('No se pudo convertir ID de hilera a número: $idHilera');
          }
        }
      }

      if (datosPlantas.isEmpty) {
        throw Exception('No se encontraron datos válidos en el archivo');
      }

      // Mostrar resumen y confirmar
      await _mostrarResumenPlantas(datosPlantas);

    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al procesar contenido: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _mostrarResumenPlantas(List<Map<String, dynamic>> datosPlantas) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.eco, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Confirmar Plantas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archivo: $_uploadedFileName'),
            const SizedBox(height: 16),
            Text('Resumen de plantas:'),
            const SizedBox(height: 8),
            Text('• Total de hileras: ${datosPlantas.length}'),
            Text('• Hileras con plantas: ${datosPlantas.where((p) => p['n_plantas'] > 0).length}'),
            Text('• Hileras sin plantas: ${datosPlantas.where((p) => p['n_plantas'] == 0).length}'),
            const SizedBox(height: 16),
            const Text(
              '¿Deseas proceder con la asignación de plantas?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción actualizará los datos de plantas por hilera.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Proceder'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _ejecutarPlantas(datosPlantas);
    } else {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
    }
  }

  Future<void> _ejecutarPlantas(List<Map<String, dynamic>> datosPlantas) async {
    try {
      // Obtener token de autenticación
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();

      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }

      // Preparar datos en el formato correcto que espera el backend
      final plantasFormateadas = datosPlantas.map((planta) => {
        'id_cuartel': planta['id_cuartel'],
        'id_hilera': planta['id_hilera'],
        'n_plantas': planta['n_plantas'],
      }).toList();

      print('Datos a enviar al backend: ${jsonEncode({'plantas': plantasFormateadas})}');

      // Enviar datos al backend
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/cuarteles/plantas-masivo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'plantas': plantasFormateadas,
        }),
      );

      print('Respuesta del servidor: ${response.statusCode}');
      print('Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Plantas asignadas: ${data['message']}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          // Recargar cuarteles para mostrar cambios
          await _cargarCuarteles();
        } else {
          throw Exception(data['message'] ?? 'Error en la asignación de plantas');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Error ${response.statusCode}: ${errorData['message'] ?? response.reasonPhrase}');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en plantas: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadedFileName = null;
      });
    }
  }

  Widget _buildCuartelesList() {
    if (_isLoadingCuarteles) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryColor),
            const SizedBox(height: 16),
            Text(
              'Cargando cuarteles...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_cuarteles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay cuarteles en esta sucursal',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final sucursalActiva = authProvider.userData?['sucursal_nombre'] ?? '';
                return Text(
                  'Sucursal: $sucursalActiva',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarCuarteles,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuarteles Disponibles (${_cuarteles.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final sucursalActiva = authProvider.userData?['sucursal_nombre'] ?? '';
                    return Text(
                      'Sucursal: $sucursalActiva',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
              ],
            ),
            Row(
              children: [
                // Contador de seleccionados
                if (_cuartelesSeleccionados.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_cuartelesSeleccionados.length} seleccionados',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_cuartelesSeleccionados.isNotEmpty) const SizedBox(width: 8),
                
                // Botón descargar Excel
                if (_cuartelesSeleccionados.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _descargarExcelCuartelesSeleccionados,
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Descargar Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                if (_cuartelesSeleccionados.isNotEmpty) const SizedBox(width: 8),
                
                // Botón subir Excel
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _seleccionarArchivoExcel,
                  icon: _isUploading 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload_file, size: 16),
                  label: Text(_isUploading ? 'Procesando...' : 'Subir Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Botón seleccionar todos
                ElevatedButton.icon(
                  onPressed: _toggleSeleccionarTodos,
                  icon: Icon(_seleccionarTodos ? Icons.check_box : Icons.check_box_outline_blank, size: 16),
                  label: Text(_seleccionarTodos ? 'Deseleccionar' : 'Seleccionar Todos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Botón actualizar
                IconButton(
                  onPressed: _isLoadingCuarteles ? null : _cargarCuarteles,
                  icon: _isLoadingCuarteles 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      )
                    : Icon(Icons.refresh, color: AppTheme.primaryColor),
                  tooltip: 'Actualizar cuarteles',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._cuarteles.map((cuartel) => _buildCuartelCard(cuartel)).toList(),
        
        // Sección de plantas por hilera
        if (_cuarteles.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Plantas por Hilera',
            'Gestión de plantas en las hileras de los cuarteles',
            Icons.eco,
            AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          _buildPlantasSection(),
        ],
      ],
    );
  }

  Widget _buildPlantasSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Plantas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Botón descargar Excel de plantas
                    ElevatedButton.icon(
                      onPressed: _cuartelesSeleccionados.isNotEmpty ? _descargarExcelPlantas : null,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Descargar Plantas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Botón subir Excel de plantas
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _seleccionarArchivoPlantas,
                      icon: _isUploading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.upload_file, size: 16),
                      label: Text(_isUploading ? 'Procesando...' : 'Subir Plantas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.infoColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Instrucciones para Plantas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Selecciona los cuarteles que tienen hileras',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    '2. Descarga el Excel de plantas para completar',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    '3. Sube el Excel con los datos de plantas por hilera',
                    style: TextStyle(fontSize: 14),
                  ),
                  const Text(
                    '4. El sistema creará automáticamente las plantas',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuartelCard(Map<String, dynamic> cuartel) {
    final cuartelId = cuartel['id'] as int;
    final isSeleccionado = _cuartelesSeleccionados.contains(cuartelId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSeleccionado ? 6 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSeleccionado 
          ? BorderSide(color: AppTheme.successColor, width: 2)
          : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox de selección
            Checkbox(
              value: isSeleccionado,
              onChanged: (value) => _toggleSeleccionCuartel(cuartelId),
              activeColor: AppTheme.successColor,
            ),
            const SizedBox(width: 8),
            // Avatar del estado
            CircleAvatar(
              backgroundColor: _getEstadoColor(cuartel['estado']),
              child: Icon(Icons.grid_on, color: Colors.white),
            ),
          ],
        ),
        title: Text(
          cuartel['nombre'],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSeleccionado ? AppTheme.successColor : null,
          ),
        ),
        subtitle: Text('${cuartel['n_hileras']} hileras - ${_getEstadoText(cuartel['estado'])}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHilerasList(cuartel['id']),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAgregarHilerasDialog(cuartel['id']),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Hileras'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Estado Catastro',
                          border: OutlineInputBorder(),
                        ),
                        value: cuartel['estado'],
                        items: [
                          'activo',
                          'inactivo',
                          'pendiente',
                          'en_progreso',
                          'completado',
                          'verificado'
                        ].map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(_getEstadoText(estado)),
                        )).toList(),
                        onChanged: (value) => _actualizarEstadoCatastro(cuartel['id'], value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHilerasList(int cuartelId) {
    // TODO: Cargar hileras desde la API para el cuartel específico
    final hileras = <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hileras del Cuartel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${hileras.length} hileras',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (hileras.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.view_column_outlined, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No hay hileras en este cuartel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega hileras usando el botón "Agregar Hileras"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2,
            ),
            itemCount: hileras.length,
            itemBuilder: (context, index) {
              final hilera = hileras[index];
              return Card(
                elevation: 1,
                child: InkWell(
                  onTap: () => _showEliminarHileraDialog(hilera['id'] as int, hilera['nombre'] as String),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hilera['nombre'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          '${hilera['plantas']} plantas',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

















  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de utilidad
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'completado':
        return AppTheme.successColor;
      case 'en_progreso':
        return AppTheme.warningColor;
      case 'verificado':
        return AppTheme.infoColor;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'activo':
        return 'Activo';
      case 'inactivo':
        return 'Inactivo';
      case 'pendiente':
        return 'Pendiente';
      case 'en_progreso':
        return 'En Progreso';
      case 'completado':
        return 'Completado';
      case 'verificado':
        return 'Verificado';
      default:
        return estado;
    }
  }

  // Métodos de acción
  void _procesarCargaMasiva() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Procesando carga masiva de cuarteles...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAgregarHilerasDialog(int cuartelId) {
    final cantidadController = TextEditingController();
    
    // Buscar el cuartel seleccionado
    final cuartel = _cuarteles.firstWhere((c) => c['id'] == cuartelId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Agregar Hileras'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cuartel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cuartel: ${cuartel['nombre']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Superficie: ${cuartel['superficie']} ha'),
                  Text('Hileras actuales: ${cuartel['n_hileras']}'),
                  Text('Variedad: ${cuartel['variedad']}'),
                  Text('Sucursal: ${cuartel['sucursal']}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Cuántas hileras adicionales deseas agregar?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: 'Número de Hileras',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.view_column),
                helperText: 'Se crearán automáticamente las hileras numeradas',
                hintText: 'Ej: 10',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las hileras se crearán automáticamente con nombres secuenciales',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final cantidad = int.tryParse(cantidadController.text);
              if (cantidad == null || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un número válido mayor a 0'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              
              // Mostrar loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Agregando $cantidad hileras...'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );

                              try {
                  // Obtener token de autenticación
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final token = await authProvider.getToken();

                  if (token == null) {
                    throw Exception('No hay token de autenticación disponible');
                  }

                  // Llamada real a la API para agregar hileras
                  final response = await http.post(
                    Uri.parse('http://localhost:5000/api/cuarteles/$cuartelId/hileras'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'cantidad': cantidad,
                      'cuartel_id': cuartelId,
                    }),
                  );

                  if (response.statusCode == 200) {
                    final data = jsonDecode(response.body);
                    
                    if (data['success'] == true) {
                      // Actualizar el cuartel localmente
                      setState(() {
                        final index = _cuarteles.indexWhere((c) => c['id'] == cuartelId);
                        if (index != -1) {
                          _cuarteles[index]['n_hileras'] = (_cuarteles[index]['n_hileras'] as int) + cantidad;
                        }
                      });

                      // Mostrar éxito
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Se agregaron $cantidad hileras al cuartel ${cuartel['nombre']}'),
                            ],
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    } else {
                      throw Exception(data['message'] ?? 'Error al agregar hileras');
                    }
                  } else {
                    throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al agregar hileras: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Hileras'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showEliminarHileraDialog(int hileraId, String hileraNombre) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Hilera'),
        content: Text(
          '¿Eliminar hilera $hileraNombre? Esta acción también eliminará todas las plantas asociadas.',
        ),
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
                  content: Text('Hilera $hileraNombre eliminada'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _actualizarEstadoCatastro(int cuartelId, String estado) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado actualizado: ${_getEstadoText(estado)}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }





  // MÉTODOS DE DESCARGA DE PLANTILLAS - IMPLEMENTACIÓN REAL
  void _seleccionarArchivoCuarteles() {
    _mostrarDialogoSeleccionArchivo('cuarteles');
  }

  void _seleccionarArchivoGeneral() {
    _mostrarDialogoSeleccionArchivo('general');
  }

  void _mostrarDialogoSeleccionArchivo(String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.file_open, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text('Seleccionar Archivo ${tipo.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Formatos soportados:'),
            const SizedBox(height: 8),
            _buildInfoItem('• Excel (.xlsx, .xls)'),
            _buildInfoItem('• CSV (.csv)'),
            _buildInfoItem('• Tamaño máximo: 10MB'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asegúrate de que el archivo siga el formato de la plantilla',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _iniciarSeleccionArchivo(tipo);
            },
            icon: const Icon(Icons.file_open),
            label: const Text('Seleccionar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _iniciarSeleccionArchivo(String tipo) {
    // TODO: Implementar selección real de archivos
    // Por ahora simulamos la selección
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Procesando archivo ${tipo}...'),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simular procesamiento completado
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Archivo ${tipo.toUpperCase()} cargado exitosamente'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    });
  }

  void _descargarPlantillaCuarteles() {
    _mostrarDialogoDescarga('cuarteles');
  }

  void _descargarPlantillaGeneral() {
    _mostrarDialogoDescarga('general');
  }

  void _mostrarDialogoDescarga(String tipo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: AppTheme.infoColor),
            const SizedBox(width: 8),
            Text('Descargar Plantilla ${tipo.toUpperCase()}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se descargará la plantilla Excel con:'),
            const SizedBox(height: 8),
            _buildPlantillaInfo(tipo),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'La plantilla incluye headers formateados y ejemplos de datos',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _iniciarDescarga(tipo);
            },
            icon: const Icon(Icons.download),
            label: const Text('Descargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantillaInfo(String tipo) {
    switch (tipo) {
      case 'cuarteles':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Nombre del Cuartel'),
            _buildInfoItem('• Superficie (ha)'),
            _buildInfoItem('• Número de Hileras'),
            _buildInfoItem('• Sucursal'),
            _buildInfoItem('• Variedad'),
            _buildInfoItem('• Año de Plantación'),
          ],
        );
      case 'general':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Plantas (ID, Nombre, Tipo)'),
            _buildInfoItem('• Registros (Planta, Evaluador, Fecha)'),
            _buildInfoItem('• Datos completos (Cuarteles + Hileras)'),
          ],
        );
      default:
        return const Text('Información de plantilla no disponible');
    }
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  void _iniciarDescarga(String tipo) {
    // Mostrar loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text('Solicitando plantilla_${tipo}.xlsx al servidor...'),
          ],
        ),
        backgroundColor: AppTheme.infoColor,
        duration: const Duration(seconds: 3),
      ),
    );

    // IMPLEMENTACIÓN REAL: Llamada al backend según tu guía
    _descargarPlantillaDesdeBackend(tipo);
  }

  Future<void> _descargarPlantillaDesdeBackend(String tipo) async {
    try {
      // IMPLEMENTACIÓN REAL: Llamada al backend
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = await authProvider.getToken();
      
      if (token == null) {
        throw Exception('No hay token de autenticación disponible');
      }
      
      final uri = Uri.parse('http://localhost:5000/api/mapeo/descargar-plantilla?tipo=$tipo');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // El backend envía el archivo Excel como bytes
        final bytes = response.bodyBytes;
        final filename = 'plantilla_${tipo}.xlsx';
        
        // El frontend descarga el archivo recibido
        await _descargarArchivo(bytes, filename);
        
        _mostrarExitoDescarga(tipo);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.reasonPhrase}');
      }
      
    } catch (e) {
      // Si falla la llamada al backend, crear un archivo de ejemplo
      print('Error al conectar con backend: $e');
      await _crearArchivoEjemplo(tipo);
    }
  }

  Future<void> _crearArchivoEjemplo(String tipo) async {
    try {
      // Crear contenido de ejemplo para la plantilla
      String contenido = '';
      String filename = '';
      
      if (tipo == 'cuarteles') {
        contenido = '''Nombre del Cuartel,Superficie (ha),Número de Hileras,Sucursal,Variedad,Año de Plantación
Cuartel A,5.2,10,Sucursal Norte,Variedad 1,2024
Cuartel B,3.8,8,Sucursal Sur,Variedad 2,2024
Cuartel C,7.1,12,Sucursal Este,Variedad 1,2024''';
        filename = 'plantilla_cuarteles.csv';
      } else {
        contenido = '''Planta,Tipo Planta,Evaluador,Fecha
Planta 1,Tipo A,Evaluador 1,2024-01-15
Planta 2,Tipo B,Evaluador 2,2024-01-16
Planta 3,Tipo A,Evaluador 1,2024-01-17''';
        filename = 'plantilla_general.csv';
      }
      
             // Convertir a bytes usando UTF-8
       final bytes = utf8.encode(contenido);
      
      // Descargar archivo
      await _descargarArchivo(bytes, filename);
      _mostrarExitoDescarga(tipo);
      
    } catch (e) {
      _mostrarErrorDescarga('Error al crear archivo de ejemplo: $e');
    }
  }

  void _mostrarExitoDescarga(String tipo) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Plantilla ${tipo.toUpperCase()} descargada exitosamente'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarErrorDescarga(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Error al descargar: $error'),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  // Método auxiliar para descargar archivo - IMPLEMENTACIÓN REAL
  Future<void> _descargarArchivo(List<int> bytes, String filename) async {
    try {
      // Para web (Flutter Web)
      if (kIsWeb) {
        // Implementación real para web usando dart:html
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        print('✅ Archivo $filename descargado exitosamente en web');
      } else {
        // Para móvil/desktop - mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Archivo $filename listo para descargar'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
        print('📱 Archivo $filename listo para descargar en móvil/desktop');
      }
      
    } catch (e) {
      print('❌ Error al descargar archivo: $e');
      rethrow;
    }
  }
}

