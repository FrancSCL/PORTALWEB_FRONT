import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import '../widgets/main_scaffold.dart';
import '../theme/app_theme.dart';

class LookerTestScreen extends StatefulWidget {
  const LookerTestScreen({super.key});

  @override
  State<LookerTestScreen> createState() => _LookerTestScreenState();
}

class _LookerTestScreenState extends State<LookerTestScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _showNavigation = true;
  String? _currentEmbedUrl;

  @override
  void initState() {
    super.initState();
    // URL de Looker Studio proporcionada
    _urlController.text = 'https://lookerstudio.google.com/embed/reporting/7fb758d6-8db0-4811-9bec-a00553f01b0c/page/98hZF';
    // Generar iframe automáticamente al cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateIframe();
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _generateIframe() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una URL válida')),
      );
      return;
    }

    setState(() {
      _currentEmbedUrl = url;
    });
  }

  Widget _buildIframeWidget() {
    if (_currentEmbedUrl == null) {
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Genera un embed para ver la vista previa',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Crear iframe real para web
    final iframeId = 'looker-iframe-${DateTime.now().millisecondsSinceEpoch}';
    
    // Registrar el iframe con Flutter
    ui.platformViewRegistry.registerViewFactory(iframeId, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = _currentEmbedUrl!
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      
      // Configurar sandbox usando setAttribute
      iframe.setAttribute('sandbox', 'allow-storage-access-by-user-activation allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox');
      
      return iframe;
    });

    return HtmlElementView(
      viewType: iframeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double cardMaxWidth = 1400;
    final double viewHeight = (size.height * 0.78).clamp(380.0, 920.0);
    
    return MainScaffold(
      title: 'Looker Test',
      currentRoute: '/looker-test',
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16),
        child: _currentEmbedUrl == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: cardMaxWidth),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.06),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.analytics_outlined, size: 20, color: Colors.black87),
                              SizedBox(width: 10),
                              Text(
                                'Reporte',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: viewHeight,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: _buildIframeContainer(),
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

  // Contenedor que fija el HtmlElementView con layout limpio
  Widget _buildIframeContainer() {
    return Container(
      color: Colors.white,
      child: _buildIframeWidget(),
    );
  }
}
