import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';

class SucursalSelector extends StatefulWidget {
  const SucursalSelector({super.key});

  @override
  State<SucursalSelector> createState() => _SucursalSelectorState();
}

class _SucursalSelectorState extends State<SucursalSelector> {
  List<String> _sucursalesDisponibles = [];
  bool _isLoadingSucursales = true;

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  Future<void> _cargarSucursales() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sucursales = await authProvider.getSucursalesDisponibles();
      setState(() {
        _sucursalesDisponibles = sucursales;
        _isLoadingSucursales = false;
      });
    } catch (e) {
      print('Error cargando sucursales: $e');
      setState(() {
        _isLoadingSucursales = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userData = authProvider.userData;
        final sucursalActual = userData?['sucursal_nombre'] ?? 'Sin sucursal';
        final nombreUsuario = userData?['nombre'] ?? 'Usuario';
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Información del usuario
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Bienvenido, $nombreUsuario',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 12)),
                ],
              ),
              
              // Separador vertical
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 1,
                height: 20,
                color: Colors.white.withOpacity(0.3),
              ),
              
              // Selector de sucursal
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sucursal:',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  
                  // Dropdown o loading
                  _isLoadingSucursales
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Cargando...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : DropdownButton<String>(
                          value: _sucursalesDisponibles.contains(sucursalActual) ? sucursalActual : null,
                          onChanged: (String? newValue) async {
                            if (newValue != null && newValue != sucursalActual) {
                              // Mostrar diálogo de carga
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Cambiando sucursal...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Por favor espera mientras se actualiza la configuración',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );

                              try {
                                final success = await authProvider.cambiarSucursal(newValue);
                                
                                // Cerrar diálogo de carga
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }

                                if (success) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white),
                                            const SizedBox(width: 8),
                                            Text('Sucursal cambiada a: $newValue'),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.successColor,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error, color: Colors.white),
                                            const SizedBox(width: 8),
                                            const Text('Error al cambiar sucursal'),
                                          ],
                                        ),
                                        backgroundColor: AppTheme.errorColor,
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                // Cerrar diálogo de carga en caso de error
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error, color: Colors.white),
                                          const SizedBox(width: 8),
                                          const Text('Error de conexión'),
                                        ],
                                      ),
                                      backgroundColor: AppTheme.errorColor,
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          items: _sucursalesDisponibles.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList(),
                          underline: Container(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                            size: 16,
                          ),
                          dropdownColor: AppTheme.primaryColor,
                          style: const TextStyle(color: Colors.white),
                        ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
