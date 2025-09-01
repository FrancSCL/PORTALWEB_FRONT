import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class CambiarSucursalScreen extends StatefulWidget {
  const CambiarSucursalScreen({super.key});

  @override
  State<CambiarSucursalScreen> createState() => _CambiarSucursalScreenState();
}

class _CambiarSucursalScreenState extends State<CambiarSucursalScreen> {
  String? _selectedSucursal;
  final List<String> _sucursales = [
    'Sucursal Norte',
    'Sucursal Sur',
    'Sucursal Este',
    'Sucursal Oeste',
  ];

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Cambiar Sucursal',
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona la sucursal activa:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSucursal,
              decoration: const InputDecoration(
                labelText: 'Sucursal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _sucursales.map((sucursal) {
                return DropdownMenuItem<String>(
                  value: sucursal,
                  child: Text(sucursal),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSucursal = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor selecciona una sucursal';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedSucursal != null
                    ? () {
                        // TODO: Implementar cambio de sucursal
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sucursal cambiada a: $_selectedSucursal'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Cambiar Sucursal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
